import 'package:accessibility_frontend/domain/onboarding/onboarding_completion_models.dart';

abstract interface class OnboardingCompletionGateway {
  Future<OnboardingCompletionResult> completeOnboarding(
    OnboardingCompletionRequest request,
  );
}
