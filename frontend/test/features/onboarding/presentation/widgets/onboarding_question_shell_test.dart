import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes visible and semantic progress', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(_testApp(shell: _shell(questionNumber: 3)));

    expect(find.text('Question 3 of 5'), findsOneWidget);
    final Finder progress = find.byKey(OnboardingQuestionShell.progressKey);
    expect(progress, findsOneWidget);
    expect(
      tester.getSemantics(progress),
      matchesSemantics(
        label: 'Onboarding question 3 of 5',
        value: '60 percent complete',
      ),
    );
    semantics.dispose();
  });

  testWidgets('invokes Back, Skip, and Continue callbacks', (
    WidgetTester tester,
  ) async {
    int backCount = 0;
    int skipCount = 0;
    int continueCount = 0;

    await tester.pumpWidget(
      _testApp(
        shell: _shell(
          onBack: () => backCount += 1,
          onSkip: () => skipCount += 1,
          onContinue: () => continueCount += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
    await tester.tap(find.byKey(OnboardingQuestionShell.skipButtonKey));
    await tester.tap(find.byKey(OnboardingQuestionShell.continueButtonKey));

    expect(backCount, 1);
    expect(skipCount, 1);
    expect(continueCount, 1);
  });

  testWidgets('disabled and loading states block all interactions', (
    WidgetTester tester,
  ) async {
    int callbackCount = 0;
    int childCallbackCount = 0;

    Future<void> pumpShell({required bool enabled, required bool isLoading}) {
      return tester.pumpWidget(
        _testApp(
          shell: _shell(
            enabled: enabled,
            isLoading: isLoading,
            onBack: () => callbackCount += 1,
            onSkip: () => callbackCount += 1,
            onContinue: () => callbackCount += 1,
            child: TextButton(
              key: const Key('question_choice'),
              onPressed: () => childCallbackCount += 1,
              child: const Text('A choice'),
            ),
          ),
        ),
      );
    }

    await pumpShell(enabled: false, isLoading: false);
    expect(
      tester
          .widget<TextButton>(find.byKey(OnboardingQuestionShell.backButtonKey))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(OnboardingQuestionShell.skipButtonKey))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(OnboardingQuestionShell.continueButtonKey),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.byKey(const Key('question_choice')).hitTestable(),
      findsNothing,
    );

    await pumpShell(enabled: true, isLoading: true);
    expect(
      find.byKey(OnboardingQuestionShell.loadingStatusKey),
      findsOneWidget,
    );
    expect(find.text('Saving your answer'), findsOneWidget);
    expect(
      find.byKey(const Key('question_choice')).hitTestable(),
      findsNothing,
    );
    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
    await tester.tap(find.byKey(OnboardingQuestionShell.skipButtonKey));
    await tester.tap(find.byKey(OnboardingQuestionShell.continueButtonKey));

    expect(callbackCount, 0);
    expect(childCallbackCount, 0);
  });

  testWidgets('can disable Continue without blocking Back or Skip', (
    WidgetTester tester,
  ) async {
    int backCount = 0;
    int skipCount = 0;
    int continueCount = 0;

    await tester.pumpWidget(
      _testApp(
        shell: _shell(
          continueEnabled: false,
          onBack: () => backCount += 1,
          onSkip: () => skipCount += 1,
          onContinue: () => continueCount += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
    await tester.tap(find.byKey(OnboardingQuestionShell.skipButtonKey));
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(OnboardingQuestionShell.continueButtonKey),
          )
          .onPressed,
      isNull,
    );

    expect(backCount, 1);
    expect(skipCount, 1);
    expect(continueCount, 0);
  });

  testWidgets('supports heading focus handoff and predictable traversal', (
    WidgetTester tester,
  ) async {
    final FocusNode backFocusNode = FocusNode(debugLabel: 'Back');
    final FocusNode headingFocusNode = FocusNode(debugLabel: 'Heading');
    final FocusNode choiceFocusNode = FocusNode(debugLabel: 'Choice');
    final FocusNode skipFocusNode = FocusNode(debugLabel: 'Skip');
    final FocusNode continueFocusNode = FocusNode(debugLabel: 'Continue');
    addTearDown(() {
      backFocusNode.dispose();
      headingFocusNode.dispose();
      choiceFocusNode.dispose();
      skipFocusNode.dispose();
      continueFocusNode.dispose();
    });

    await tester.pumpWidget(
      _testApp(
        shell: _shell(
          backFocusNode: backFocusNode,
          headingFocusNode: headingFocusNode,
          skipFocusNode: skipFocusNode,
          continueFocusNode: continueFocusNode,
          child: TextButton(
            focusNode: choiceFocusNode,
            onPressed: () {},
            child: const Text('A choice'),
          ),
        ),
      ),
    );

    headingFocusNode.requestFocus();
    await tester.pump();
    expect(headingFocusNode.hasFocus, isTrue);

    backFocusNode.requestFocus();
    await tester.pump();
    expect(backFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(headingFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(choiceFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(skipFocusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(continueFocusNode.hasFocus, isTrue);
  });

  testWidgets('remains usable at 3.2x text with a keyboard inset', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final MediaQueryData mediaQuery = MediaQueryData.fromView(tester.view)
        .copyWith(
          textScaler: const TextScaler.linear(3.2),
          viewInsets: const EdgeInsets.only(bottom: 220),
        );

    await tester.pumpWidget(
      _testApp(
        mediaQuery: mediaQuery,
        shell: _shell(
          explanation:
              'Choose everything that helps. Your answers remain optional '
              'and can be changed later.',
          child: const TextField(
            decoration: InputDecoration(labelText: 'Something else'),
          ),
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(OnboardingQuestionShell.continueButtonKey),
    );
    await tester.pump();

    expect(find.byKey(OnboardingQuestionShell.scrollViewKey), findsOneWidget);
    expect(
      find.byKey(OnboardingQuestionShell.continueButtonKey),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(shell: _shell()));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

OnboardingQuestionShell _shell({
  int questionNumber = 1,
  String explanation = 'Choose what helps. You can update your answer anytime.',
  Widget child = const Text('Question content'),
  VoidCallback? onBack,
  VoidCallback? onSkip,
  VoidCallback? onContinue,
  FocusNode? headingFocusNode,
  FocusNode? backFocusNode,
  FocusNode? skipFocusNode,
  FocusNode? continueFocusNode,
  bool enabled = true,
  bool continueEnabled = true,
  bool isLoading = false,
}) {
  return OnboardingQuestionShell(
    questionNumber: questionNumber,
    questionCount: 5,
    title: 'What accommodations help you?',
    explanation: explanation,
    headingFocusNode: headingFocusNode,
    backFocusNode: backFocusNode,
    skipFocusNode: skipFocusNode,
    continueFocusNode: continueFocusNode,
    enabled: enabled,
    continueEnabled: continueEnabled,
    isLoading: isLoading,
    onBack: onBack ?? () {},
    onSkip: onSkip ?? () {},
    onContinue: onContinue ?? () {},
    child: child,
  );
}

Widget _testApp({
  required OnboardingQuestionShell shell,
  MediaQueryData? mediaQuery,
}) {
  final Widget body = Scaffold(body: shell);
  return MaterialApp(
    theme: AppTheme.light,
    home: mediaQuery == null ? body : MediaQuery(data: mediaQuery, child: body),
  );
}
