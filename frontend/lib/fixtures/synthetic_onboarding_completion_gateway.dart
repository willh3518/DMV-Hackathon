import 'package:accessibility_frontend/contracts/onboarding_completion_gateway.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_completion_models.dart';

/// Deterministic frontend-only completion fixture.
///
/// It records only an invocation count and deliberately does not retain the
/// submitted accessibility profile.
final class SyntheticOnboardingCompletionGateway
    implements OnboardingCompletionGateway {
  SyntheticOnboardingCompletionGateway({
    this.result = const OnboardingCompletionSuccess(),
  });

  final OnboardingCompletionResult result;
  int callCount = 0;

  @override
  Future<OnboardingCompletionResult> completeOnboarding(
    OnboardingCompletionRequest request,
  ) async {
    callCount += 1;
    return result;
  }
}
