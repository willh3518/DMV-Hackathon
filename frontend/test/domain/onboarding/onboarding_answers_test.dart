import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2 onboarding drafts', () {
    test('distinguishes unanswered, answered, and skipped states', () {
      const AccommodationsDraft unanswered = AccommodationsDraft();
      const AccommodationsDraft answered = AccommodationsDraft(
        options: <AccommodationOption>{AccommodationOption.stepFreeAccess},
      );
      const AccommodationsDraft skipped = AccommodationsDraft.skipped();

      expect(unanswered.hasAnswer, isFalse);
      expect(unanswered.skipped, isFalse);
      expect(answered.hasAnswer, isTrue);
      expect(answered.skipped, isFalse);
      expect(answered.options, contains(AccommodationOption.stepFreeAccess));
      expect(skipped.hasAnswer, isFalse);
      expect(skipped.skipped, isTrue);
      expect(skipped.options, isEmpty);
      expect(skipped.other, isEmpty);
    });

    test('keeps dietary requirements separate from other preferences', () {
      const ExperiencePreferencesDraft draft = ExperiencePreferencesDraft(
        food: <FoodPreference>{FoodPreference.italian},
        dietaryRequirements: <DietaryRequirement>{
          DietaryRequirement.allergyDiscussionNeeded,
        },
        experience: <ExperiencePreference>{
          ExperiencePreference.quieterEnvironment,
        },
      );

      expect(draft.hasAnswer, isTrue);
      expect(
        draft.dietaryRequirements,
        contains(DietaryRequirement.allergyDiscussionNeeded),
      );
      expect(
        draft.experience,
        contains(ExperiencePreference.quieterEnvironment),
      );

      const ExperiencePreferencesDraft skipped =
          ExperiencePreferencesDraft.skipped();
      expect(skipped.hasAnswer, isFalse);
      expect(skipped.skipped, isTrue);
      expect(skipped.food, isEmpty);
      expect(skipped.dietaryRequirements, isEmpty);
      expect(skipped.experience, isEmpty);
      expect(skipped.otherDietaryRequirement, isEmpty);
    });

    test('requires an explicit unit for a custom travel value', () {
      const TravelComfortDraft incomplete = TravelComfortDraft(
        option: TravelComfortOption.custom,
        customValue: '12',
      );
      const TravelComfortDraft duration = TravelComfortDraft(
        option: TravelComfortOption.custom,
        customValue: '12',
        customUnit: TravelCustomUnit.minutes,
      );
      const TravelComfortDraft preset = TravelComfortDraft(
        option: TravelComfortOption.halfMile,
      );
      const TravelComfortDraft skipped = TravelComfortDraft.skipped();

      expect(incomplete.hasAnswer, isFalse);
      expect(duration.hasAnswer, isTrue);
      expect(preset.hasAnswer, isTrue);
      expect(skipped.hasAnswer, isFalse);
      expect(skipped.skipped, isTrue);
    });

    test(
      'rejects invalid custom travel values even when a unit is present',
      () {
        const List<TravelComfortDraft> invalidDrafts = <TravelComfortDraft>[
          TravelComfortDraft(
            option: TravelComfortOption.custom,
            customValue: '0',
            customUnit: TravelCustomUnit.minutes,
          ),
          TravelComfortDraft(
            option: TravelComfortOption.custom,
            customValue: '-3',
            customUnit: TravelCustomUnit.miles,
          ),
          TravelComfortDraft(
            option: TravelComfortOption.custom,
            customValue: 'abc',
            customUnit: TravelCustomUnit.minutes,
          ),
          TravelComfortDraft(
            option: TravelComfortOption.custom,
            customValue: 'NaN',
            customUnit: TravelCustomUnit.miles,
          ),
          TravelComfortDraft(
            option: TravelComfortOption.custom,
            customValue: 'Infinity',
            customUnit: TravelCustomUnit.minutes,
          ),
        ];

        for (final TravelComfortDraft draft in invalidDrafts) {
          expect(draft.parsedCustomValue, isNull);
          expect(draft.hasValidCustomAnswer, isFalse);
          expect(draft.hasAnswer, isFalse);
        }

        const TravelComfortDraft validDraft = TravelComfortDraft(
          option: TravelComfortOption.custom,
          customValue: '12.5',
          customUnit: TravelCustomUnit.miles,
        );
        expect(validDraft.parsedCustomValue, 12.5);
        expect(validDraft.hasValidCustomAnswer, isTrue);
        expect(validDraft.hasAnswer, isTrue);
      },
    );

    test('keeps interests optional and Skip distinct', () {
      const InterestsDraft answered = InterestsDraft(
        options: <InterestOption>{
          InterestOption.restaurantsAndCafes,
          InterestOption.museums,
        },
      );
      const InterestsDraft skipped = InterestsDraft.skipped();

      expect(answered.hasAnswer, isTrue);
      expect(skipped.hasAnswer, isFalse);
      expect(skipped.skipped, isTrue);
    });

    test('distinguishes Q5 None, Skip, and answers', () {
      const PlanningSituationsDraft answered = PlanningSituationsDraft(
        situations: <PlanningSituation>{PlanningSituation.loudEnvironments},
      );
      const PlanningSituationsDraft none = PlanningSituationsDraft.none();
      const PlanningSituationsDraft skipped = PlanningSituationsDraft.skipped();

      expect(answered.hasAnswer, isTrue);
      expect(none.noneApply, isTrue);
      expect(none.hasAnswer, isTrue);
      expect(skipped.skipped, isTrue);
      expect(skipped.hasAnswer, isFalse);
    });
  });
}
