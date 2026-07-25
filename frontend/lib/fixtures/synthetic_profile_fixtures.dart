import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';

/// Clearly synthetic profile data for isolated previews and tests.
abstract final class SyntheticProfileFixtures {
  static const ProfileSnapshot sampleProfile = ProfileSnapshot(
    responses: OnboardingSubmission(
      accommodations: AccommodationsDraft(
        options: <AccommodationOption>{
          AccommodationOption.stepFreeAccess,
          AccommodationOption.accessibleRestroom,
        },
      ),
      experiencePreferences: ExperiencePreferencesDraft(
        food: <FoodPreference>{FoodPreference.italian},
        experience: <ExperiencePreference>{
          ExperiencePreference.quieterEnvironment,
        },
      ),
      travelComfort: TravelComfortDraft(option: TravelComfortOption.halfMile),
      interests: InterestsDraft(
        options: <InterestOption>{
          InterestOption.restaurantsAndCafes,
          InterestOption.museums,
        },
      ),
      planningSituations: PlanningSituationsDraft(
        situations: <PlanningSituation>{PlanningSituation.loudEnvironments},
      ),
    ),
  );
}
