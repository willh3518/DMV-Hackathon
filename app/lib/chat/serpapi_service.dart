import 'dart:convert';

import 'package:http/http.dart' as http;

import 'proxy_config.dart';

class SerpApiException implements Exception {
  SerpApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SerpApiPlace {
  const SerpApiPlace({
    required this.name,
    this.address,
    this.category,
    this.rating,
    this.reviewCount,
    this.phone,
    this.hours,
  });

  final String name;
  final String? address;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final String? phone;
  final String? hours;

  /// Provenance-tagged so the model can never present this as observed
  /// review content. See docs/steering/serpapi-data-sourcing.md.
  Map<String, dynamic> toEvidenceJson() => {
    'name': name,
    'address': address,
    'category': category,
    'rating': rating,
    'reviewCount': reviewCount,
    'phone': phone,
    'hours': hours,
    'evidenceType': 'declared',
    'note':
        'Aggregate rating and review count only; individual review text is '
        'not available from this lookup.',
  };
}

class SerpApiService {
  /// Calls the local proxy (../server), never SerpAPI directly: SerpAPI
  /// does not send CORS headers permitting browser-origin requests, and the
  /// key must not ship inside the client bundle.
  Future<List<SerpApiPlace>> searchLocalPlaces(String query, {int limit = 5}) async {
    final uri = Uri.parse(
      '$proxyBaseUrl/api/places',
    ).replace(queryParameters: {'q': query});

    final http.Response response;
    try {
      response = await http.get(uri);
    } catch (_) {
      throw SerpApiException('Could not reach the local proxy. Is server/bin/server.dart running?');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw SerpApiException('SerpAPI returned an unreadable response.');
    }

    if (response.statusCode != 200) {
      final message = data['error']?.toString();
      throw SerpApiException(message ?? 'SerpAPI request failed (${response.statusCode}).');
    }

    // engine=google nests local pack listings under local_results.places
    // (a flat local_results array is only returned by engine=google_local).
    final localResults = data['local_results'] as Map<String, dynamic>?;
    final places = localResults?['places'] as List<dynamic>? ?? const [];

    return places.take(limit).map((raw) {
      final r = raw as Map<String, dynamic>;
      return SerpApiPlace(
        name: (r['title'] as String?) ?? 'Unknown',
        address: r['address']?.toString(),
        category: r['type']?.toString(),
        rating: (r['rating'] as num?)?.toDouble(),
        reviewCount: (r['reviews'] as num?)?.toInt(),
        phone: r['phone']?.toString(),
        hours: r['hours']?.toString(),
      );
    }).toList();
  }
}
