import 'dart:async';

import 'package:accessibility_frontend/contracts/authentication_gateway.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';
import 'package:accessibility_frontend/features/authentication/presentation/authentication_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthenticationScreen', () {
    testWidgets('moves focus to the screen heading after route entry', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp(gateway: _FakeAuthenticationGateway()));
      await tester.pump();

      final Focus headingFocus = tester.widget<Focus>(
        find.byKey(const Key('authentication_heading_focus')),
      );
      expect(headingFocus.focusNode?.hasFocus, isTrue);
      expect(headingFocus.focusNode?.skipTraversal, isTrue);
    });

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

    testWidgets('mode changes retain focus on the segmented control', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp(gateway: _FakeAuthenticationGateway()));

      final Finder modeSwitch = find.byKey(
        const Key('authentication_mode_switch'),
      );
      for (
        int step = 0;
        step < 4 && !_primaryFocusIsWithin(tester, modeSwitch);
        step += 1
      ) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }

      expect(_primaryFocusIsWithin(tester, modeSwitch), isTrue);
      final FocusNode? modeFocus = FocusManager.instance.primaryFocus;
      tester
          .widget<SegmentedButton<AuthenticationOperation>>(modeSwitch)
          .onSelectionChanged
          ?.call(<AuthenticationOperation>{AuthenticationOperation.signIn});
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, same(modeFocus));
      expect(_primaryFocusIsWithin(tester, modeSwitch), isTrue);
      expect(find.text('Welcome back'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 240));
      expect(_primaryFocusIsWithin(tester, modeSwitch), isTrue);
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

    testWidgets('focuses the first invalid field in form order', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp(gateway: _FakeAuthenticationGateway()));

      await _tapSubmit(tester);
      expect(
        _editableTextFor(
          tester,
          const Key('authentication_email_field'),
        ).focusNode.hasFocus,
        isTrue,
      );

      await tester.enterText(
        find.byKey(const Key('authentication_email_field')),
        'ada@example.com',
      );
      await _tapSubmit(tester);
      expect(
        _editableTextFor(
          tester,
          const Key('authentication_password_field'),
        ).focusNode.hasFocus,
        isTrue,
      );

      await tester.enterText(
        find.byKey(const Key('authentication_password_field')),
        'strongpass',
      );
      await tester.enterText(
        find.byKey(const Key('authentication_confirm_password_field')),
        'different',
      );
      await _tapSubmit(tester);
      expect(
        _editableTextFor(
          tester,
          const Key('authentication_confirm_password_field'),
        ).focusNode.hasFocus,
        isTrue,
      );
    });

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
        expect(find.bySemanticsLabel('Show password'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Show confirmation password'),
          findsOneWidget,
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

        expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
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
      final _FakeAuthenticationGateway gateway = _FakeAuthenticationGateway(
        result: const AuthenticationSuccess(
          nextStep: StartOnboardingNextStep(),
        ),
      );
      await tester.pumpWidget(
        _buildApp(
          gateway: gateway,
          onAuthenticated: (AuthenticationNextStep value) => nextStep = value,
        ),
      );

      await _enterSignUpCredentials(tester);
      await _tapSubmit(tester);

      expect(nextStep, isA<StartOnboardingNextStep>());
      expect(gateway.callCount, 1);
      expect(
        find.byKey(const Key('authentication_loading_status')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('authentication_submit_button')),
            )
            .onPressed,
        isNull,
      );
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

    testWidgets(
      'converts a throwing gateway into an unknown error and focuses it',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _buildApp(
              gateway: _FakeAuthenticationGateway(
                error: StateError('synthetic adapter failure'),
              ),
            ),
          );
          await _enterSignUpCredentials(tester);

          await _tapSubmit(tester);
          await tester.pump();

          expect(
            find.text('Something went wrong. Please try again.'),
            findsOneWidget,
          );
          expect(
            find.textContaining('synthetic adapter failure'),
            findsNothing,
          );

          final Focus errorFocus = tester.widget<Focus>(
            find.byKey(const Key('authentication_error_focus')),
          );
          expect(errorFocus.focusNode?.hasFocus, isTrue);
          expect(errorFocus.focusNode?.skipTraversal, isTrue);

          final SemanticsData errorSemantics = tester
              .getSemantics(
                find.byKey(const Key('authentication_error_announcement')),
              )
              .getSemanticsData();
          expect(errorSemantics.flagsCollection.isLiveRegion, isTrue);
          expect(
            errorSemantics.label,
            'Account access error. Something went wrong. Please try again.',
          );

          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const Key('authentication_submit_button')),
                )
                .onPressed,
            isNotNull,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('guards against duplicate submit while loading', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final Completer<AuthenticationResult> completer =
          Completer<AuthenticationResult>();
      final _FakeAuthenticationGateway gateway = _FakeAuthenticationGateway(
        completer: completer,
      );

      try {
        await tester.pumpWidget(_buildApp(gateway: gateway));
        await _enterSignUpCredentials(tester);

        await _tapSubmit(tester);
        await _tapSubmit(tester);

        expect(gateway.callCount, 1);
        expect(
          find.byKey(const Key('authentication_loading_indicator')),
          findsOneWidget,
        );
        final SemanticsData loadingSemantics = tester
            .getSemantics(
              find.byKey(const Key('authentication_loading_status')),
            )
            .getSemanticsData();
        expect(loadingSemantics.flagsCollection.isLiveRegion, isTrue);
        expect(loadingSemantics.label, 'Creating your account');
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('authentication_submit_button')),
              )
              .onPressed,
          isNull,
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.byKey(const Key('authentication_loading_status')),
          findsOneWidget,
        );

        completer.complete(
          const AuthenticationSuccess(nextStep: StartOnboardingNextStep()),
        );
        await tester.pump();
        await tester.pump();
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'blocks system back during submit and returns one late typed result',
      (WidgetTester tester) async {
        final Completer<AuthenticationResult> completer =
            Completer<AuthenticationResult>();
        final _FakeAuthenticationGateway gateway = _FakeAuthenticationGateway(
          completer: completer,
        );
        AuthenticationNextStep? routeResult;

        await tester.pumpWidget(
          _buildRoutedApp(
            gateway: gateway,
            onResult: (AuthenticationNextStep? result) {
              routeResult = result;
            },
          ),
        );
        await tester.tap(find.byKey(const Key('open_authentication_route')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));

        await _enterSignUpCredentials(tester);
        await _tapSubmit(tester);

        expect(gateway.callCount, 1);
        final ModalRoute<dynamic>? authenticationRoute = ModalRoute.of(
          tester.element(find.byType(AuthenticationScreen)),
        );
        expect(
          authenticationRoute?.popDisposition,
          RoutePopDisposition.doNotPop,
        );

        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(find.byType(AuthenticationScreen), findsOneWidget);
        expect(routeResult, isNull);
        expect(gateway.callCount, 1);

        completer.complete(
          const AuthenticationSuccess(nextStep: StartOnboardingNextStep()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));
        await tester.pump();

        expect(routeResult, isA<StartOnboardingNextStep>());
        expect(find.byType(AuthenticationScreen), findsNothing);
        expect(gateway.callCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

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

    testWidgets(
      'reduced motion settles size changes and uses static loading status',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final Completer<AuthenticationResult> completer =
            Completer<AuthenticationResult>();
        final MediaQueryData mediaQuery = MediaQueryData.fromView(
          tester.view,
        ).copyWith(disableAnimations: true);

        try {
          await tester.pumpWidget(
            _buildApp(
              gateway: _FakeAuthenticationGateway(completer: completer),
              mediaQuery: mediaQuery,
            ),
          );

          expect(find.byType(AnimatedSize), findsNothing);
          for (final AnimatedSwitcher switcher
              in tester.widgetList<AnimatedSwitcher>(
                find.byType(AnimatedSwitcher),
              )) {
            expect(
              switcher.duration,
              lessThanOrEqualTo(const Duration(milliseconds: 100)),
            );
          }

          await _enterSignUpCredentials(tester);
          await _tapSubmit(tester);

          expect(
            find.byKey(const Key('authentication_loading_indicator')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('authentication_loading_static_status')),
            findsOneWidget,
          );
          expect(find.text('Creating your account'), findsOneWidget);

          final SemanticsData loadingSemantics = tester
              .getSemantics(
                find.byKey(const Key('authentication_loading_status')),
              )
              .getSemanticsData();
          expect(loadingSemantics.flagsCollection.isLiveRegion, isTrue);
          expect(loadingSemantics.label, 'Creating your account');

          await tester.pump(const Duration(milliseconds: 100));
          expect(
            find.byKey(const Key('authentication_loading_static_status')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('authentication_loading_indicator')),
            findsNothing,
          );

          completer.complete(
            const AuthenticationFailure(
              reason: AuthenticationFailureReason.unknown,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            find.byKey(const Key('authentication_loading_static_status')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('authentication_error_banner')),
            findsOneWidget,
          );
        } finally {
          semantics.dispose();
        }
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
  MediaQueryData? mediaQuery,
}) {
  final Widget screen = AuthenticationScreen(
    gateway: gateway,
    initialOperation: initialOperation,
    onBack: () {},
    onAuthenticated: onAuthenticated ?? (_) {},
    onTerms: () {},
    onPrivacy: () {},
  );

  return MaterialApp(
    theme: AppTheme.light,
    home: mediaQuery == null
        ? screen
        : MediaQuery(data: mediaQuery, child: screen),
  );
}

Widget _buildRoutedApp({
  required AuthenticationGateway gateway,
  required ValueChanged<AuthenticationNextStep?> onResult,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (BuildContext hostContext) {
        return Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('open_authentication_route'),
              onPressed: () async {
                final AuthenticationNextStep? result =
                    await Navigator.of(
                      hostContext,
                    ).push<AuthenticationNextStep>(
                      MaterialPageRoute<AuthenticationNextStep>(
                        builder: (BuildContext routeContext) {
                          return AuthenticationScreen(
                            gateway: gateway,
                            onBack: () => Navigator.of(routeContext).pop(),
                            onAuthenticated: (AuthenticationNextStep nextStep) {
                              Navigator.of(routeContext).pop(nextStep);
                            },
                            onTerms: () {},
                            onPrivacy: () {},
                          );
                        },
                      ),
                    );
                onResult(result);
              },
              child: const Text('Open authentication'),
            ),
          ),
        );
      },
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

EditableText _editableTextFor(WidgetTester tester, Key fieldKey) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(fieldKey),
      matching: find.byType(EditableText),
    ),
  );
}

bool _primaryFocusIsWithin(WidgetTester tester, Finder ancestorFinder) {
  final Element ancestor = tester.element(ancestorFinder);
  final BuildContext? focusContext =
      FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) {
    return false;
  }
  if (identical(focusContext, ancestor)) {
    return true;
  }

  bool isWithin = false;
  focusContext.visitAncestorElements((Element element) {
    isWithin = identical(element, ancestor);
    return !isWithin;
  });
  return isWithin;
}

class _FakeAuthenticationGateway implements AuthenticationGateway {
  _FakeAuthenticationGateway({
    AuthenticationResult? result,
    this.completer,
    this.error,
  }) : result =
           result ??
           const AuthenticationSuccess(nextStep: StartOnboardingNextStep());

  final AuthenticationResult result;
  final Completer<AuthenticationResult>? completer;
  final Object? error;
  int callCount = 0;

  Future<AuthenticationResult> _nextResult() {
    callCount += 1;
    final Object? thrownError = error;
    if (thrownError != null) {
      return Future<AuthenticationResult>.error(thrownError);
    }
    return completer?.future ?? Future<AuthenticationResult>.value(result);
  }

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) {
    return _nextResult();
  }

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) {
    return _nextResult();
  }
}
