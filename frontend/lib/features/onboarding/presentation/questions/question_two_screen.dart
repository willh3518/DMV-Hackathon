import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';

/// Controlled Question 2 UI for food and dining-experience preferences.
///
/// Dietary answers intentionally remain separate from the two preference
/// groups. This screen records explicit choices without inferring their
/// priority.
class QuestionTwoScreen extends StatefulWidget {
  const QuestionTwoScreen({
    required this.draft,
    required this.onChanged,
    required this.headingFocusNode,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
    this.enabled = true,
    super.key,
  });

  static const Key foodHeadingKey = Key('question_two_food_heading');
  static const Key dietaryHeadingKey = Key('question_two_dietary_heading');
  static const Key experienceHeadingKey = Key(
    'question_two_experience_heading',
  );
  static const Key otherDietaryFieldKey = Key(
    'question_two_other_dietary_field',
  );

  static Key foodOptionKey(FoodPreference option) =>
      ValueKey<String>('question_two_food_${option.name}');

  static Key dietaryOptionKey(DietaryRequirement option) =>
      ValueKey<String>('question_two_dietary_${option.name}');

  static Key experienceOptionKey(ExperiencePreference option) =>
      ValueKey<String>('question_two_experience_${option.name}');

  final ExperiencePreferencesDraft draft;
  final ValueChanged<ExperiencePreferencesDraft> onChanged;
  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final bool enabled;

  @override
  State<QuestionTwoScreen> createState() => _QuestionTwoScreenState();
}

class _QuestionTwoScreenState extends State<QuestionTwoScreen> {
  late final TextEditingController _otherDietaryController;

  @override
  void initState() {
    super.initState();
    _otherDietaryController = TextEditingController(
      text: widget.draft.otherDietaryRequirement,
    );
  }

