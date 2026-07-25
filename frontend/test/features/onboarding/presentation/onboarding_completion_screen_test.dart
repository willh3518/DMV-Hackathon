import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_completion_models.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/onboarding_completion_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'ready state keeps five question responses editable and submit explicit',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildHarness());

      expect(
        find.text('Ready to submit your five question responses?'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'You can still go back and change any of your five question responses',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Nothing is submitted in this build until you press the button below.',
        ),
        findsOneWidget,
      );
      expect(find.text('Done for now'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(OnboardingCompletionScreen.primaryButtonKey),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('submitting state disables back and exposes live status', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _buildHarness(stage: OnboardingCompletionStage.submitting),
      );

      expect(
        tester
            .widget<TextButton>(
              find.byKey(OnboardingCompletionScreen.backButtonKey),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(OnboardingCompletionScreen.primaryButtonKey),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester.getSemantics(find.byKey(OnboardingCompletionScreen.statusKey)),
        matchesSemantics(
          isLiveRegion: true,
          label:
              'Submitting your question responses. Back and repeated submission are disabled until this state changes.',
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'failure state renders a user-safe retry reason with error semantics',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildHarness(
            stage: OnboardingCompletionStage.failure,
            failureReason: OnboardingCompletionFailureReason.serviceUnavailable,
          ),
        );

        expect(find.text('We could not submit your responses'), findsOneWidget);
        expect(
          find.text(
            'Submission is temporarily unavailable right now. Try again in a moment.',
          ),
          findsOneWidget,
        );
        expect(find.text('Retry submission'), findsOneWidget);
        expect(
          tester.getSemantics(
            find.byKey(OnboardingCompletionScreen.errorStatusKey),
          ),
          matchesSemantics(
            isLiveRegion: true,
            label:
                'Submission failed. Submission is temporarily unavailable right now. Try again in a moment. Retry is available.',
          ),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('confirmed state is only shown when passed confirmed stage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    expect(find.text('Done for now'), findsNothing);

    await tester.pumpWidget(
      _buildHarness(stage: OnboardingCompletionStage.confirmed),
    );

    expect(
      find.text('Your profile setup is confirmed in this frontend build'),
      findsOneWidget,
    );
    expect(find.text('Done for now'), findsOneWidget);
    expect(find.text('Retry submission'), findsNothing);
  });

  testWidgets(
    'submit action is guarded against duplicate taps before stage changes',
    (WidgetTester tester) async {
      int submitCount = 0;

      await tester.pumpWidget(_buildHarness(onSubmit: () => submitCount += 1));

      final Finder primaryButton = find.byKey(
        OnboardingCompletionScreen.primaryButtonKey,
      );
      await tester.ensureVisible(primaryButton);
      await tester.pump();
      await tester.tap(primaryButton);
      await tester.pump();
      await tester.tap(primaryButton);
      await tester.pump();

      expect(submitCount, 1);
      expect(tester.widget<FilledButton>(primaryButton).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(OnboardingCompletionScreen.backButtonKey),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('system back delegates to onBack when back is enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildRouteHarness());
    await tester.tap(find.byKey(const Key('open_completion_route')));
    await tester.pumpAndSettle();

    final ModalRoute<dynamic>? route = ModalRoute.of(
      tester.element(find.byType(OnboardingCompletionScreen)),
    );
    expect(route?.popDisposition, RoutePopDisposition.doNotPop);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingCompletionScreen), findsNothing);
    expect(find.text('Route host'), findsOneWidget);
  });

  testWidgets('system back is blocked while submitting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildRouteHarness(stage: OnboardingCompletionStage.submitting),
    );
    await tester.tap(find.byKey(const Key('open_completion_route')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final ModalRoute<dynamic>? submittingRoute = ModalRoute.of(
      tester.element(find.byType(OnboardingCompletionScreen)),
    );
    expect(submittingRoute?.popDisposition, RoutePopDisposition.doNotPop);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(OnboardingCompletionScreen), findsOneWidget);
    expect(submittingRoute?.isCurrent, isTrue);
  });

  testWidgets('system back is blocked while the local submit lock is active', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildRouteHarness());
    await tester.tap(find.byKey(const Key('open_completion_route')));
    await tester.pumpAndSettle();

    final Finder primaryButton = find.byKey(
      OnboardingCompletionScreen.primaryButtonKey,
    );
    await tester.ensureVisible(primaryButton);
    await tester.pump();
    await tester.tap(primaryButton);
    await tester.pump();

    final ModalRoute<dynamic>? lockedRoute = ModalRoute.of(
      tester.element(find.byType(OnboardingCompletionScreen)),
    );
    expect(lockedRoute?.popDisposition, RoutePopDisposition.doNotPop);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(OnboardingCompletionScreen), findsOneWidget);
    expect(lockedRoute?.isCurrent, isTrue);
  });

  testWidgets('confirmed continue keeps Back enabled afterward', (
    WidgetTester tester,
  ) async {
    int continueCount = 0;

    await tester.pumpWidget(
      _buildRouteHarness(
        stage: OnboardingCompletionStage.confirmed,
        onContinue: () => continueCount += 1,
      ),
    );
    await tester.tap(find.byKey(const Key('open_completion_route')));
    await tester.pumpAndSettle();

    final Finder primaryButton = find.byKey(
      OnboardingCompletionScreen.primaryButtonKey,
    );
    await tester.ensureVisible(primaryButton);
    await tester.pump();
    await tester.tap(primaryButton);
    await tester.pump();

    expect(continueCount, 1);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(OnboardingCompletionScreen.backButtonKey),
          )
          .onPressed,
      isNotNull,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingCompletionScreen), findsNothing);
    expect(find.text('Route host'), findsOneWidget);
  });

  testWidgets('visible Back still pops the route in ready state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildRouteHarness());
    await tester.tap(find.byKey(const Key('open_completion_route')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(OnboardingCompletionScreen.backButtonKey),
    );
    await tester.pump();
    await tester.tap(find.byKey(OnboardingCompletionScreen.backButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingCompletionScreen), findsNothing);
    expect(find.text('Route host'), findsOneWidget);
  });

  testWidgets('supports heading focus handoff without traversal', (
    WidgetTester tester,
  ) async {
    final FocusNode headingFocusNode = FocusNode(
      debugLabel: 'Completion heading',
    );
    addTearDown(headingFocusNode.dispose);

    await tester.pumpWidget(_buildHarness(headingFocusNode: headingFocusNode));

    final Focus headingFocus = tester.widget<Focus>(
      find.byKey(OnboardingCompletionScreen.headingFocusKey),
    );
    expect(headingFocus.skipTraversal, isTrue);

    headingFocusNode.requestFocus();
    await tester.pump();
    expect(headingFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(headingFocusNode.hasFocus, isFalse);
  });

  testWidgets(
    'submitting uses static feedback when reduced motion is enabled',
    (WidgetTester tester) async {
      final MediaQueryData mediaQuery = MediaQueryData.fromView(
        tester.view,
      ).copyWith(disableAnimations: true);

      await tester.pumpWidget(
        _buildHarness(
          stage: OnboardingCompletionStage.submitting,
          mediaQuery: mediaQuery,
          includeBackdrop: false,
        ),
      );

      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('remains usable at 3.2x text on a 320x568 screen', (
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

    await tester.pumpWidget(_buildHarness());
    await tester.ensureVisible(
      find.byKey(OnboardingCompletionScreen.primaryButtonKey),
    );
    await tester.pump();

    expect(
      find.byKey(OnboardingCompletionScreen.scrollViewKey),
      findsOneWidget,
    );
    expect(
      find.byKey(OnboardingCompletionScreen.primaryButtonKey),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

Widget _buildHarness({
  OnboardingCompletionStage stage = OnboardingCompletionStage.ready,
  OnboardingCompletionFailureReason? failureReason,
  FocusNode? headingFocusNode,
  VoidCallback? onBack,
  VoidCallback? onSubmit,
  VoidCallback? onRetry,
  VoidCallback? onContinue,
  MediaQueryData? mediaQuery,
  bool includeBackdrop = true,
}) {
  final FocusNode ownedHeadingFocusNode =
      headingFocusNode ?? FocusNode(debugLabel: 'Completion heading');

  final Widget screen = OnboardingCompletionScreen(
    stage: stage,
    failureReason: failureReason,
    headingFocusNode: ownedHeadingFocusNode,
    onBack: onBack ?? () {},
    onSubmit: onSubmit ?? () {},
    onRetry: onRetry ?? () {},
    onContinue: onContinue ?? () {},
  );

  final Widget body = Scaffold(
    body: Stack(
      children: <Widget>[if (includeBackdrop) const BubbleBackdrop(), screen],
    ),
  );

  final Widget app = MaterialApp(theme: AppTheme.light, home: body);
  return headingFocusNode == null
      ? _OwnedFocusHarness(
          focusNode: ownedHeadingFocusNode,
          child: mediaQuery == null
              ? app
              : MediaQuery(data: mediaQuery, child: app),
        )
      : mediaQuery == null
      ? app
      : MediaQuery(data: mediaQuery, child: app);
}

class _OwnedFocusHarness extends StatefulWidget {
  const _OwnedFocusHarness({required this.focusNode, required this.child});

  final FocusNode focusNode;
  final Widget child;

  @override
  State<_OwnedFocusHarness> createState() => _OwnedFocusHarnessState();
}

class _OwnedFocusHarnessState extends State<_OwnedFocusHarness> {
  @override
  void dispose() {
    widget.focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Widget _buildRouteHarness({
  OnboardingCompletionStage stage = OnboardingCompletionStage.ready,
  VoidCallback? onBack,
  VoidCallback? onSubmit,
  VoidCallback? onRetry,
  VoidCallback? onContinue,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Route host', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('open_completion_route'),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext routeContext) {
                        return _RouteCompletionScreen(
                          stage: stage,
                          onBack:
                              onBack ??
                              () => Navigator.of(routeContext).pop<void>(),
                          onSubmit: onSubmit ?? () {},
                          onRetry: onRetry ?? () {},
                          onContinue: onContinue ?? () {},
                        );
                      },
                    ),
                  );
                },
                child: const Text('Open completion'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _RouteCompletionScreen extends StatefulWidget {
  const _RouteCompletionScreen({
    required this.stage,
    required this.onBack,
    required this.onSubmit,
    required this.onRetry,
    required this.onContinue,
  });

  final OnboardingCompletionStage stage;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  State<_RouteCompletionScreen> createState() => _RouteCompletionScreenState();
}

class _RouteCompletionScreenState extends State<_RouteCompletionScreen> {
  late final FocusNode _headingFocusNode;

  @override
  void initState() {
    super.initState();
    _headingFocusNode = FocusNode(debugLabel: 'Route completion heading');
  }

  @override
  void dispose() {
    _headingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingCompletionScreen(
        stage: widget.stage,
        headingFocusNode: _headingFocusNode,
        onBack: widget.onBack,
        onSubmit: widget.onSubmit,
        onRetry: widget.onRetry,
        onContinue: widget.onContinue,
      ),
    );
  }
}
