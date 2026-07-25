import 'dart:convert';

import 'package:accessibility_frontend/contracts/discovery_gateway.dart';
import 'package:accessibility_frontend/domain/chat/chat_models.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:accessibility_frontend/live/place_cache.dart';
import 'package:accessibility_frontend/live/proxy_config.dart';
import 'package:accessibility_frontend/live/serpapi_client.dart';
import 'package:http/http.dart' as http;

/// Backs [DiscoveryGateway] with the real OpenAI + SerpAPI proxy (../../server)
/// instead of synthetic fixtures. Holds one persistent conversation for the
/// life of this instance — tool calls/results from earlier turns (e.g. a
/// place's dataId) stay in context for later turns, matching the fix applied
/// to the chat-spike app/ project earlier this session.
class LiveDiscoveryGateway implements DiscoveryGateway {
  LiveDiscoveryGateway({required this.systemPrompt, required PlaceCache placeCache})
    : _placeCache = placeCache;

  final String systemPrompt;
  final PlaceCache _placeCache;
  final SerpApiClient _serpApi = SerpApiClient();
  final List<Map<String, dynamic>> _conversation = [];
  bool _systemPromptSet = false;
  static const _conversationId = 'live-conversation';
  static const _model = 'gpt-4o';
  static const _maxToolRounds = 6;

