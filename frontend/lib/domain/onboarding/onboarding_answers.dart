/// Helpful accommodations a person may choose during Question 1.
///
/// These are constraint candidates only. Selection order does not imply
/// priority, and the frontend must not infer a diagnosis from any option.
enum AccommodationOption {
  stepFreeAccess,
  wheelchairAccessibleSpaces,
  accessibleRestroom,
  accessibleParking,
  seatingAccommodation,
  lowVisionSupport,
  hearingOrCommunicationSupport,
  serviceAnimalAccess,
  staffAssistance,
}

/// Controlled draft state for Question 1.
final class AccommodationsDraft {
  const AccommodationsDraft({
    this.options = const <AccommodationOption>{},
    this.other = '',
  }) : skipped = false;

  const AccommodationsDraft.skipped()
    : options = const <AccommodationOption>{},
      other = '',
      skipped = true;

  final Set<AccommodationOption> options;
  final String other;
  final bool skipped;

  bool get hasAnswer => options.isNotEmpty || other.trim().isNotEmpty;
}

/// Cuisine and food preferences used by Question 2.
enum FoodPreference {
  italian,
  mexican,
  american,
  mediterranean,
  eastAsian,
  southAsian,
  cafesAndBakeries,
}

/// Explicit dietary requirements remain requirements, not soft preferences.
enum DietaryRequirement {
  vegetarian,
  vegan,
  glutenFree,
  halal,
  kosher,
  allergyDiscussionNeeded,
}

/// Service, communication, and environment preferences used by Question 2.
enum ExperiencePreference {
  tableService,
  counterService,
  quieterEnvironment,
  patientStaff,
  simpleExplanations,
  detailedExplanations,
  digitalMenu,
  largeTextMenu,
  softerLighting,
  brighterLighting,
  lowerCrowds,
}

/// Controlled draft state for Question 2.
final class ExperiencePreferencesDraft {
  const ExperiencePreferencesDraft({
    this.food = const <FoodPreference>{},
    this.dietaryRequirements = const <DietaryRequirement>{},
    this.experience = const <ExperiencePreference>{},
    this.otherDietaryRequirement = '',
  }) : skipped = false;

  const ExperiencePreferencesDraft.skipped()
    : food = const <FoodPreference>{},
      dietaryRequirements = const <DietaryRequirement>{},
      experience = const <ExperiencePreference>{},
      otherDietaryRequirement = '',
      skipped = true;

  final Set<FoodPreference> food;
  final Set<DietaryRequirement> dietaryRequirements;
  final Set<ExperiencePreference> experience;
  final String otherDietaryRequirement;
  final bool skipped;

  bool get hasAnswer =>
      food.isNotEmpty ||
      dietaryRequirements.isNotEmpty ||
      experience.isNotEmpty ||
      otherDietaryRequirement.trim().isNotEmpty;
}

/// Working Question 3 choices. Final labels remain configurable.
enum TravelComfortOption {
  fewMinutes,
  quarterMile,
  halfMile,
  oneMile,
  moreThanOneMile,
  depends,
  noDistanceRestriction,
  custom,
}

enum TravelCustomUnit { minutes, miles }

/// Controlled draft state for Question 3.
final class TravelComfortDraft {
  const TravelComfortDraft({
    this.option,
    this.customValue = '',
    this.customUnit,
  }) : skipped = false,
       assert(
         option == TravelComfortOption.custom ||
             (customValue == '' && customUnit == null),
       );

  const TravelComfortDraft.skipped()
    : option = null,
      customValue = '',
      customUnit = null,
      skipped = true;

  final TravelComfortOption? option;
  final String customValue;
  final TravelCustomUnit? customUnit;
  final bool skipped;

  double? get parsedCustomValue {
    final double? parsed = double.tryParse(customValue.trim());
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  bool get hasValidCustomAnswer =>
      option == TravelComfortOption.custom &&
      parsedCustomValue != null &&
      customUnit != null;

  bool get hasAnswer {
    final TravelComfortOption? selected = option;
    if (selected == null) {
      return false;
    }
    if (selected != TravelComfortOption.custom) {
      return true;
    }
    return hasValidCustomAnswer;
  }
}

/// Place and activity interests used by Question 4.
enum InterestOption {
  restaurantsAndCafes,
  museums,
  parksAndNature,
  shopping,
  liveMusic,
  moviesAndTheater,
  sports,
  games,
  artsAndCrafts,
  socialActivities,
  familyActivities,
}

/// Controlled draft state for Question 4.
final class InterestsDraft {
  const InterestsDraft({
    this.options = const <InterestOption>{},
    this.other = '',
  }) : skipped = false;

  const InterestsDraft.skipped()
    : options = const <InterestOption>{},
      other = '',
      skipped = true;

  final Set<InterestOption> options;
  final String other;
  final bool skipped;

  bool get hasAnswer => options.isNotEmpty || other.trim().isNotEmpty;
}

/// Functional situations a person may want a place recommendation to avoid or
/// plan around. These do not encode a diagnosis.
enum PlanningSituation {
  stairs,
  longPeriodsOfStanding,
  narrowOrCrowdedSpaces,
  loudEnvironments,
  flashingOrIntenseLighting,
  longTravelDistances,
  complexInstructions,
  unexpectedPhysicalContact,
  largeCrowds,
  limitedRestroomAccess,
}

/// Controlled draft state for Question 5.
final class PlanningSituationsDraft {
  const PlanningSituationsDraft({
    this.situations = const <PlanningSituation>{},
    this.other = '',
  }) : noneApply = false,
       preferNotToSay = false,
       skipped = false;

  const PlanningSituationsDraft.none()
    : situations = const <PlanningSituation>{},
      other = '',
      noneApply = true,
      preferNotToSay = false,
      skipped = false;

  const PlanningSituationsDraft.preferNotToSay()
    : situations = const <PlanningSituation>{},
      other = '',
      noneApply = false,
      preferNotToSay = true,
      skipped = false;

  const PlanningSituationsDraft.skipped()
    : situations = const <PlanningSituation>{},
      other = '',
      noneApply = false,
      preferNotToSay = false,
      skipped = true;

  final Set<PlanningSituation> situations;
  final String other;
  final bool noneApply;
  final bool preferNotToSay;
  final bool skipped;

  bool get hasAnswer =>
      noneApply ||
      preferNotToSay ||
      situations.isNotEmpty ||
      other.trim().isNotEmpty;
}

/// Complete five-question draft passed to the external completion contract.
final class OnboardingSubmission {
  const OnboardingSubmission({
    required this.accommodations,
    required this.experiencePreferences,
    required this.travelComfort,
    required this.interests,
    required this.planningSituations,
  });

  final AccommodationsDraft accommodations;
  final ExperiencePreferencesDraft experiencePreferences;
  final TravelComfortDraft travelComfort;
  final InterestsDraft interests;
  final PlanningSituationsDraft planningSituations;
}
