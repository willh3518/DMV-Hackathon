import 'dart:async';

import 'package:accessibility_frontend/contracts/authentication_gateway.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';
import 'package:accessibility_frontend/features/authentication/presentation/authentication_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthenticationScreen', () {
    testWidgets('defaults to sign-up and switches to sign-in mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp(gateway: _FakeAuthenticationGateway()));

      expect(find.text('Create account'), findsWidgets);
      expect(
        find.byKey(const Key('authentication_confirm_password_field')),
        findsOneWidget,
      );

      await tester.tap(find.text('Sign in').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.byKey(const Key('authentication_confirm_password_field')),
        findsNothing,
      );
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets(
      'validates required fields, email format, length, and confirmation',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildApp(gateway: _FakeAuthenticationGateway()),
        );

        await _tapSubmit(tester);

        expect(find.text('Enter your email.'), findsOneWidget);
        expect(find.text('Enter your password.'), findsOneWidget);
        expect(find.text('Confirm your password.'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('authentication_email_field')),
          'not-an-email',
        );
        await tester.enterText(
          find.byKey(const Key('authentication_password_field')),
          'short',
        );
        await tester.enterText(
          find.byKey(const Key('authentication_confirm_password_field')),
          'different',
        );
        await _tapSubmit(tester);

        expect(find.text('Enter a valid email address.'), findsOneWidget);
        expect(find.text('Use at least 8 characters.'), findsOneWidget);
        expect(find.text('Passwords do not match.'), findsOneWidget);
      },
    );

    testWidgets('password visibility controls expose selected semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildApp(gateway: _FakeAuthenticationGateway()),
        );

        final Finder passwordToggle = find.byKey(
          const Key('authentication_password_visibility_button'),
        );
        expect(
          tester.getSemantics(passwordToggle),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            isSelected: false,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        await tester.tap(passwordToggle);
        await tester.pump();

        expect(
          tester.getSemantics(passwordToggle),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            isSelected: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('submits successfully and reports the next step', (
      WidgetTester tester,
    ) async {
      AuthenticationNextStep? nextStep;
      await tester.pumpWidget(
        _buildApp(
          gateway: _FakeAuthenticationGateway(
            result: const AuthenticationSuccess(
              nextStep: StartOnboardingNextStep(),
            ),
          ),
          onAuthenticated: (AuthenticationNextStep value) => nextStep = value,
        ),
      );

      await _enterSignUpCredentials(tester);
      await _tapSubmit(tester);

      expect(nextStep, isA<StartOnboardingNextStep>());
    });

    testWidgets('shows account-exists failure and offers a sign-in switch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          gateway: _FakeAuthenticationGateway(
            result: const AuthenticationFailure(
              reason: AuthenticationFailureReason.accountAlreadyExists,
            ),
          ),
        ),
      );

      await _enterSignUpCredentials(tester);
      await _tapSubmit(tester);

      expect(
        find.text(
          'An account with this email already exists. Try signing in instead.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('switch_to_sign_in_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('switch_to_sign_in_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.byKey(const Key('authentication_confirm_password_field')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('authentication_error_banner')),
        findsNothing,
      );
    });

    testWidgets('guards against duplicate submit while loading', (
      WidgetTester tester,
    ) async {
      final Completer<AuthenticationResult> completer =
          Completer<AuthenticationResult>();
      final _FakeAuthenticationGateway gateway = _FakeAuthenticationGateway(
        completer: completer,
      );

      await tester.pumpWidget(_buildApp(gateway: gateway));
      await _enterSignUpCredentials(tester);

      await _tapSubmit(tester);
      await _tapSubmit(tester);

      expect(gateway.callCount, 1);
      expect(
        find.byKey(const Key('authentication_loading_indicator')),
        findsOneWidget,
      );

      completer.complete(
        const AuthenticationSuccess(nextStep: StartOnboardingNextStep()),
      );
      await tester.pump();
      await tester.pump();
    });

    testWidgets(
      'keyboard actions can submit sign-in mode without pointer input',
      (WidgetTester tester) async {
        AuthenticationNextStep? nextStep;
        await tester.pumpWidget(
          _buildApp(
            gateway: _FakeAuthenticationGateway(
              result: const AuthenticationSuccess(nextStep: OpenChatNextStep()),
            ),
            initialOperation: AuthenticationOperation.signIn,
            onAuthenticated: (AuthenticationNextStep value) => nextStep = value,
          ),
        );

        await tester.enterText(
          find.byKey(const Key('authentication_email_field')),
          'ada@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        final EditableText passwordField = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('authentication_password_field')),
            matching: find.byType(EditableText),
          ),
        );
        expect(passwordField.focusNode.hasFocus, isTrue);

        await tester.enterText(
          find.byKey(const Key('authentication_password_field')),
          'strongpass',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(nextStep, isA<OpenChatNextStep>());
      },
    );

    testWidgets('remains usable with 3.2x text on a 320x568 screen', (
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

      await tester.pumpWidget(_buildApp(gateway: _FakeAuthenticationGateway()));
      await tester.ensureVisible(
        find.byKey(const Key('authentication_submit_button')),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('authentication_submit_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('authentication_terms_button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets automated accessibility guidelines', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp(gateway: _FakeAuthenticationGateway()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}

Widget _buildApp({
  required AuthenticationGateway gateway,
  AuthenticationOperation initialOperation = AuthenticationOperation.signUp,
  ValueChanged<AuthenticationNextStep>? onAuthenticated,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: AuthenticationScreen(
      gateway: gateway,
      initialOperation: initialOperation,
      onBack: () {},
      onAuthenticated: onAuthenticated ?? (_) {},
      onTerms: () {},
      onPrivacy: () {},
    ),
  );
}

Future<void> _enterSignUpCredentials(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('authentication_email_field')),
    'ada@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('authentication_password_field')),
    'strongpass',
  );
  await tester.enterText(
    find.byKey(const Key('authentication_confirm_password_field')),
    'strongpass',
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final Finder submitButton = find.byKey(
    const Key('authentication_submit_button'),
  );
  await tester.ensureVisible(submitButton);
  await tester.pump();
  await tester.tap(submitButton);
  await tester.pump();
}

class _FakeAuthenticationGateway implements AuthenticationGateway {
  _FakeAuthenticationGateway({AuthenticationResult? result, this.completer})
    : result =
          result ??
          const AuthenticationSuccess(nextStep: StartOnboardingNextStep());

  final AuthenticationResult result;
  final Completer<AuthenticationResult>? completer;
  int callCount = 0;

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) {
    callCount += 1;
    return completer?.future ?? Future<AuthenticationResult>.value(result);
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) {
    callCount += 1;
    return completer?.future ?? Future<AuthenticationResult>.value(result);
  }
}
