import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';
import 'package:accessibility_frontend/fixtures/synthetic_authentication_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String syntheticEmail = 'person@example.test';
  const String syntheticPassword = 'invented-test-password';

  test('sign up can route a new user to the start of onboarding', () async {
    final SyntheticAuthenticationGateway gateway =
        SyntheticAuthenticationGateway();

    final AuthenticationResult result = await gateway.signUp(
      email: syntheticEmail,
      password: syntheticPassword,
    );

    expect(result, isA<AuthenticationSuccess>());
    expect(
      (result as AuthenticationSuccess).nextStep,
      isA<StartOnboardingNextStep>(),
    );
  });

  test('sign in can route an incomplete user to a configured step', () async {
    final SyntheticAuthenticationGateway gateway =
        SyntheticAuthenticationGateway(
          signInResult: AuthenticationSuccess(
            nextStep: ResumeOnboardingNextStep(stepIndex: 2),
          ),
        );

    final AuthenticationResult result = await gateway.signIn(
      email: syntheticEmail,
      password: syntheticPassword,
    );

    expect(result, isA<AuthenticationSuccess>());
    final AuthenticationNextStep nextStep =
        (result as AuthenticationSuccess).nextStep;
    expect(nextStep, isA<ResumeOnboardingNextStep>());
    expect((nextStep as ResumeOnboardingNextStep).stepIndex, 2);
  });

  test('sign in can route a complete user to Chat', () async {
    final SyntheticAuthenticationGateway gateway =
        SyntheticAuthenticationGateway();

    final AuthenticationResult result = await gateway.signIn(
      email: syntheticEmail,
      password: syntheticPassword,
    );

    expect(result, isA<AuthenticationSuccess>());
    expect((result as AuthenticationSuccess).nextStep, isA<OpenChatNextStep>());
  });

  test('returns a configured user-safe failure', () async {
    final SyntheticAuthenticationGateway gateway =
        SyntheticAuthenticationGateway(
          signInResult: const AuthenticationFailure(
            reason: AuthenticationFailureReason.invalidCredentials,
          ),
        );

    final AuthenticationResult result = await gateway.signIn(
      email: syntheticEmail,
      password: syntheticPassword,
    );

    expect(result, isA<AuthenticationFailure>());
    final AuthenticationFailure failure = result as AuthenticationFailure;
    expect(
      failure.reason.userMessage,
      'The email or password was not recognized. Check your details and '
      'try again.',
    );
    expect(failure.reason.canRetry, isTrue);
  });

  test('records deterministic non-sensitive operation metadata only', () async {
    final SyntheticAuthenticationGateway gateway =
        SyntheticAuthenticationGateway();

    await gateway.signUp(email: syntheticEmail, password: syntheticPassword);
    await gateway.signIn(email: syntheticEmail, password: syntheticPassword);

    expect(
      gateway.attempts
          .map((SyntheticAuthenticationAttempt attempt) => attempt.operation)
          .toList(),
      <AuthenticationOperation>[
        AuthenticationOperation.signUp,
        AuthenticationOperation.signIn,
      ],
    );
    expect(gateway.attempts.toString(), isNot(contains(syntheticEmail)));
    expect(gateway.attempts.toString(), isNot(contains(syntheticPassword)));
    expect(
      () => gateway.attempts.add(
        const SyntheticAuthenticationAttempt(
          operation: AuthenticationOperation.signIn,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('rejects an onboarding resume index outside the five questions', () {
    expect(
      () => ResumeOnboardingNextStep(stepIndex: onboardingStepCount),
      throwsRangeError,
    );
  });
}
