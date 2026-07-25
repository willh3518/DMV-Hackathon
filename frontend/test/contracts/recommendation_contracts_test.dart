import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:accessibility_frontend/fixtures/synthetic_external_action_launcher.dart';
import 'package:accessibility_frontend/fixtures/synthetic_place_detail_gateway.dart';
import 'package:accessibility_frontend/fixtures/synthetic_recommendation_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'synthetic detail and external-action adapters return typed results',
    () async {
      final SyntheticPlaceDetailGateway detailGateway =
          SyntheticPlaceDetailGateway(
            result: const PlaceDetailSuccess(
              detail: SyntheticRecommendationFixtures.restaurantDetail,
            ),
          );
      final SyntheticExternalActionLauncher launcher =
          SyntheticExternalActionLauncher();

      final PlaceDetailResult detail = await detailGateway.loadPlaceDetail(
        recommendationId: 'restaurant-1',
      );
      final ExternalActionLaunchResult launch = await launcher.launch(
        SyntheticRecommendationFixtures.restaurantDetail.externalActions.first,
      );

      expect(detail, isA<PlaceDetailSuccess>());
      expect(launch, isA<ExternalActionLaunchSuccess>());
      expect(detailGateway.callCount, 1);
      expect(launcher.callCount, 1);
    },
  );

  test(
    'synthetic detail adapter keeps recommendation details paired',
    () async {
      final SyntheticPlaceDetailGateway gateway =
          SyntheticPlaceDetailGateway.byId(
            results: const <String, PlaceDetailResult>{
              'restaurant-1': PlaceDetailSuccess(
                detail: SyntheticRecommendationFixtures.restaurantDetail,
              ),
              'activity-1': PlaceDetailSuccess(
                detail: SyntheticRecommendationFixtures.activityDetail,
              ),
            },
          );

      final PlaceDetailResult activityResult = await gateway.loadPlaceDetail(
        recommendationId: 'activity-1',
      );
      final PlaceDetailResult missingResult = await gateway.loadPlaceDetail(
        recommendationId: 'missing',
      );

      expect(
        (activityResult as PlaceDetailSuccess).detail.placeName,
        'Riverside Art Studio',
      );
      expect(missingResult, isA<PlaceDetailFailure>());
    },
  );
}
