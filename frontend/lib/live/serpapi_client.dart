import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:accessibility_frontend/live/proxy_config.dart';

class SerpApiException implements Exception {
  SerpApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Declared (business-listing) data for one place, from engine=google_maps.
/// See docs/steering/serpapi-data-sourcing.md.
class SerpApiPlace {
  const SerpApiPlace({
    required this.dataId,
    required this.name,
    this.address,
    this.category,
    this.rating,
    this.reviewCount,
    this.phone,
    this.hours,
    this.price,
  });

  final String dataId;
  final String name;
  final String? address;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final String? phone;
  final String? hours;
  final String? price;

  Map<String, dynamic> toEvidenceJson() => {
    'dataId': dataId,
    'name': name,
    'address': address,
    'category': category,
    'rating': rating,
    'reviewCount': reviewCount,
    'phone': phone,
    'hours': hours,
    'price': price,
    'evidenceType': 'declared',
    'note':
        'Aggregate rating and review count only. Call get_reviews_for_place '
        'with this dataId to read individual review text (observed evidence).',
  };
}

/// Observed (customer-reported) evidence for one place, from
/// engine=google_maps_reviews. See docs/steering/serpapi-data-sourcing.md.
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

  Map<String, dynamic> toEvidenceJson() => {
    'reviewerName': reviewerName,
    'rating': rating,
    'text': text,
    'relativeDate': relativeDate,
    'isoDate': isoDate,
    'evidenceType': 'observed',
  };
}

class SerpApiClient {
  Future<List<SerpApiPlace>> searchLocalPlaces(
    String query, {
    int limit = 5,
  }) async {
    final uri = Uri.parse(
      '$proxyBaseUrl/api/places',
    ).replace(queryParameters: {'q': query});

    final data = await _getJson(uri);
    final results = data['local_results'] as List<dynamic>? ?? const [];

    return results
        .map((raw) {
          final r = raw as Map<String, dynamic>;
          final dataId = r['data_id']?.toString();
          if (dataId == null) return null;
          return SerpApiPlace(
            dataId: dataId,
            name: (r['title'] as String?) ?? 'Unknown',
            address: r['address']?.toString(),
            category: r['type']?.toString(),
            rating: (r['rating'] as num?)?.toDouble(),
            reviewCount: (r['reviews'] as num?)?.toInt(),
            phone: r['phone']?.toString(),
            hours: r['hours']?.toString(),
            price: r['price']?.toString(),
          );
        })
        .whereType<SerpApiPlace>()
        .take(limit)
        .toList();
  }

  Future<List<SerpApiReview>> fetchReviews(
    String dataId, {
    int limit = 5,
  }) async {
    final uri = Uri.parse(
      '$proxyBaseUrl/api/reviews',
    ).replace(queryParameters: {'data_id': dataId});

    final data = await _getJson(uri);
    final reviews = data['reviews'] as List<dynamic>? ?? const [];

    return reviews.take(limit).map((raw) {
      final r = raw as Map<String, dynamic>;
      final user = r['user'] as Map<String, dynamic>?;
      final snippet =
          (r['snippet'] as String?) ??
          ((r['extracted_snippet'] as Map<String, dynamic>?)?['original']
              as String?) ??
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

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await http.get(uri);
    } catch (_) {
      throw SerpApiException(
        'Could not reach the local proxy. Is server/bin/server.dart running?',
      );
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw SerpApiException('SerpAPI returned an unreadable response.');
    }

    if (response.statusCode != 200) {
      final message = data['error']?.toString();
      throw SerpApiException(
        message ?? 'SerpAPI request failed (${response.statusCode}).',
      );
    }

    return data;
  }
}
