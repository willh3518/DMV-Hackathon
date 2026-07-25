import 'package:accessibility_frontend/live/serpapi_client.dart';

/// Shared, in-memory only. Populated by [LiveDiscoveryGateway] as it searches
/// so [LivePlaceDetailGateway] can look a place back up by its dataId
/// (used as the recommendationId) without a redundant search call.
class PlaceCache {
  final Map<String, SerpApiPlace> _byDataId = {};

  void put(SerpApiPlace place) => _byDataId[place.dataId] = place;

  void putAll(Iterable<SerpApiPlace> places) => places.forEach(put);

  SerpApiPlace? get(String dataId) => _byDataId[dataId];
}
