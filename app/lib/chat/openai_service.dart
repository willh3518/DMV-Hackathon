import 'dart:convert';

import 'package:http/http.dart' as http;

import 'proxy_config.dart';
import 'serpapi_service.dart';

class OpenAiException implements Exception {
  OpenAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenAiService {
  OpenAiService({SerpApiService? serpApi}) : _serpApi = serpApi ?? SerpApiService();

  static const _model = 'gpt-4o';

  /// Caps how many tool-call round trips a single user message can trigger,
  /// so a confused model can't loop indefinitely against SerpAPI/OpenAI.
  /// Sized for search -> reviews-per-candidate-place -> final answer.
  static const _maxToolRounds = 5;

  final SerpApiService _serpApi;

  /// Persists across turns for the lifetime of this service instance (i.e.
  /// the whole chat session), unlike the visible ChatMessage list in
  /// ChatPage. This is deliberate: tool calls/results from an earlier turn
  /// — e.g. a dataId a search already resolved — must stay in context, or
  /// a later turn ("yes please") forces the model to blindly re-search
  /// instead of reusing what it already found.
  final List<Map<String, dynamic>> _conversation = [];
  bool _systemPromptSet = false;

  static const _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'search_places_and_reviews',
        'description':
            'Search live Google Local results via SerpAPI for restaurants and other '
            'places. This is the ONLY source of truth for real business names, '
            'addresses, ratings, hours, and review counts — never answer questions '
            'about a specific real place from memory or training data, always call '
            'this tool first. Results are declared/aggregate listing data only; no '
            'individual review text is included.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description':
                  'Search terms combining place type/cuisine/need and a location, '
                  'e.g. "quiet italian restaurant wheelchair accessible near '
                  'national mall washington dc".',
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
            'Fetch individual customer review text for one specific place via '
            'SerpAPI, using the dataId returned by search_places_and_reviews. '
            'This is the ONLY source of observed (customer-reported) evidence — '
            'ratings/hours/category from search_places_and_reviews are declared '
            'listing data, not observed experience. Call this before making any '
            'claim about what reviewers actually said (accessibility details, '
            'noise, staff behavior, etc.); if it returns no reviews, that aspect '
            'is unknown, not negative.',
        'parameters': {
          'type': 'object',
          'properties': {
            'dataId': {
              'type': 'string',
              'description':
                  'The dataId field from a prior search_places_and_reviews '
                  'result for this specific place.',
            },
          },
          'required': ['dataId'],
        },
      },
    },
  ];

  /// Appends [userText] to the persistent session conversation, running the
  /// tool loop as needed, and returns the final assistant reply text. Only
  /// the new user turn is passed in — prior turns (including tool calls/
  /// results) are already retained in [_conversation].
  Future<String> sendMessage(String userText, {required String systemPrompt}) async {
    if (!_systemPromptSet) {
      _conversation.add({'role': 'system', 'content': systemPrompt});
      _systemPromptSet = true;
    }
    _conversation.add({'role': 'user', 'content': userText});

    for (var round = 0; round < _maxToolRounds; round++) {
      final message = await _requestCompletion(_conversation);
      final toolCalls = message['tool_calls'] as List<dynamic>?;

      if (toolCalls == null || toolCalls.isEmpty) {
        final content = message['content'] as String?;
        if (content == null || content.isEmpty) {
          throw OpenAiException('OpenAI returned an empty reply.');
        }
        _conversation.add({'role': 'assistant', 'content': content});
        return content;
      }

      _conversation.add(message);

      for (final rawCall in toolCalls) {
        final call = rawCall as Map<String, dynamic>;
        final function = call['function'] as Map<String, dynamic>;
        final name = function['name'] as String?;
        final callId = call['id'] as String?;

        final String resultJson;
        switch (name) {
          case 'search_places_and_reviews':
            resultJson = await _runPlaceSearch(function['arguments'] as String?);
          case 'get_reviews_for_place':
            resultJson = await _runGetReviews(function['arguments'] as String?);
          default:
            resultJson = jsonEncode({'error': 'Unknown tool "$name".'});
        }

        _conversation.add({
          'role': 'tool',
          'tool_call_id': callId,
          'name': name,
          'content': resultJson,
        });
      }
    }

    throw OpenAiException(
      'Gave up after $_maxToolRounds place-search rounds without a final reply.',
    );
  }

  Future<String> _runPlaceSearch(String? argumentsJson) async {
    try {
      final args = argumentsJson == null || argumentsJson.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(argumentsJson) as Map<String, dynamic>;
      final query = args['query'] as String?;
      if (query == null || query.isEmpty) {
        return jsonEncode({'error': 'Missing required "query" argument.'});
      }

      final places = await _serpApi.searchLocalPlaces(query);
      return jsonEncode({
        'source': 'SerpAPI (Google Local)',
        'query': query,
        'results': places.map((p) => p.toEvidenceJson()).toList(),
      });
    } on SerpApiException catch (e) {
      return jsonEncode({'error': e.message});
    } catch (_) {
      return jsonEncode({'error': 'Place search failed unexpectedly.'});
    }
  }

  Future<String> _runGetReviews(String? argumentsJson) async {
    try {
      final args = argumentsJson == null || argumentsJson.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(argumentsJson) as Map<String, dynamic>;
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
    } on SerpApiException catch (e) {
      return jsonEncode({'error': e.message});
    } catch (_) {
      return jsonEncode({'error': 'Review lookup failed unexpectedly.'});
    }
  }

  Future<Map<String, dynamic>> _requestCompletion(List<Map<String, dynamic>> conversation) async {
    // Calls the local proxy (../server), not OpenAI directly, so the API key
    // never ships inside the client bundle. See server/README.md.
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$proxyBaseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model': _model, 'messages': conversation, 'tools': _tools}),
      );
    } catch (_) {
      throw OpenAiException('Could not reach the local proxy. Is server/bin/server.dart running?');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw OpenAiException('OpenAI returned an unreadable response.');
    }

    if (response.statusCode != 200) {
      final message = (data['error'] as Map<String, dynamic>?)?['message'] as String?;
      throw OpenAiException(message ?? 'OpenAI request failed (${response.statusCode}).');
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenAiException('OpenAI returned no choices.');
    }
    return (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>;
  }
}