  static const _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'search_places_and_reviews',
        'description':
            'Search live Google Maps results via SerpAPI for restaurants and other '
            'places. This is the ONLY source of truth for real business names, '
            'addresses, ratings, hours, and review counts — never answer from '
            'memory. Results are declared/aggregate listing data only.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Place type/cuisine/need plus a location.',
            },
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_reviews_for_place',
        'description':
            'Fetch individual customer review text (observed evidence) for one '
            'place using its dataId from a prior search. Call before claiming '
            'anything about what reviewers said.',
        'parameters': {
          'type': 'object',
          'properties': {
            'dataId': {'type': 'string'},
          },
          'required': ['dataId'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'submit_recommendations',
        'description':
            'End the turn with one or more matched places. Call this once you '
            'have searched and (where relevant) checked reviews for enough '
            'candidates to recommend. Every attribute status must be backed by '
            'declared or observed evidence already fetched this conversation, '
            'or marked unknown — never guessed.',
        'parameters': {
          'type': 'object',
          'properties': {
            'message': {
              'type': 'string',
              'description': 'Short conversational reply to show above the results.',
            },
            'announcementLabel': {
              'type': 'string',
              'description': 'Screen-reader announcement, e.g. "3 recommendations are ready to review".',
            },
            'recommendations': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'dataId': {
                    'type': 'string',
                    'description': 'The dataId of this place from a search result.',
                  },
                  'placeName': {'type': 'string'},
                  'placeTypeLabel': {'type': 'string'},
                  'matchScore': {
                    'type': 'integer',
                    'description': '0-100 personalized fit for this user, not a generic star rating.',
                  },
                  'matchExplanation': {'type': 'string'},
                  'attributeSummaries': {
                    'type': 'array',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'label': {'type': 'string'},
                        'status': {
                          'type': 'string',
                          'enum': ['strength', 'concern', 'unknown'],
                        },
                      },
                      'required': ['label', 'status'],
                    },
                  },
                },
                'required': [
                  'dataId',
                  'placeName',
                  'placeTypeLabel',
                  'matchScore',
                  'matchExplanation',
                  'attributeSummaries',
                ],
              },
            },
          },
          'required': ['message', 'announcementLabel', 'recommendations'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'submit_clarifying_question',
        'description':
            'End the turn by asking the user one clarifying question instead '
            'of searching — use when their request or profile is too vague '
            'to search yet.',
        'parameters': {
          'type': 'object',
          'properties': {
            'message': {'type': 'string'},
          },
          'required': ['message'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'submit_no_results',
        'description': 'End the turn when a genuine search returned nothing usable.',
        'parameters': {
          'type': 'object',
          'properties': {
            'message': {'type': 'string'},
          },
          'required': ['message'],
        },
      },
    },
  ];

  @override
  Future<DiscoveryResult> send(DiscoveryRequest request) async {
    if (!_systemPromptSet) {
      _conversation.add({'role': 'system', 'content': systemPrompt});
      _systemPromptSet = true;
    }
    _conversation.add({'role': 'user', 'content': request.text});

    try {
      for (var round = 0; round < _maxToolRounds; round++) {
        final message = await _requestCompletion();
        final toolCalls = message['tool_calls'] as List<dynamic>?;

        if (toolCalls == null || toolCalls.isEmpty) {
          // Model replied without using a submit_* tool; treat as clarification
          // rather than silently dropping the turn.
          final content = message['content'] as String? ?? '';
          _conversation.add({'role': 'assistant', 'content': content});
          return DiscoveryClarification(conversationId: _conversationId, message: content);
        }

        _conversation.add(message);

        for (final rawCall in toolCalls) {
          final call = rawCall as Map<String, dynamic>;
          final function = call['function'] as Map<String, dynamic>;
          final name = function['name'] as String?;
          final callId = call['id'] as String?;
          final argsJson = function['arguments'] as String?;

          if (name == 'submit_recommendations') {
            return _buildRecommendations(argsJson);
          }
          if (name == 'submit_clarifying_question') {
            final args = _decodeArgs(argsJson);
            return DiscoveryClarification(
              conversationId: _conversationId,
              message: (args['message'] as String?) ?? '',
            );
          }
          if (name == 'submit_no_results') {
            final args = _decodeArgs(argsJson);
            return DiscoveryNoResults(
              conversationId: _conversationId,
              message: (args['message'] as String?) ?? '',
            );
          }

          final resultJson = switch (name) {
            'search_places_and_reviews' => await _runPlaceSearch(argsJson),
            'get_reviews_for_place' => await _runGetReviews(argsJson),
            _ => jsonEncode({'error': 'Unknown tool "$name".'}),
          };

          _conversation.add({
            'role': 'tool',
            'tool_call_id': callId,
            'name': name,
            'content': resultJson,
          });
        }
      }

      return const DiscoveryFailure(reason: DiscoveryFailureReason.serviceUnavailable);
    } on SerpApiException {
      return const DiscoveryFailure(reason: DiscoveryFailureReason.serviceUnavailable);
    } catch (_) {
      return const DiscoveryFailure(reason: DiscoveryFailureReason.networkUnavailable);
    }
  }

  DiscoveryResult _buildRecommendations(String? argsJson) {
    final args = _decodeArgs(argsJson);
    final rawRecs = args['recommendations'] as List<dynamic>? ?? const [];

    final recommendations = rawRecs.map((raw) {
      final r = raw as Map<String, dynamic>;
      final attrs = (r['attributeSummaries'] as List<dynamic>? ?? const [])
          .map((a) {
            final m = a as Map<String, dynamic>;
            return RecommendationAttributeSummary(
              label: (m['label'] as String?) ?? '',
              status: _statusFrom(m['status'] as String?),
            );
          })
          .toList();

      final place = _placeCache.get(r['dataId'] as String? ?? '');

      return RecommendationSummary(
        id: (r['dataId'] as String?) ?? '',
        placeName: (r['placeName'] as String?) ?? 'Unknown place',
        placeTypeLabel: (r['placeTypeLabel'] as String?) ?? '',
        personalizedMatch: PersonalizedMatch(
          score: ((r['matchScore'] as num?)?.toInt() ?? 0).clamp(0, 100),
        ),
        matchExplanation: (r['matchExplanation'] as String?) ?? '',
        attributeSummaries: attrs,
        practicalContext: place == null
            ? null
            : PlacePracticalContext(
                priceLabel: place.price,
                cuisineLabel: place.category,
                hoursLabel: place.hours,
              ),
      );
    }).toList();

    if (recommendations.isEmpty) {
      return DiscoveryNoResults(
        conversationId: _conversationId,
        message: (args['message'] as String?) ?? 'No matches found.',
      );
    }

    return DiscoveryResults(
      conversationId: _conversationId,
      message: (args['message'] as String?) ?? '',
      payload: RecommendationResultsPayload(
        recommendations: recommendations,
        announcementLabel:
            (args['announcementLabel'] as String?) ??
            '${recommendations.length} recommendations are ready to review.',
      ),
    );
  }

  AccessibilityStatus _statusFrom(String? raw) => switch (raw) {
    'strength' => AccessibilityStatus.strength,
    'concern' => AccessibilityStatus.concern,
    _ => AccessibilityStatus.unknown,
  };

  Map<String, dynamic> _decodeArgs(String? argsJson) {
    if (argsJson == null || argsJson.isEmpty) return const {};
    try {
      return jsonDecode(argsJson) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Future<String> _runPlaceSearch(String? argsJson) async {
    final args = _decodeArgs(argsJson);
    final query = args['query'] as String?;
    if (query == null || query.isEmpty) {
      return jsonEncode({'error': 'Missing required "query" argument.'});
    }
    final places = await _serpApi.searchLocalPlaces(query);
    _placeCache.putAll(places);
    return jsonEncode({
      'source': 'SerpAPI (Google Maps)',
      'query': query,
      'results': places.map((p) => p.toEvidenceJson()).toList(),
    });
  }

  Future<String> _runGetReviews(String? argsJson) async {
    final args = _decodeArgs(argsJson);
    final dataId = args['dataId'] as String?;
    if (dataId == null || dataId.isEmpty) {
      return jsonEncode({'error': 'Missing required "dataId" argument.'});
    }
    final reviews = await _serpApi.fetchReviews(dataId);
    return jsonEncode({
      'source': 'SerpAPI (Google Maps Reviews)',
      'dataId': dataId,
      'results': reviews.map((r) => r.toEvidenceJson()).toList(),
    });
  }

  Future<Map<String, dynamic>> _requestCompletion() async {
    final response = await http.post(
      Uri.parse('$proxyBaseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model': _model, 'messages': _conversation, 'tools': _tools}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw SerpApiException('OpenAI request failed (${response.statusCode}).');
    }
    final choices = data['choices'] as List<dynamic>;
    return (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>;
  }
}
