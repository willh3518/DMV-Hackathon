import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/onboarding_entry_flow.dart';
import 'package:accessibility_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('transitions hand focus to Question 1 and back to the CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    await tester.tap(find.byKey(const Key('get_started_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();

    expect(find.text('What accommodations help you?'), findsOneWidget);
    expect(find.text('Question 1 of 5'), findsOneWidget);
    final Focus questionHeading = tester.widget<Focus>(
      find.byKey(const Key('question_one_heading_focus')),
    );
    expect(questionHeading.focusNode?.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('onboarding_back_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();

    expect(find.text('Find places that fit you.'), findsOneWidget);
    final FilledButton getStarted = tester.widget<FilledButton>(
      find.byKey(const Key('get_started_button')),
    );
    expect(getStarted.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the active onboarding step is exposed to semantics', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MainApp());

    expect(find.bySemanticsLabel('Find places that fit you.'), findsOneWidget);
    expect(
      find.bySemanticsLabel('What accommodations help you?'),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('get_started_button')));
    await tester.pump();

    expect(find.bySemanticsLabel('Find places that fit you.'), findsNothing);
    expect(
      find.bySemanticsLabel('What accommodations help you?'),
      findsOneWidget,
    );
    final Finder progress = find.bySemanticsLabel('Onboarding question 1 of 5');
    expect(progress, findsOneWidget);
    expect(
      tester.getSemantics(progress),
      matchesSemantics(
        label: 'Onboarding question 1 of 5',
        value: '20 percent complete',
      ),
    );
    semantics.dispose();
  });

  testWidgets('Sign in gives honest temporary feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -200),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pump();

    expect(
      find.text('Sign in will be available in the next app build.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Question 1 meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.tap(find.byKey(const Key('get_started_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('landing remains usable with large text on a small screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(const MainApp());
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -800),
    );
    await tester.pump();

    expect(find.byKey(const Key('get_started_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Question 1 supports 3.2x text on a small screen', (
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

    await tester.pumpWidget(const MainApp());
    await tester.ensureVisible(find.byKey(const Key('get_started_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('get_started_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();
    await tester.ensureVisible(find.text('Your choices come next'));
    await tester.pump();

    expect(find.text('What accommodations help you?'), findsOneWidget);
    expect(find.text('Your choices come next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MediaQuery disableAnimations uses a short settled crossfade', (
    WidgetTester tester,
  ) async {
    final MediaQueryData mediaQuery = MediaQueryData.fromView(
      tester.view,
    ).copyWith(disableAnimations: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(data: mediaQuery, child: const OnboardingEntryFlow()),
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);
    tester
        .widget<FilledButton>(find.byKey(const Key('get_started_button')))
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('What accommodations help you?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('platform reduceMotion stops and later restarts ambient motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    expect(tester.hasRunningAnimations, isTrue);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);

    tester
        .widget<FilledButton>(find.byKey(const Key('get_started_button')))
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('What accommodations help you?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.hasRunningAnimations, isFalse);

    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });
}
