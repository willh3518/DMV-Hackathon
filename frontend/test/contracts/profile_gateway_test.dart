import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/fixtures/synthetic_profile_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'synthetic profile gateway records counts without retaining drafts',
    () async {
      const ProfileSnapshot snapshot = ProfileSnapshot(
        responses: OnboardingSubmission(
          accommodations: AccommodationsDraft.skipped(),
          experiencePreferences: ExperiencePreferencesDraft.skipped(),
          travelComfort: TravelComfortDraft.skipped(),
          interests: InterestsDraft.skipped(),
          planningSituations: PlanningSituationsDraft.none(),
        ),
      );
      final SyntheticProfileGateway gateway = SyntheticProfileGateway(
        loadResult: const ProfileLoadSuccess(profile: snapshot),
      );

      final ProfileLoadResult loadResult = await gateway.loadProfile();
      final ProfileSaveResult saveResult = await gateway.saveProfile(snapshot);

      expect(loadResult, isA<ProfileLoadSuccess>());
      expect(saveResult, isA<ProfileSaveConfirmed>());
      expect(gateway.loadCount, 1);
      expect(gateway.saveCount, 1);
    },
  );
}
