import 'package:accessibility_frontend/contracts/place_detail_gateway.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';

final class SyntheticPlaceDetailGateway implements PlaceDetailGateway {
  SyntheticPlaceDetailGateway({required PlaceDetailResult result})
    : _defaultResult = result,
      _resultsById = const <String, PlaceDetailResult>{};

  SyntheticPlaceDetailGateway.byId({
    required Map<String, PlaceDetailResult> results,
  }) : assert(results.isNotEmpty),
       _defaultResult = null,
       _resultsById = Map<String, PlaceDetailResult>.unmodifiable(results);

  final PlaceDetailResult? _defaultResult;
  final Map<String, PlaceDetailResult> _resultsById;
  int callCount = 0;

  @override
  Future<PlaceDetailResult> loadPlaceDetail({
    required String recommendationId,
  }) async {
    callCount += 1;
    return _resultsById[recommendationId] ??
        _defaultResult ??
        const PlaceDetailFailure(reason: PlaceDetailFailureReason.unknown);
  }
}
