import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';

abstract interface class PlaceDetailGateway {
  Future<PlaceDetailResult> loadPlaceDetail({required String recommendationId});
}
