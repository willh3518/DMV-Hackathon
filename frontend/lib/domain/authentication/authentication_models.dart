/// The authentication action initiated by the user.
enum AuthenticationOperation { signUp, signIn }

/// The number of onboarding questions in the Version 1 flow.
const int onboardingStepCount = 5;

/// A successful authentication destination.
///
/// These types describe frontend routing only. They do not contain a provider
/// session, token, or user record.
sealed class AuthenticationNextStep {
  const AuthenticationNextStep();
}

/// Begin onboarding at its first question.
final class StartOnboardingNextStep extends AuthenticationNextStep {
  const StartOnboardingNextStep();
}

/// Continue onboarding at a zero-based question index.
final class ResumeOnboardingNextStep extends AuthenticationNextStep {
  factory ResumeOnboardingNextStep({required int stepIndex}) {
    if (stepIndex < 0 || stepIndex >= onboardingStepCount) {
      throw RangeError.range(
        stepIndex,
        0,
        onboardingStepCount - 1,
        'stepIndex',
      );
    }
    return ResumeOnboardingNextStep._(stepIndex);
  }

  const ResumeOnboardingNextStep._(this.stepIndex);

  final int stepIndex;
}

/// Open the main application on Chat.
final class OpenChatNextStep extends AuthenticationNextStep {
  const OpenChatNextStep();
}

/// A provider-neutral authentication response.
sealed class AuthenticationResult {
  const AuthenticationResult();
}

/// Authentication completed and the client may follow [nextStep].
final class AuthenticationSuccess extends AuthenticationResult {
  const AuthenticationSuccess({required this.nextStep});

  final AuthenticationNextStep nextStep;
}

/// Stable failure categories that can be mapped from an external service.
///
/// Messages are deliberately user-safe and contain no provider details.
enum AuthenticationFailureReason {
  invalidRequest(
    userMessage: 'Check your account details and try again.',
    canRetry: true,
  ),
  invalidCredentials(
    userMessage:
        'The email or password was not recognized. Check your details and '
        'try again.',
    canRetry: true,
  ),
  accountAlreadyExists(
    userMessage:
        'An account with this email already exists. Try signing in instead.',
    canRetry: false,
  ),
  networkUnavailable(
    userMessage: 'We could not connect. Check your connection and try again.',
    canRetry: true,
  ),
  serviceUnavailable(
    userMessage: 'Account access is temporarily unavailable. Please try again.',
    canRetry: true,
  ),
  unknown(
    userMessage: 'Something went wrong. Please try again.',
    canRetry: true,
  );

  const AuthenticationFailureReason({
    required this.userMessage,
    required this.canRetry,
  });

  final String userMessage;
  final bool canRetry;
}

/// Authentication did not complete.
final class AuthenticationFailure extends AuthenticationResult {
  const AuthenticationFailure({required this.reason});

  final AuthenticationFailureReason reason;
}
