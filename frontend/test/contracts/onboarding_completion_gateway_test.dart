import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_completion_models.dart';
import 'package:accessibility_frontend/fixtures/synthetic_onboarding_completion_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'synthetic completion returns a typed result without retaining answers',
    () async {
      final SyntheticOnboardingCompletionGateway gateway =
          SyntheticOnboardingCompletionGateway(
            result: const OnboardingCompletionFailure(
              reason: OnboardingCompletionFailureReason.networkUnavailable,
            ),
          );
      const OnboardingCompletionRequest request = OnboardingCompletionRequest(
        submission: OnboardingSubmission(
          accommodations: AccommodationsDraft(),
          experiencePreferences: ExperiencePreferencesDraft(),
          travelComfort: TravelComfortDraft(),
          interests: InterestsDraft(
            options: <InterestOption>{InterestOption.museums},
          ),
          planningSituations: PlanningSituationsDraft(),
        ),
      );

      final OnboardingCompletionResult result = await gateway
          .completeOnboarding(request);

      expect(result, isA<OnboardingCompletionFailure>());
      expect(gateway.callCount, 1);
    },
  );
}
