import 'dart:async';

import 'package:accessibility_frontend/contracts/external_action_launcher.dart';
import 'package:accessibility_frontend/contracts/place_detail_gateway.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/place_detail_route.dart';
import 'package:accessibility_frontend/fixtures/synthetic_recommendation_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detail route renders loading first and then complete evidence', (
    WidgetTester tester,
  ) async {
    final Completer<PlaceDetailResult> completer =
        Completer<PlaceDetailResult>();
    final _CompleterPlaceDetailGateway gateway = _CompleterPlaceDetailGateway(
      completer: completer,
    );

    await tester.pumpWidget(
      _buildHarness(
        placeDetailGateway: gateway,
        externalActionLauncher: _QueueExternalActionLauncher(),
      ),
    );

    expect(find.byKey(PlaceDetailRoute.loadingStateKey), findsOneWidget);
    expect(gateway.callCount, 1);

    completer.complete(
      const PlaceDetailSuccess(
        detail: SyntheticRecommendationFixtures.restaurantDetail,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(PlaceDetailRoute.loadingStateKey), findsNothing);
    expect(find.text('Business-declared evidence'), findsOneWidget);
    expect(find.text('Customer-observed evidence'), findsNWidgets(2));
    expect(find.text('Practical actions'), findsOneWidget);
  });

  testWidgets('detail route retries after a recoverable load failure', (
    WidgetTester tester,
  ) async {
    final _QueuePlaceDetailGateway gateway = _QueuePlaceDetailGateway(
      results: <PlaceDetailResult>[
        const PlaceDetailFailure(
          reason: PlaceDetailFailureReason.serviceUnavailable,
        ),
        const PlaceDetailSuccess(
          detail: SyntheticRecommendationFixtures.restaurantDetail,
        ),
      ],
    );

    await tester.pumpWidget(
      _buildHarness(
        placeDetailGateway: gateway,
        externalActionLauncher: _QueueExternalActionLauncher(),
      ),
    );
    await tester.pump();

    expect(find.byKey(PlaceDetailRoute.errorStateKey), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.byKey(PlaceDetailRoute.retryLoadButtonKey));
    await tester.pump();
    await tester.pump();

    expect(gateway.callCount, 2);
    expect(find.byKey(PlaceDetailRoute.errorStateKey), findsNothing);
    expect(find.text('Business-declared evidence'), findsOneWidget);
  });

  testWidgets('detail route exposes Retry as a semantics tap action', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final _QueuePlaceDetailGateway gateway = _QueuePlaceDetailGateway(
        results: <PlaceDetailResult>[
          const PlaceDetailFailure(
            reason: PlaceDetailFailureReason.serviceUnavailable,
          ),
          const PlaceDetailSuccess(
            detail: SyntheticRecommendationFixtures.restaurantDetail,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildHarness(
          placeDetailGateway: gateway,
          externalActionLauncher: _QueueExternalActionLauncher(),
        ),
      );
      await tester.pump();

      final SemanticsNode retryNode = tester.getSemantics(
        find.byKey(PlaceDetailRoute.errorStateKey),
      );
      expect(
        retryNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      retryNode.owner!.performAction(retryNode.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump();

      expect(gateway.callCount, 2);
      expect(find.byKey(PlaceDetailRoute.errorStateKey), findsNothing);
      expect(find.text('Business-declared evidence'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'detail route surfaces partial evidence, unknown-heavy, and missing-action states',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildHarness(
          placeDetailGateway: _QueuePlaceDetailGateway(
            results: <PlaceDetailResult>[
              PlaceDetailSuccess(detail: _partialUnknownDetail),
            ],
          ),
          externalActionLauncher: _QueueExternalActionLauncher(),
        ),
      );
      await tester.pump();

      expect(find.byKey(PlaceDetailRoute.partialNoticeKey), findsOneWidget);
      expect(
        find.byKey(PlaceDetailRoute.unknownHeavyNoticeKey),
        findsOneWidget,
      );
      expect(
        find.byKey(PlaceDetailRoute.missingActionsNoticeKey),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Unknown means the current contract did not supply',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'detail route shows a retryable generic failure when loaded detail does not match the selected recommendation',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildHarness(
          placeDetailGateway: _QueuePlaceDetailGateway(
            results: const <PlaceDetailResult>[
              PlaceDetailSuccess(detail: _mismatchedDetail),
            ],
          ),
          externalActionLauncher: _QueueExternalActionLauncher(),
        ),
      );
      await tester.pump();

      expect(find.byKey(PlaceDetailRoute.errorStateKey), findsOneWidget);
      expect(find.text('We could not load these details'), findsOneWidget);
      expect(find.byKey(PlaceDetailRoute.retryLoadButtonKey), findsOneWidget);
      expect(find.text('Another Place'), findsNothing);
      expect(find.text('Business-declared evidence'), findsNothing);
      expect(
        find.byKey(PlaceDetailRoute.actionButtonKey(PlaceActionType.website)),
        findsNothing,
      );
    },
  );

  testWidgets(
    'external-action failure keeps detail open and offers retry with copy fallback',
    (WidgetTester tester) async {
      final _ClipboardSpy clipboardSpy = _ClipboardSpy();
      await clipboardSpy.install();
      addTearDown(clipboardSpy.dispose);

      final _QueueExternalActionLauncher launcher =
          _QueueExternalActionLauncher(
            results: <ExternalActionLaunchResult>[
              const ExternalActionLaunchFailure(
                userMessage: 'Directions could not open from this device.',
                fallbackCopyValue: '100 Example Street',
              ),
              const ExternalActionLaunchSuccess(),
            ],
          );

      await tester.pumpWidget(
        _buildHarness(
          placeDetailGateway: _QueuePlaceDetailGateway(
            results: const <PlaceDetailResult>[
              PlaceDetailSuccess(
                detail: SyntheticRecommendationFixtures.restaurantDetail,
              ),
            ],
          ),
          externalActionLauncher: launcher,
        ),
      );
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(
          PlaceDetailRoute.actionButtonKey(PlaceActionType.directions),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          PlaceDetailRoute.actionButtonKey(PlaceActionType.directions),
        ),
      );
      await tester.pump();

      expect(find.byKey(PlaceDetailRoute.actionFailureKey), findsOneWidget);
      expect(find.text('Bluebird Kitchen'), findsOneWidget);
      expect(find.text('Copy address'), findsOneWidget);

      await tester.tap(find.text('Copy address'));
      await tester.pump();

      expect(clipboardSpy.lastCopiedText, '100 Example Street');

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(launcher.callCount, 2);
      expect(find.byKey(PlaceDetailRoute.actionFailureKey), findsNothing);
      expect(find.byType(PlaceDetailRoute), findsOneWidget);
    },
  );

  testWidgets('detail route respects 3.2x text scaling on a small screen', (
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
      _buildHarness(
        placeDetailGateway: _QueuePlaceDetailGateway(
          results: const <PlaceDetailResult>[
            PlaceDetailSuccess(
              detail: SyntheticRecommendationFixtures.restaurantDetail,
            ),
          ],
        ),
        externalActionLauncher: _QueueExternalActionLauncher(),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(PlaceDetailRoute.backButtonKey));
    await tester.ensureVisible(
      find.byKey(PlaceDetailRoute.actionButtonKey(PlaceActionType.directions)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('detail route shows no running animation in reduced motion', (
    WidgetTester tester,
  ) async {
    final MediaQueryData mediaQuery = MediaQueryData.fromView(
      tester.view,
    ).copyWith(disableAnimations: true);

    await tester.pumpWidget(
      _buildHarness(
        placeDetailGateway: _QueuePlaceDetailGateway(
          results: const <PlaceDetailResult>[
            PlaceDetailSuccess(
              detail: SyntheticRecommendationFixtures.restaurantDetail,
            ),
          ],
        ),
        externalActionLauncher: _QueueExternalActionLauncher(),
        mediaQuery: mediaQuery,
      ),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('detail route meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        placeDetailGateway: _QueuePlaceDetailGateway(
          results: const <PlaceDetailResult>[
            PlaceDetailSuccess(
              detail: SyntheticRecommendationFixtures.restaurantDetail,
            ),
          ],
        ),
        externalActionLauncher: _QueueExternalActionLauncher(),
      ),
    );
    await tester.pump();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

Widget _buildHarness({
  required PlaceDetailGateway placeDetailGateway,
  required ExternalActionLauncher externalActionLauncher,
  MediaQueryData? mediaQuery,
}) {
  final Widget app = MaterialApp(
    theme: AppTheme.light,
    home: PlaceDetailRoute(
      recommendation: SyntheticRecommendationFixtures.restaurant,
      placeDetailGateway: placeDetailGateway,
      externalActionLauncher: externalActionLauncher,
      onClose: () {},
    ),
  );

  return mediaQuery == null ? app : MediaQuery(data: mediaQuery, child: app);
}

const PlaceDetail _partialUnknownDetail = PlaceDetail(
  recommendationId: 'restaurant-1',
  placeName: 'Bluebird Kitchen',
  placeTypeLabel: 'Italian restaurant',
  personalizedMatch: PersonalizedMatch(score: 88),
  matchExplanation:
      'Strong step-free access and quieter seating align with this profile.',
  evidenceCoverageNotices: <EvidenceCoverageNotice>{
    EvidenceCoverageNotice.partial,
    EvidenceCoverageNotice.unknownHeavy,
  },
  attributes: <AttributeAssessment>[
    AttributeAssessment(
      label: 'Step-free entrance',
      status: AccessibilityStatus.strength,
      explanation: 'Observed evidence supports the entrance path.',
      observedEvidence: <EvidenceItem>[
        EvidenceItem(
          sourceKind: EvidenceSourceKind.observed,
          summary: 'A recent review described a level front entrance.',
        ),
      ],
    ),
    AttributeAssessment(
      label: 'Restroom maneuverability',
      status: AccessibilityStatus.unknown,
      explanation: 'No reliable evidence was supplied.',
    ),
    AttributeAssessment(
      label: 'Lighting',
      status: AccessibilityStatus.unknown,
      explanation: 'No reliable evidence was supplied.',
    ),
  ],
);

const PlaceDetail _mismatchedDetail = PlaceDetail(
  recommendationId: 'other-place',
  placeName: 'Another Place',
  placeTypeLabel: 'Cafe',
  personalizedMatch: PersonalizedMatch(score: 22),
  matchExplanation: 'This content should never be shown for the selected card.',
  attributes: <AttributeAssessment>[
    AttributeAssessment(
      label: 'Step-free entrance',
      status: AccessibilityStatus.concern,
      explanation: 'Mismatched detail should be hidden.',
      declaredEvidence: <EvidenceItem>[
        EvidenceItem(
          sourceKind: EvidenceSourceKind.declared,
          summary: 'Mismatched evidence should be hidden.',
        ),
      ],
    ),
  ],
  externalActions: <PlaceExternalAction>[
    PlaceExternalAction(
      type: PlaceActionType.website,
      label: 'Website',
      target: 'synthetic://mismatch',
    ),
  ],
);

final class _CompleterPlaceDetailGateway implements PlaceDetailGateway {
  _CompleterPlaceDetailGateway({required this.completer});

  final Completer<PlaceDetailResult> completer;
  int callCount = 0;

  @override
  Future<PlaceDetailResult> loadPlaceDetail({
    required String recommendationId,
  }) {
    callCount += 1;
    return completer.future;
  }
}

final class _QueuePlaceDetailGateway implements PlaceDetailGateway {
  _QueuePlaceDetailGateway({required List<PlaceDetailResult> results})
    : _results = List<PlaceDetailResult>.from(results);

  final List<PlaceDetailResult> _results;
  int callCount = 0;

  @override
  Future<PlaceDetailResult> loadPlaceDetail({
    required String recommendationId,
  }) async {
    callCount += 1;
    return _results.removeAt(0);
  }
}

final class _QueueExternalActionLauncher implements ExternalActionLauncher {
  _QueueExternalActionLauncher({List<ExternalActionLaunchResult>? results})
    : _results = List<ExternalActionLaunchResult>.from(
        results ??
            const <ExternalActionLaunchResult>[ExternalActionLaunchSuccess()],
      );

  final List<ExternalActionLaunchResult> _results;
  int callCount = 0;

  @override
  Future<ExternalActionLaunchResult> launch(PlaceExternalAction action) async {
    callCount += 1;
    return _results.removeAt(0);
  }
}

final class _ClipboardSpy {
  String? lastCopiedText;

  Future<void> install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            lastCopiedText =
                (methodCall.arguments as Map<dynamic, dynamic>)['text']
                    as String?;
          }
          return null;
        });
    return Future<void>.value();
  }

  Future<void> dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    return Future<void>.value();
  }
}
