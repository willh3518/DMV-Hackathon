import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_message.dart';
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

  static const _model = 'gpt-4o-mini';

  /// Caps how many tool-call round trips a single user message can trigger,
  /// so a confused model can't loop indefinitely against SerpAPI/OpenAI.
  static const _maxToolRounds = 3;

  final SerpApiService _serpApi;

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
  ];

  /// Sends the visible conversation to OpenAI, prefixed with [systemPrompt],
  /// running the search_places_and_reviews tool loop as needed, and returns the
  /// final assistant reply text.
  Future<String> sendMessage(List<ChatMessage> history, {required String systemPrompt}) async {
    final conversation = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => m.toApiJson()),
    ];

    for (var round = 0; round < _maxToolRounds; round++) {
      final message = await _requestCompletion(conversation);
      final toolCalls = message['tool_calls'] as List<dynamic>?;

      if (toolCalls == null || toolCalls.isEmpty) {
        final content = message['content'] as String?;
        if (content == null || content.isEmpty) {
          throw OpenAiException('OpenAI returned an empty reply.');
        }
        return content;
      }

      conversation.add(message);

      for (final rawCall in toolCalls) {
        final call = rawCall as Map<String, dynamic>;
        final function = call['function'] as Map<String, dynamic>;
        final name = function['name'] as String?;
        final callId = call['id'] as String?;

        final resultJson = name == 'search_places_and_reviews'
            ? await _runPlaceSearch(function['arguments'] as String?)
            : jsonEncode({'error': 'Unknown tool "$name".'});

        conversation.add({
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
