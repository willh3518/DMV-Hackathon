import 'package:accessibility_frontend/contracts/authentication_gateway.dart';
import 'package:accessibility_frontend/app/main_app_shell.dart';
import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/onboarding_entry_flow.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_five_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_one_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_two_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:accessibility_frontend/features/profile/presentation/profile_screen.dart';
import 'package:accessibility_frontend/fixtures/synthetic_authentication_gateway.dart';
import 'package:accessibility_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('transitions hand focus to Question 1 and back to the CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await _completeSignUp(tester);

    expect(find.text('What accommodations help you?'), findsOneWidget);
    expect(find.text('Question 1 of 5'), findsOneWidget);
    final Focus questionHeading = tester.widget<Focus>(
      find.byKey(OnboardingQuestionShell.headingFocusKey),
    );
    expect(questionHeading.focusNode?.hasFocus, isTrue);

    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
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

    await _completeSignUp(tester);

    final ExcludeSemantics landingGate = tester.widget<ExcludeSemantics>(
      find.byKey(const Key('landing_semantics_gate')),
    );
    final ExcludeSemantics questionGate = tester.widget<ExcludeSemantics>(
      find.byKey(const Key('question_semantics_gate')),
    );
    expect(landingGate.excluding, isTrue);
    expect(questionGate.excluding, isFalse);
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

  testWidgets('Sign in opens authentication in returning-user mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    final Finder signIn = find.byKey(const Key('sign_in_button'));
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.byKey(const Key('authentication_confirm_password_field')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('authentication_back_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();

    expect(find.text('Find places that fit you.'), findsOneWidget);
    final TextButton signInButton = tester.widget<TextButton>(
      find.byKey(const Key('sign_in_button')),
    );
    expect(signInButton.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default returning-user sign in opens Chat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    await _completeSignIn(tester);

    expect(find.text('Find a place'), findsOneWidget);
    expect(find.byKey(MainAppShell.navigationBarKey), findsOneWidget);

    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();
    expect(find.byKey(ProfileScreen.loadErrorKey), findsOneWidget);
    expect(find.text('Step-free access'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Get started opens authentication and back restores its CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    final Finder getStarted = find.byKey(const Key('get_started_button'));
    await tester.ensureVisible(getStarted);
    await tester.tap(getStarted);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Create account'), findsWidgets);

    await tester.tap(find.byKey(const Key('authentication_back_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump();

    final FilledButton getStartedButton = tester.widget<FilledButton>(
      getStarted,
    );
    expect(getStartedButton.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resume opens the available saved question and restores origin', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OnboardingEntryFlow(
          authenticationGateway: SyntheticAuthenticationGateway(
            signInResult: AuthenticationSuccess(
              nextStep: ResumeOnboardingNextStep(stepIndex: 1),
            ),
          ),
        ),
      ),
    );

    await _completeSignIn(tester);

    expect(
      find.text('What kind of experience works best for you?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
    await _settleQuestionTransition(tester);

    expect(find.text('What accommodations help you?'), findsOneWidget);

    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
    await _settleQuestionTransition(tester);

    final TextButton signInButton = tester.widget<TextButton>(
      find.byKey(const Key('sign_in_button')),
    );
    expect(signInButton.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resume opens Question 4 directly when that is the saved step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OnboardingEntryFlow(
          authenticationGateway: SyntheticAuthenticationGateway(
            signInResult: AuthenticationSuccess(
              nextStep: ResumeOnboardingNextStep(stepIndex: 3),
            ),
          ),
        ),
      ),
    );

    await _completeSignIn(tester);

    expect(
      find.text('What kinds of places and activities interest you?'),
      findsOneWidget,
    );
    expect(find.text('Question 4 of 5'), findsOneWidget);
  });

  testWidgets('Q1 and Q2 answers persist through Q3 and Back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await _completeSignUp(tester);

    await tester.tap(
      find.byKey(
        QuestionOneScreen.optionKey(AccommodationOption.stepFreeAccess),
      ),
    );
    await tester.pump();
    await _continueToNextQuestion(tester);

    expect(
      find.text('What kind of experience works best for you?'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(QuestionTwoScreen.foodOptionKey(FoodPreference.italian)),
    );
    await tester.pump();
    await _continueToNextQuestion(tester);

    expect(
      find.text(
        'How far are you comfortable traveling without a private vehicle?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
    await _settleQuestionTransition(tester);
    final MultiSelectOptionTile italian = tester.widget<MultiSelectOptionTile>(
      find.byKey(QuestionTwoScreen.foodOptionKey(FoodPreference.italian)),
    );
    expect(italian.selected, isTrue);

    await tester.tap(find.byKey(OnboardingQuestionShell.backButtonKey));
    await _settleQuestionTransition(tester);
    final MultiSelectOptionTile stepFree = tester.widget<MultiSelectOptionTile>(
      find.byKey(
        QuestionOneScreen.optionKey(AccommodationOption.stepFreeAccess),
      ),
    );
    expect(stepFree.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing Q5 opens Chat without a submit or confirmed page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await _completeSignUp(tester);

    await _continueToNextQuestion(tester);
    await _continueToNextQuestion(tester);
    final Finder questionThreeSkip = find.byKey(
      OnboardingQuestionShell.skipButtonKey,
    );
    await tester.ensureVisible(questionThreeSkip);
    await tester.pump();
    await tester.tap(questionThreeSkip);
    await _settleQuestionTransition(tester);
    await _continueToNextQuestion(tester);

    final Finder largeCrowds = find.byKey(
      QuestionFiveScreen.situationKey(PlanningSituation.largeCrowds),
    );
    await tester.ensureVisible(largeCrowds);
    await tester.pump();
    await tester.tap(largeCrowds);
    await tester.pump();
    await _continueToNextQuestion(tester);

    expect(find.text('Find a place'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(
      find.text('Ready to submit your five question responses?'),
      findsNothing,
    );
    expect(
      find.text('Your profile setup is confirmed in this frontend build'),
      findsNothing,
    );

    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();
    expect(find.text('Large crowds'), findsOneWidget);

    final Finder signOut = find.byKey(ProfileScreen.signOutButtonKey);
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Find places that fit you.'), findsOneWidget);
  });

  testWidgets(
    'open chat next step returns to landing with an honest root message',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: OnboardingEntryFlow(
            authenticationGateway: _TestAuthenticationGateway(
              signInResult: const AuthenticationSuccess(
                nextStep: OpenChatNextStep(),
              ),
            ),
          ),
        ),
      );

      await _completeSignIn(tester);

      expect(find.text('Find places that fit you.'), findsOneWidget);
      expect(
        find.text(
          'Your account is ready. Chat will connect from the home screen in '
          'a later build.',
        ),
        findsOneWidget,
      );

      final TextButton signInButton = tester.widget<TextButton>(
        find.byKey(const Key('sign_in_button')),
      );
      expect(signInButton.focusNode?.hasFocus, isTrue);
      final ExcludeSemantics questionGate = tester.widget<ExcludeSemantics>(
        find.byKey(const Key('question_semantics_gate')),
      );
      expect(questionGate.excluding, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Question 1 meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await _completeSignUp(tester);

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
    await _completeSignUp(tester);
    await tester.ensureVisible(find.byKey(QuestionOneScreen.otherFieldKey));
    await tester.pump();

    expect(find.text('What accommodations help you?'), findsOneWidget);
    expect(find.text('Something else (optional)'), findsOneWidget);
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
    await _completeSignUp(
      tester,
      routeDuration: const Duration(milliseconds: 100),
    );

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

    await _completeSignUp(
      tester,
      routeDuration: const Duration(milliseconds: 100),
    );

    expect(find.text('What accommodations help you?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.hasRunningAnimations, isFalse);

    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _continueToNextQuestion(WidgetTester tester) async {
  final Finder continueButton = find.byKey(
    OnboardingQuestionShell.continueButtonKey,
  );
  await tester.ensureVisible(continueButton);
  await tester.pump();
  await tester.tap(continueButton);
  await _settleQuestionTransition(tester);
}

Future<void> _settleQuestionTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
  await tester.pump();
}

Future<void> _completeSignUp(
  WidgetTester tester, {
  Duration routeDuration = const Duration(milliseconds: 320),
}) async {
  final Finder getStarted = find.byKey(const Key('get_started_button'));
  await tester.ensureVisible(getStarted);
  await tester.tap(getStarted);
  await tester.pump();
  await tester.pump(routeDuration);

  expect(find.text('Create account'), findsWidgets);

  await tester.enterText(
    find.byKey(const Key('authentication_email_field')),
    'person@example.test',
  );
  await tester.enterText(
    find.byKey(const Key('authentication_password_field')),
    'invented-password',
  );
  await tester.enterText(
    find.byKey(const Key('authentication_confirm_password_field')),
    'invented-password',
  );

  final Finder submit = find.byKey(const Key('authentication_submit_button'));
  await tester.ensureVisible(submit);
  await tester.pump();
  tester.widget<FilledButton>(submit).onPressed?.call();
  await tester.pump();
  await tester.pump(routeDuration);
  await tester.pump();
  await tester.pump(routeDuration);
  await tester.pump();
  await tester.pump(routeDuration);
  await tester.pump();
}

Future<void> _completeSignIn(
  WidgetTester tester, {
  Duration routeDuration = const Duration(milliseconds: 320),
}) async {
  final Finder signIn = find.byKey(const Key('sign_in_button'));
  await tester.ensureVisible(signIn);
  await tester.tap(signIn);
  await tester.pump();
  await tester.pump(routeDuration);

  expect(find.text('Welcome back'), findsOneWidget);

  await tester.enterText(
    find.byKey(const Key('authentication_email_field')),
    'person@example.test',
  );
  await tester.enterText(
    find.byKey(const Key('authentication_password_field')),
    'invented-password',
  );

  final Finder submit = find.byKey(const Key('authentication_submit_button'));
  await tester.ensureVisible(submit);
  await tester.pump();
  tester.widget<FilledButton>(submit).onPressed?.call();
  await tester.pump();
  await tester.pump(routeDuration);
  await tester.pump();
  await tester.pump(routeDuration);
  await tester.pump();
  await tester.pump(routeDuration);
  await tester.pump();
}

class _TestAuthenticationGateway implements AuthenticationGateway {
  const _TestAuthenticationGateway({required this.signInResult});

  final AuthenticationResult signInResult;

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    return signInResult;
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) async {
    return const AuthenticationSuccess(nextStep: StartOnboardingNextStep());
  }
}
