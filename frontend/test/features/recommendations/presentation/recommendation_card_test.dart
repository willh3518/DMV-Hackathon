import 'package:accessibility_frontend/contracts/external_action_launcher.dart';
import 'package:accessibility_frontend/contracts/place_detail_gateway.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/design_system/components/status_indicator.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/place_detail_route.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/recommendation_card.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/recommendation_results_section.dart';
import 'package:accessibility_frontend/fixtures/synthetic_recommendation_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'recommendation card renders supplied personalized summary and status semantics',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildCardHarness(
            recommendation: SyntheticRecommendationFixtures.restaurant,
          ),
        );

        expect(find.text('Bluebird Kitchen'), findsOneWidget);
        expect(find.text('Italian restaurant'), findsOneWidget);
        expect(find.text('88%'), findsOneWidget);
        expect(find.text('Personalized match'), findsOneWidget);
        expect(
          find.text(
            'Strong step-free access and quieter seating align with this profile.',
          ),
          findsOneWidget,
        );
        expect(find.text(r'$$'), findsOneWidget);
        expect(find.text('Italian'), findsOneWidget);
        expect(find.text('0.7 mi'), findsOneWidget);
        expect(find.text('Open until 9 PM'), findsOneWidget);
        expect(
          find.text(
            'Confidence high • 6 mentions • Latest mention 2 months ago',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'Personalized match 88 percent for this request',
          ),
          findsOneWidget,
        );
        expect(
          tester.getSemantics(find.byType(AppStatusIndicator).first),
          matchesSemantics(label: 'Strength: Step-free entrance'),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'recommendation card omits missing optional context and evidence labels cleanly',
    (WidgetTester tester) async {
      const RecommendationSummary recommendation = RecommendationSummary(
        id: 'quiet-cafe',
        placeName: 'Harbor Cafe',
        placeTypeLabel: 'Cafe',
        personalizedMatch: PersonalizedMatch(score: 74),
        matchExplanation:
            'The supplied evidence suggests a simpler midday environment.',
        attributeSummaries: <RecommendationAttributeSummary>[
          RecommendationAttributeSummary(
            label: 'Queue wait time',
            status: AccessibilityStatus.unknown,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildCardHarness(recommendation: recommendation),
      );

      expect(find.text('Harbor Cafe'), findsOneWidget);
      expect(find.text('74%'), findsOneWidget);
      expect(find.textContaining('Confidence'), findsNothing);
      expect(find.textContaining('mentions'), findsNothing);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text(r'$$'), findsNothing);
      expect(find.text('Open until 9 PM'), findsNothing);
    },
  );

  testWidgets(
    'results section opens detail and restores focus to the originating details button',
    (WidgetTester tester) async {
      final _StaticPlaceDetailGateway gateway = _StaticPlaceDetailGateway(
        result: const PlaceDetailSuccess(
          detail: SyntheticRecommendationFixtures.restaurantDetail,
        ),
      );
      final _StaticExternalActionLauncher launcher =
          _StaticExternalActionLauncher();

      await tester.pumpWidget(
        _buildResultsHarness(
          recommendations: const <RecommendationSummary>[
            SyntheticRecommendationFixtures.restaurant,
          ],
          placeDetailGateway: gateway,
          externalActionLauncher: launcher,
        ),
      );

      final Key detailsKey = RecommendationCard.detailsButtonKey(
        'restaurant-1',
      );
      await tester.ensureVisible(find.byKey(detailsKey));
      await tester.tap(find.byKey(detailsKey));
      await tester.pumpAndSettle();

      expect(find.byType(PlaceDetailRoute), findsOneWidget);
      expect(find.text('Bluebird Kitchen'), findsWidgets);

      await tester.tap(find.byKey(PlaceDetailRoute.backButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(PlaceDetailRoute), findsNothing);
      expect(
        tester.widget<TextButton>(find.byKey(detailsKey)).focusNode?.hasFocus,
        isTrue,
      );
      expect(gateway.callCount, 1);
    },
  );

  testWidgets(
    'results section settles quickly when reduced motion is enabled',
    (WidgetTester tester) async {
      final MediaQueryData mediaQuery = MediaQueryData.fromView(
        tester.view,
      ).copyWith(disableAnimations: true);

      await tester.pumpWidget(
        _buildResultsHarness(
          recommendations: const <RecommendationSummary>[
            SyntheticRecommendationFixtures.restaurant,
          ],
          placeDetailGateway: _StaticPlaceDetailGateway(
            result: const PlaceDetailSuccess(
              detail: SyntheticRecommendationFixtures.restaurantDetail,
            ),
          ),
          externalActionLauncher: _StaticExternalActionLauncher(),
          mediaQuery: mediaQuery,
        ),
      );

      await tester.ensureVisible(
        find.byKey(RecommendationCard.detailsButtonKey('restaurant-1')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(RecommendationCard.detailsButtonKey('restaurant-1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlaceDetailRoute), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('results section remains usable at 3.2x text scale', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      _buildResultsHarness(
        recommendations: const <RecommendationSummary>[
          SyntheticRecommendationFixtures.restaurant,
        ],
        placeDetailGateway: _StaticPlaceDetailGateway(
          result: const PlaceDetailSuccess(
            detail: SyntheticRecommendationFixtures.restaurantDetail,
          ),
        ),
        externalActionLauncher: _StaticExternalActionLauncher(),
      ),
    );

    await tester.ensureVisible(
      find.byKey(RecommendationCard.detailsButtonKey('restaurant-1')),
    );
    await tester.pump();

    expect(find.text('Recommended for this request'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('results section meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildResultsHarness(
        recommendations: const <RecommendationSummary>[
          SyntheticRecommendationFixtures.restaurant,
        ],
        placeDetailGateway: _StaticPlaceDetailGateway(
          result: const PlaceDetailSuccess(
            detail: SyntheticRecommendationFixtures.restaurantDetail,
          ),
        ),
        externalActionLauncher: _StaticExternalActionLauncher(),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

Widget _buildCardHarness({
  required RecommendationSummary recommendation,
  MediaQueryData? mediaQuery,
}) {
  final Widget app = MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: RecommendationCard(
          recommendation: recommendation,
          detailsFocusNode: FocusNode(debugLabel: 'Details button'),
          onOpenDetails: () {},
        ),
      ),
    ),
  );

  return mediaQuery == null ? app : MediaQuery(data: mediaQuery, child: app);
}

Widget _buildResultsHarness({
  required List<RecommendationSummary> recommendations,
  required PlaceDetailGateway placeDetailGateway,
  required ExternalActionLauncher externalActionLauncher,
  MediaQueryData? mediaQuery,
}) {
  final Widget app = MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: RecommendationResultsSection(
          recommendations: recommendations,
          placeDetailGateway: placeDetailGateway,
          externalActionLauncher: externalActionLauncher,
        ),
      ),
    ),
  );

  return mediaQuery == null ? app : MediaQuery(data: mediaQuery, child: app);
}

final class _StaticPlaceDetailGateway implements PlaceDetailGateway {
  _StaticPlaceDetailGateway({required this.result});

  final PlaceDetailResult result;
  int callCount = 0;

  @override
  Future<PlaceDetailResult> loadPlaceDetail({
    required String recommendationId,
  }) async {
    callCount += 1;
    return result;
  }
}

final class _StaticExternalActionLauncher implements ExternalActionLauncher {
  @override
  Future<ExternalActionLaunchResult> launch(PlaceExternalAction action) async {
    return const ExternalActionLaunchSuccess();
  }
}
