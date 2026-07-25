import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';

/// Controlled Question 5 UI for situations a recommendation should avoid or
/// help the user plan around.
///
/// Selections describe functional situations only. This screen does not infer
/// a diagnosis or priority from an answer.
class QuestionFiveScreen extends StatefulWidget {
  const QuestionFiveScreen({
    required this.draft,
    required this.onChanged,
    required this.headingFocusNode,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
    this.enabled = true,
    super.key,
  });

  static const Key otherFieldKey = Key('question_five_other_field');
  static const Key noneKey = Key('question_five_none');

  static Key situationKey(PlanningSituation situation) =>
      ValueKey<String>('question_five_situation_${situation.name}');

  final PlanningSituationsDraft draft;
  final ValueChanged<PlanningSituationsDraft> onChanged;
  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final bool enabled;

  @override
  State<QuestionFiveScreen> createState() => _QuestionFiveScreenState();
}

class _QuestionFiveScreenState extends State<QuestionFiveScreen> {
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(text: widget.draft.other);
  }

  @override
  void didUpdateWidget(QuestionFiveScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String nextText = widget.draft.other;
    if (_otherController.text != nextText) {
      _otherController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _changeSituation(PlanningSituation situation, bool selected) {
    final Set<PlanningSituation> nextSituations = <PlanningSituation>{
      ...widget.draft.situations,
    };
    if (selected) {
      nextSituations.add(situation);
    } else {
      nextSituations.remove(situation);
    }

    widget.onChanged(
      PlanningSituationsDraft(
        situations: Set<PlanningSituation>.unmodifiable(nextSituations),
        other: widget.draft.other,
      ),
    );
  }

  void _changeOther(String value) {
    widget.onChanged(
      PlanningSituationsDraft(
        situations: widget.draft.situations,
        other: value,
      ),
    );
  }

  void _changeNone(bool selected) {
    widget.onChanged(
      selected
          ? const PlanningSituationsDraft.none()
          : const PlanningSituationsDraft(),
    );
  }

  void _skip() {
    widget.onChanged(const PlanningSituationsDraft.skipped());
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionShell(
      questionNumber: 5,
      questionCount: 5,
      title: 'Are there situations we should avoid or plan around?',
      explanation:
          'Choose anything that could affect whether a place works for you. '
          'This is about situations, not diagnoses, and selections are not '
          'ranked. You can change your answers anytime.',
      headingFocusNode: widget.headingFocusNode,
      enabled: widget.enabled,
      onBack: widget.onBack,
      onSkip: _skip,
      onContinue: widget.onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Select all that apply',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Choose situations that would help us find a place that fits. '
            'Selection order does not set priority.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final PlanningSituation situation in PlanningSituation.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MultiSelectOptionTile(
                key: QuestionFiveScreen.situationKey(situation),
                label: _labelFor(situation),
                selected: widget.draft.situations.contains(situation),
                enabled: widget.enabled,
                onChanged: (bool selected) =>
                    _changeSituation(situation, selected),
              ),
            ),
          MultiSelectOptionTile(
            key: QuestionFiveScreen.noneKey,
            label: 'None',
            description: 'None of these situations affect the places I choose.',
            selected: widget.draft.noneApply,
            enabled: widget.enabled,
            onChanged: _changeNone,
          ),
          const SizedBox(height: 20),
          TextField(
            key: QuestionFiveScreen.otherFieldKey,
            controller: _otherController,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Something else (optional)',
              hintText: 'Describe another situation',
              helperText:
                  'Share only what would help us recommend a fitting place.',
            ),
            onChanged: _changeOther,
          ),
        ],
      ),
    );
  }
}

String _labelFor(PlanningSituation situation) {
  return switch (situation) {
    PlanningSituation.stairs => 'Stairs',
    PlanningSituation.longPeriodsOfStanding => 'Long periods of standing',
    PlanningSituation.narrowOrCrowdedSpaces => 'Narrow or crowded spaces',
    PlanningSituation.loudEnvironments => 'Loud environments',
    PlanningSituation.flashingOrIntenseLighting =>
      'Flashing or intense lighting',
    PlanningSituation.longTravelDistances => 'Long travel distances',
    PlanningSituation.complexInstructions => 'Complex instructions',
    PlanningSituation.unexpectedPhysicalContact =>
      'Unexpected physical contact',
    PlanningSituation.largeCrowds => 'Large crowds',
    PlanningSituation.limitedRestroomAccess => 'Limited restroom access',
  };
}
