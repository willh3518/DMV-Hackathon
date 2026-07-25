import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';

class QuestionOneScreen extends StatefulWidget {
  const QuestionOneScreen({
    required this.draft,
    required this.onChanged,
    required this.headingFocusNode,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
    this.enabled = true,
    super.key,
  });

  static const Key otherFieldKey = Key('question_one_other_field');
  static const Key preferNotToSayKey = Key('question_one_prefer_not_to_say');

  static Key optionKey(AccommodationOption option) {
    return ValueKey<AccommodationOption>(option);
  }

  final AccommodationsDraft draft;
  final ValueChanged<AccommodationsDraft> onChanged;
  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final bool enabled;

  @override
  State<QuestionOneScreen> createState() => _QuestionOneScreenState();
}

class _QuestionOneScreenState extends State<QuestionOneScreen> {
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(text: widget.draft.other);
  }

  @override
  void didUpdateWidget(QuestionOneScreen oldWidget) {
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

  void _changeOption(AccommodationOption option, bool selected) {
    final Set<AccommodationOption> nextOptions = Set<AccommodationOption>.of(
      widget.draft.options,
    );
    if (selected) {
      nextOptions.add(option);
    } else {
      nextOptions.remove(option);
    }

    widget.onChanged(
      AccommodationsDraft(
        options: Set<AccommodationOption>.unmodifiable(nextOptions),
        other: widget.draft.preferNotToSay ? '' : widget.draft.other,
      ),
    );
  }

  void _changeOther(String value) {
    widget.onChanged(
      AccommodationsDraft(
        options: widget.draft.preferNotToSay
            ? const <AccommodationOption>{}
            : widget.draft.options,
        other: value,
      ),
    );
  }

  void _changePreferNotToSay(bool selected) {
    widget.onChanged(
      selected
          ? const AccommodationsDraft.preferNotToSay()
          : const AccommodationsDraft(),
    );
  }

  void _skip() {
    widget.onChanged(const AccommodationsDraft.skipped());
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionShell(
      questionNumber: 1,
      questionCount: 5,
      title: 'What accommodations help you?',
      explanation:
          'Choose any that help us understand which places may work for you. '
          'You do not need to name a diagnosis, and you can change these '
          'answers anytime.',
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
          const SizedBox(height: 16),
          for (final AccommodationOption option in AccommodationOption.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MultiSelectOptionTile(
                key: QuestionOneScreen.optionKey(option),
                label: _labelFor(option),
                selected: widget.draft.options.contains(option),
                enabled: widget.enabled,
                onChanged: (bool selected) => _changeOption(option, selected),
              ),
            ),
          const SizedBox(height: 4),
          TextField(
            key: QuestionOneScreen.otherFieldKey,
            controller: _otherController,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Something else (optional)',
              hintText: 'Describe another accommodation',
              helperText:
                  'Share only what would help us find a place that fits.',
            ),
            onChanged: _changeOther,
          ),
          const SizedBox(height: 24),
          MultiSelectOptionTile(
            key: QuestionOneScreen.preferNotToSayKey,
            label: 'Prefer not to say',
            description:
                'Record that you prefer not to share accommodation details.',
            selected: widget.draft.preferNotToSay,
            enabled: widget.enabled,
            onChanged: _changePreferNotToSay,
          ),
        ],
      ),
    );
  }
}

String _labelFor(AccommodationOption option) {
  return switch (option) {
    AccommodationOption.stepFreeAccess => 'Step-free access',
    AccommodationOption.wheelchairAccessibleSpaces =>
      'Wheelchair-accessible spaces',
    AccommodationOption.accessibleRestroom => 'Accessible restroom',
    AccommodationOption.accessibleParking => 'Accessible parking',
    AccommodationOption.seatingAccommodation => 'Seating accommodations',
    AccommodationOption.lowVisionSupport => 'Low-vision support',
    AccommodationOption.hearingOrCommunicationSupport =>
      'Hearing or communication support',
    AccommodationOption.serviceAnimalAccess => 'Service-animal access',
    AccommodationOption.staffAssistance => 'Staff assistance',
  };
}
