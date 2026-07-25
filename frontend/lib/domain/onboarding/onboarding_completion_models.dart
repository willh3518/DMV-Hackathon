import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';

sealed class OnboardingCompletionResult {
  const OnboardingCompletionResult();
}

final class OnboardingCompletionSuccess extends OnboardingCompletionResult {
  const OnboardingCompletionSuccess();
}

enum OnboardingCompletionFailureReason {
  networkUnavailable(
    userMessage: 'We could not connect. Check your connection and try again.',
    canRetry: true,
  ),
  serviceUnavailable(
    userMessage: 'Profile setup is temporarily unavailable. Please try again.',
    canRetry: true,
  ),
  unknown(
    userMessage: 'We could not finish setting up your profile. Try again.',
    canRetry: true,
  );

  const OnboardingCompletionFailureReason({
    required this.userMessage,
    required this.canRetry,
  });

  final String userMessage;
  final bool canRetry;
}

final class OnboardingCompletionFailure extends OnboardingCompletionResult {
  const OnboardingCompletionFailure({required this.reason});

  final OnboardingCompletionFailureReason reason;
}

final class OnboardingCompletionRequest {
  const OnboardingCompletionRequest({required this.submission});

  final OnboardingSubmission submission;
}
