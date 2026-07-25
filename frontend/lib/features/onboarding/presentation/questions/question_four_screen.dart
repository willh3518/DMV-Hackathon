import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';

/// Controlled Question 4 UI for optional place and activity interests.
class QuestionFourScreen extends StatefulWidget {
  const QuestionFourScreen({
    required this.draft,
    required this.onChanged,
    required this.headingFocusNode,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
    this.enabled = true,
    super.key,
  });

  static const Key interestsHeadingKey = Key('question_four_interests_heading');
  static const Key foodAndDrinkSectionKey = Key(
    'question_four_food_and_drink_section',
  );
  static const Key foodAndDrinkHeadingKey = Key(
    'question_four_food_and_drink_heading',
  );
  static const Key activitiesSectionKey = Key(
    'question_four_activities_section',
  );
  static const Key activitiesHeadingKey = Key(
    'question_four_activities_heading',
  );
  static const Key otherFieldKey = Key('question_four_other_field');

  static Key optionKey(InterestOption option) =>
      ValueKey<String>('question_four_interest_${option.name}');

  final InterestsDraft draft;
  final ValueChanged<InterestsDraft> onChanged;
  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final bool enabled;

  @override
  State<QuestionFourScreen> createState() => _QuestionFourScreenState();
}

class _QuestionFourScreenState extends State<QuestionFourScreen> {
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(text: widget.draft.other);
  }

  @override
  void didUpdateWidget(QuestionFourScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_otherController.text != widget.draft.other) {
      _otherController.value = TextEditingValue(
        text: widget.draft.other,
        selection: TextSelection.collapsed(offset: widget.draft.other.length),
      );
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _changeOption(InterestOption option, bool selected) {
    final Set<InterestOption> nextOptions = <InterestOption>{
      ...widget.draft.options,
    };
    selected ? nextOptions.add(option) : nextOptions.remove(option);
    widget.onChanged(
      InterestsDraft(
        options: Set<InterestOption>.unmodifiable(nextOptions),
        other: widget.draft.other,
      ),
    );
  }

  void _changeOther(String value) {
    widget.onChanged(
      InterestsDraft(options: widget.draft.options, other: value),
    );
  }

  void _skip() {
    widget.onChanged(const InterestsDraft.skipped());
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionShell(
      questionNumber: 4,
      questionCount: 5,
      title: 'What kinds of places and activities interest you?',
      explanation:
          'Choose anything you enjoy or would like to explore. These are '
          'optional preferences, not ranked priorities, and you can update '
          'them anytime.',
      headingFocusNode: widget.headingFocusNode,
      enabled: widget.enabled,
      onBack: widget.onBack,
      onSkip: _skip,
      onContinue: widget.onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            key: QuestionFourScreen.interestsHeadingKey,
            header: true,
            child: Text(
              'Select all that interest you',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          _InterestSection(
            key: QuestionFourScreen.foodAndDrinkSectionKey,
            headingKey: QuestionFourScreen.foodAndDrinkHeadingKey,
            heading: 'Food and drink',
            children: <Widget>[
              for (final InterestOption option in _foodAndDrinkOptions)
                _buildOption(option),
            ],
          ),
          const SizedBox(height: 18),
          _InterestSection(
            key: QuestionFourScreen.activitiesSectionKey,
            headingKey: QuestionFourScreen.activitiesHeadingKey,
            heading: 'Activities and outings',
            children: <Widget>[
              for (final InterestOption option in _activityOptions)
                _buildOption(option),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            key: QuestionFourScreen.otherFieldKey,
            controller: _otherController,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Something else (optional)',
              hintText: 'Add another place or activity',
              helperText:
                  'Share only interests you want used for recommendations.',
            ),
            onChanged: _changeOther,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(InterestOption option) {
    return MultiSelectOptionTile(
      key: QuestionFourScreen.optionKey(option),
      label: _interestLabels[option]!,
      selected: widget.draft.options.contains(option),
      enabled: widget.enabled,
      onChanged: (bool selected) => _changeOption(option, selected),
    );
  }
}

class _InterestSection extends StatelessWidget {
  const _InterestSection({
    required this.headingKey,
    required this.heading,
    required this.children,
    super.key,
  });

  final Key headingKey;
  final String heading;
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 14),
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

const List<InterestOption> _foodAndDrinkOptions = <InterestOption>[
  InterestOption.restaurantsAndCafes,
];

const List<InterestOption> _activityOptions = <InterestOption>[
  InterestOption.museums,
  InterestOption.parksAndNature,
  InterestOption.shopping,
  InterestOption.liveMusic,
  InterestOption.moviesAndTheater,
  InterestOption.sports,
  InterestOption.games,
  InterestOption.artsAndCrafts,
  InterestOption.socialActivities,
  InterestOption.familyActivities,
];

const Map<InterestOption, String> _interestLabels = <InterestOption, String>{
  InterestOption.restaurantsAndCafes: 'Restaurants and cafés',
  InterestOption.museums: 'Museums',
  InterestOption.parksAndNature: 'Parks and nature',
  InterestOption.shopping: 'Shopping',
  InterestOption.liveMusic: 'Live music',
  InterestOption.moviesAndTheater: 'Movies and theater',
  InterestOption.sports: 'Sports',
  InterestOption.games: 'Games',
  InterestOption.artsAndCrafts: 'Arts and crafts',
  InterestOption.socialActivities: 'Social activities',
  InterestOption.familyActivities: 'Family activities',
};
