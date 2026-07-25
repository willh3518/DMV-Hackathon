import 'dart:convert';
import 'dart:io';

const _port = 8787;
const _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';

Map<String, String> _loadEnv(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final env = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final separator = trimmed.indexOf('=');
    if (separator == -1) continue;
    env[trimmed.substring(0, separator)] = trimmed.substring(separator + 1);
  }
  return env;
}

void main() async {
  final env = _loadEnv('.env');
  final openAiKey = env['OPENAI_API_KEY'] ?? '';
  final serpApiKey = env['SERPAPI_API_KEY'] ?? '';

  final server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
  // ignore: avoid_print
  print('Proxy listening on http://localhost:$_port');

  await for (final request in server) {
    _setCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    try {
      if (request.method == 'POST' && request.uri.path == '/api/chat') {
        await _proxyChat(request, openAiKey);
      } else if (request.method == 'GET' && request.uri.path == '/api/places') {
        await _proxyPlaces(request, serpApiKey);
      } else if (request.method == 'GET' && request.uri.path == '/api/reviews') {
        await _proxyReviews(request, serpApiKey);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': 'Proxy error: $e'}));
      await request.response.close();
    }
  }
}

void _setCorsHeaders(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
}

Future<void> _proxyChat(HttpRequest request, String apiKey) async {
  if (apiKey.isEmpty) {
    await _respondJson(request.response, HttpStatus.internalServerError, {
      'error': {'message': 'Proxy is missing OPENAI_API_KEY. Add it to server/.env and restart.'},
    });
    return;
  }

  final body = await utf8.decoder.bind(request).join();

  final client = HttpClient();
  try {
    final upstreamRequest = await client.postUrl(Uri.parse(_openAiEndpoint));
    upstreamRequest.headers.contentType = ContentType.json;
    upstreamRequest.headers.set('Authorization', 'Bearer $apiKey');
    upstreamRequest.write(body);
    final upstreamResponse = await upstreamRequest.close();
    await _relay(upstreamResponse, request.response);
  } finally {
    client.close();
  }
}

Future<void> _proxyPlaces(HttpRequest request, String apiKey) async {
  if (apiKey.isEmpty) {
    await _respondJson(request.response, HttpStatus.internalServerError, {
      'error': 'Proxy is missing SERPAPI_API_KEY. Add it to server/.env and restart.',
    });
    return;
  }

  final query = request.uri.queryParameters['q'];
  if (query == null || query.isEmpty) {
    await _respondJson(request.response, HttpStatus.badRequest, {
      'error': 'Missing required "q" query parameter.',
    });
    return;
  }

  final client = HttpClient();
  try {
    // engine=google_maps (not engine=google): its local_results carries the
    // same listing fields we need PLUS data_id, which engine=google's
    // place_id (actually a data_cid) cannot be used for — google_maps_reviews
    // requires the data_id specifically. See server/README.md.
    final upstreamUri = Uri.https('serpapi.com', '/search', {
      'engine': 'google_maps',
      'q': query,
      'type': 'search',
      'api_key': apiKey,
    });
    // ignore: avoid_print
    print('[places] query="$query"');
    final upstreamRequest = await client.getUrl(upstreamUri);
    final upstreamResponse = await upstreamRequest.close();
    final body = await _relay(upstreamResponse, request.response);
    final resultCount = (jsonDecode(body)['local_results'] as List?)?.length;
    // ignore: avoid_print
    print('[places] query="$query" -> status=${upstreamResponse.statusCode} results=$resultCount');
  } finally {
    client.close();
  }
}

Future<void> _proxyReviews(HttpRequest request, String apiKey) async {
  if (apiKey.isEmpty) {
    await _respondJson(request.response, HttpStatus.internalServerError, {
      'error': 'Proxy is missing SERPAPI_API_KEY. Add it to server/.env and restart.',
    });
    return;
  }

  final dataId = request.uri.queryParameters['data_id'];
  if (dataId == null || dataId.isEmpty) {
    await _respondJson(request.response, HttpStatus.badRequest, {
      'error': 'Missing required "data_id" query parameter.',
    });
    return;
  }

  final client = HttpClient();
  try {
    final upstreamUri = Uri.https('serpapi.com', '/search', {
      'engine': 'google_maps_reviews',
      'data_id': dataId,
      'api_key': apiKey,
    });
    // ignore: avoid_print
    print('[reviews] data_id="$dataId"');
    final upstreamRequest = await client.getUrl(upstreamUri);
    final upstreamResponse = await upstreamRequest.close();
    final body = await _relay(upstreamResponse, request.response);
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final reviewCount = (decoded['reviews'] as List?)?.length;
    // ignore: avoid_print
    print(
      '[reviews] data_id="$dataId" -> status=${upstreamResponse.statusCode} '
      'reviews=$reviewCount error=${decoded['error']}',
    );
  } finally {
    client.close();
  }
}

Future<String> _relay(HttpClientResponse upstream, HttpResponse response) async {
  final body = await upstream.transform(utf8.decoder).join();
  response.statusCode = upstream.statusCode;
  response.headers.contentType = ContentType.json;
  response.write(body);
  await response.close();
  return body;
}

Future<void> _respondJson(HttpResponse response, int statusCode, Object payload) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(payload));
  await response.close();
}
