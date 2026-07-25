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
    this.dataId,
    this.address,
    this.category,
    this.rating,
    this.reviewCount,
    this.phone,
    this.hours,
  });

  final String name;

  /// Google Maps' data_id — required to look up this place's reviews via
  /// [SerpApiService.fetchReviews]. Not the same as SerpAPI's place_id/
  /// data_cid, which google_maps_reviews rejects.
  final String? dataId;
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
    'dataId': dataId,
    'address': address,
    'category': category,
    'rating': rating,
    'reviewCount': reviewCount,
    'phone': phone,
    'hours': hours,
    'evidenceType': 'declared',
    'note':
        'Aggregate rating and review count only. To read individual review '
        'text for this place, call get_reviews_for_place with its dataId.',
  };
}

class SerpApiReview {
  const SerpApiReview({
    required this.reviewerName,
    required this.rating,
    required this.text,
    this.relativeDate,
    this.isoDate,
  });

  final String reviewerName;
  final double? rating;
  final String text;
  final String? relativeDate;
  final String? isoDate;

  /// Provenance-tagged as observed (customer-reported), never declared —
  /// this is the whole point of adding this lookup. See
  /// docs/steering/serpapi-data-sourcing.md.
  Map<String, dynamic> toEvidenceJson() => {
    'reviewerName': reviewerName,
    'rating': rating,
    'text': text,
    'relativeDate': relativeDate,
    'isoDate': isoDate,
    'evidenceType': 'observed',
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

    final data = await _getJson(uri, notRunningHint: 'Is server/bin/server.dart running?');

    // engine=google_maps returns a flat local_results array (unlike
    // engine=google, which nests listings under local_results.places).
    final results = data['local_results'] as List<dynamic>? ?? const [];

    return results.take(limit).map((raw) {
      final r = raw as Map<String, dynamic>;
      return SerpApiPlace(
        name: (r['title'] as String?) ?? 'Unknown',
        dataId: r['data_id']?.toString(),
        address: r['address']?.toString(),
        category: r['type']?.toString(),
        rating: (r['rating'] as num?)?.toDouble(),
        reviewCount: (r['reviews'] as num?)?.toInt(),
        phone: r['phone']?.toString(),
        hours: r['hours']?.toString(),
      );
    }).toList();
  }

  /// Fetches individual review text for a place via engine=google_maps_reviews.
  /// [dataId] must come from a prior [searchLocalPlaces] result's dataId —
  /// SerpAPI's other place identifiers (place_id/data_cid) don't work here.
  Future<List<SerpApiReview>> fetchReviews(String dataId, {int limit = 5}) async {
    final uri = Uri.parse(
      '$proxyBaseUrl/api/reviews',
    ).replace(queryParameters: {'data_id': dataId});

    final data = await _getJson(uri, notRunningHint: 'Is server/bin/server.dart running?');

    final reviews = data['reviews'] as List<dynamic>? ?? const [];

    return reviews.take(limit).map((raw) {
      final r = raw as Map<String, dynamic>;
      final user = r['user'] as Map<String, dynamic>?;
      final snippet =
          (r['snippet'] as String?) ??
          ((r['extracted_snippet'] as Map<String, dynamic>?)?['original'] as String?) ??
          '';
      return SerpApiReview(
        reviewerName: (user?['name'] as String?) ?? 'Anonymous',
        rating: (r['rating'] as num?)?.toDouble(),
        text: snippet,
        relativeDate: r['date']?.toString(),
        isoDate: r['iso_date']?.toString(),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {required String notRunningHint}) async {
    final http.Response response;
    try {
      response = await http.get(uri);
    } catch (_) {
      throw SerpApiException('Could not reach the local proxy. $notRunningHint');
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

    return data;
  }
}