  @override
  void didUpdateWidget(QuestionTwoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String nextText = widget.draft.otherDietaryRequirement;
    if (_otherDietaryController.text != nextText) {
      _otherDietaryController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  @override
  void dispose() {
    _otherDietaryController.dispose();
    super.dispose();
  }

  void _emit({
    Set<FoodPreference>? food,
    Set<DietaryRequirement>? dietaryRequirements,
    Set<ExperiencePreference>? experience,
    String? otherDietaryRequirement,
  }) {
    widget.onChanged(
      ExperiencePreferencesDraft(
        food: food ?? widget.draft.food,
        dietaryRequirements:
            dietaryRequirements ?? widget.draft.dietaryRequirements,
        experience: experience ?? widget.draft.experience,
        otherDietaryRequirement:
            otherDietaryRequirement ?? widget.draft.otherDietaryRequirement,
      ),
    );
  }

  void _changeFood(FoodPreference option, bool selected) {
    final Set<FoodPreference> next = <FoodPreference>{...widget.draft.food};
    selected ? next.add(option) : next.remove(option);
    _emit(food: next);
  }

  void _changeDietary(DietaryRequirement option, bool selected) {
    final Set<DietaryRequirement> next = <DietaryRequirement>{
      ...widget.draft.dietaryRequirements,
    };
    selected ? next.add(option) : next.remove(option);
    _emit(dietaryRequirements: next);
  }

  void _changeExperience(ExperiencePreference option, bool selected) {
    final Set<ExperiencePreference> next = <ExperiencePreference>{
      ...widget.draft.experience,
    };
    selected ? next.add(option) : next.remove(option);
    _emit(experience: next);
  }

  void _skip() {
    widget.onChanged(const ExperiencePreferencesDraft.skipped());
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionShell(
      questionNumber: 2,
      questionCount: 5,
      title: 'What kind of experience works best for you?',
      explanation:
          'Share what you enjoy and what helps you feel comfortable. '
          'Preferences are not ranked, and you can update them anytime.',
      headingFocusNode: widget.headingFocusNode,
      enabled: widget.enabled,
      onBack: widget.onBack,
      onSkip: _skip,
      onContinue: widget.onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PreferenceSection(
            headingKey: QuestionTwoScreen.foodHeadingKey,
            heading: 'Food and cuisines',
            description:
                'Choose any you enjoy. These are preferences, not ranked '
                'priorities.',
            children: <Widget>[
              for (final FoodPreference option in FoodPreference.values)
                MultiSelectOptionTile(
                  key: QuestionTwoScreen.foodOptionKey(option),
                  label: _foodLabels[option]!,
                  selected: widget.draft.food.contains(option),
                  enabled: widget.enabled,
                  onChanged: (bool selected) => _changeFood(option, selected),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _PreferenceSection(
            headingKey: QuestionTwoScreen.dietaryHeadingKey,
            heading: 'Dietary requirements',
            description:
                'Selections and anything you add here stay requirements. '
                'We help surface these needs, but do not verify allergy '
                'safety. Confirm details directly with the venue.',
            children: <Widget>[
              for (final DietaryRequirement option in DietaryRequirement.values)
                MultiSelectOptionTile(
                  key: QuestionTwoScreen.dietaryOptionKey(option),
                  label: _dietaryLabels[option]!,
                  selected: widget.draft.dietaryRequirements.contains(option),
                  enabled: widget.enabled,
                  onChanged: (bool selected) =>
                      _changeDietary(option, selected),
                ),
              TextField(
                key: QuestionTwoScreen.otherDietaryFieldKey,
                controller: _otherDietaryController,
                enabled: widget.enabled,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Another dietary requirement',
                  helperText:
                      'Optional. Anything entered here remains a requirement.',
                ),
                onChanged: (String value) =>
                    _emit(otherDietaryRequirement: value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PreferenceSection(
            headingKey: QuestionTwoScreen.experienceHeadingKey,
            heading: 'Service, communication, and environment',
            description:
                'Choose what you prefer. Selecting an item does not make it a '
                'higher priority than another.',
            children: <Widget>[
              for (final ExperiencePreference option
                  in ExperiencePreference.values)
                MultiSelectOptionTile(
                  key: QuestionTwoScreen.experienceOptionKey(option),
                  label: _experienceLabels[option]!,
                  selected: widget.draft.experience.contains(option),
                  enabled: widget.enabled,
                  onChanged: (bool selected) =>
                      _changeExperience(option, selected),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.headingKey,
    required this.heading,
    required this.description,
    required this.children,
  });

  final Key headingKey;
  final String heading;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: SectionSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              key: headingKey,
              header: true,
              child: Text(
                heading,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            for (
              int index = 0;
              index < children.length;
              index += 1
            ) ...<Widget>[
              if (index > 0) const SizedBox(height: 10),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

const Map<FoodPreference, String> _foodLabels = <FoodPreference, String>{
  FoodPreference.italian: 'Italian',
  FoodPreference.mexican: 'Mexican',
  FoodPreference.american: 'American',
  FoodPreference.mediterranean: 'Mediterranean',
  FoodPreference.eastAsian: 'East Asian',
  FoodPreference.southAsian: 'South Asian',
  FoodPreference.cafesAndBakeries: 'Cafés and bakeries',
};

const Map<DietaryRequirement, String> _dietaryLabels =
    <DietaryRequirement, String>{
      DietaryRequirement.vegetarian: 'Vegetarian',
      DietaryRequirement.vegan: 'Vegan',
      DietaryRequirement.glutenFree: 'Gluten-free',
      DietaryRequirement.halal: 'Halal',
      DietaryRequirement.kosher: 'Kosher',
      DietaryRequirement.allergyDiscussionNeeded: 'I need to discuss allergies',
    };

const Map<ExperiencePreference, String> _experienceLabels =
    <ExperiencePreference, String>{
      ExperiencePreference.tableService: 'Table service',
      ExperiencePreference.counterService: 'Counter service',
      ExperiencePreference.quieterEnvironment: 'Quieter environment',
      ExperiencePreference.patientStaff: 'Patient staff',
      ExperiencePreference.simpleExplanations: 'Simple explanations',
      ExperiencePreference.detailedExplanations: 'Detailed explanations',
      ExperiencePreference.digitalMenu: 'Digital menu',
      ExperiencePreference.largeTextMenu: 'Large-text menu',
      ExperiencePreference.softerLighting: 'Softer lighting',
      ExperiencePreference.brighterLighting: 'Brighter lighting',
      ExperiencePreference.lowerCrowds: 'Lower-crowd environment',
    };
