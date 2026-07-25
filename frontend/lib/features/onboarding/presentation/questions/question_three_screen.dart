import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuestionThreeScreen extends StatefulWidget {
  const QuestionThreeScreen({
    required this.draft,
    required this.onChanged,
    required this.headingFocusNode,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
    this.enabled = true,
    super.key,
  });

  final TravelComfortDraft draft;
  final ValueChanged<TravelComfortDraft> onChanged;
  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final bool enabled;

  @override
  State<QuestionThreeScreen> createState() => _QuestionThreeScreenState();
}

class _QuestionThreeScreenState extends State<QuestionThreeScreen> {
  late final TextEditingController _customValueController;
  late final FocusNode _customValueFocusNode;

  bool get _isCustomSelected =>
      widget.draft.option == TravelComfortOption.custom;

  bool get _isContinueEnabled => widget.draft.hasAnswer;

  @override
  void initState() {
    super.initState();
    _customValueController = TextEditingController(
      text: widget.draft.customValue,
    );
    _customValueFocusNode = FocusNode(debugLabel: 'Question 3 custom value');
  }

  @override
  void didUpdateWidget(QuestionThreeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_customValueController.text != widget.draft.customValue) {
      _customValueController.value = TextEditingValue(
        text: widget.draft.customValue,
        selection: TextSelection.collapsed(
          offset: widget.draft.customValue.length,
        ),
      );
    }

    if (oldWidget.draft.option != TravelComfortOption.custom &&
        widget.draft.option == TravelComfortOption.custom) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && widget.enabled) {
          _customValueFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _customValueController.dispose();
    _customValueFocusNode.dispose();
    super.dispose();
  }

  void _selectOption(TravelComfortOption option) {
    if (!widget.enabled) {
      return;
    }

    if (option == TravelComfortOption.custom) {
      widget.onChanged(
        TravelComfortDraft(
          option: TravelComfortOption.custom,
          customValue: widget.draft.option == TravelComfortOption.custom
              ? widget.draft.customValue
              : '',
          customUnit: widget.draft.option == TravelComfortOption.custom
              ? widget.draft.customUnit
              : null,
        ),
      );
      return;
    }

    widget.onChanged(TravelComfortDraft(option: option));
  }

  void _updateCustomValue(String value) {
    if (!widget.enabled || !_isCustomSelected) {
      return;
    }

    widget.onChanged(
      TravelComfortDraft(
        option: TravelComfortOption.custom,
        customValue: value,
        customUnit: widget.draft.customUnit,
      ),
    );
  }

  void _selectCustomUnit(TravelCustomUnit unit) {
    if (!widget.enabled || !_isCustomSelected) {
      return;
    }

    widget.onChanged(
      TravelComfortDraft(
        option: TravelComfortOption.custom,
        customValue: widget.draft.customValue,
        customUnit: unit,
      ),
    );
  }

  Widget _buildCustomDetails(BuildContext context) {
    final bool reduceMotion = AppMotion.prefersReducedMotion(context);
    final Widget content = _isCustomSelected
        ? KeyedSubtree(
            key: const Key('question_three_custom_section'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 18),
                const Divider(color: AppColors.surfaceBlueStrong, height: 1),
                const SizedBox(height: 18),
                Text(
                  'Custom travel limit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter a positive number, then choose Minutes or Miles for the time or distance that works for you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: TextField(
                    key: const Key('question_three_custom_value_field'),
                    controller: _customValueController,
                    focusNode: _customValueFocusNode,
                    enabled: widget.enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Custom value',
                      hintText: 'Enter minutes or miles',
                    ),
                    onChanged: _updateCustomValue,
                  ),
                ),
                const SizedBox(height: 14),
                _CustomUnitSelector(
                  selectedUnit: widget.draft.customUnit,
                  enabled: widget.enabled,
                  onSelected: _selectCustomUnit,
                ),
                const SizedBox(height: 12),
                Text(
                  _isContinueEnabled
                      ? 'Your custom answer is ready to continue.'
                      : 'Choose a positive finite value and one unit to continue.',
                  key: const Key('question_three_custom_helper_text'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          )
        : const SizedBox.shrink(key: Key('question_three_custom_hidden'));

    if (reduceMotion) {
      return content;
    }

    return AnimatedSize(
      duration: AppMotion.resolveDuration(context),
      curve: AppMotion.standardCurve,
      child: AnimatedSwitcher(
        duration: AppMotion.resolveDuration(context),
        switchInCurve: AppMotion.standardCurve,
        switchOutCurve: AppMotion.standardCurve,
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionShell(
      questionNumber: 3,
      questionCount: 5,
      title: 'How far are you comfortable traveling without a private vehicle?',
      explanation:
          'Share the time or distance that usually works for you when walking, rolling, or using transit. This does not assume anything about your mobility, and you can skip it or update it later.',
      headingFocusNode: widget.headingFocusNode,
      enabled: widget.enabled,
      continueEnabled: _isContinueEnabled,
      onBack: widget.onBack,
      onSkip: () {
        widget.onChanged(const TravelComfortDraft.skipped());
        widget.onSkip();
      },
      onContinue: widget.onContinue,
      child: SectionSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Choose one answer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'We use this only to understand your travel comfort for places you might reach without a private vehicle.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            for (final _TravelOptionSpec spec in _travelOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TravelOptionTile(
                  option: spec.option,
                  label: spec.label,
                  hint: spec.hint,
                  isSelected: widget.draft.option == spec.option,
                  enabled: widget.enabled,
                  onSelected: _selectOption,
                ),
              ),
            _buildCustomDetails(context),
          ],
        ),
      ),
    );
  }
}

class _TravelOptionTile extends StatelessWidget {
  const _TravelOptionTile({
    required this.option,
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.enabled,
    required this.onSelected,
  });

  final TravelComfortOption option;
  final String label;
  final String hint;
  final bool isSelected;
  final bool enabled;
  final ValueChanged<TravelComfortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? AppColors.primaryStrong
        : AppColors.surfaceBlueStrong;
    final Color backgroundColor = isSelected
        ? AppColors.surfaceBlue
        : AppColors.surface;

    return Semantics(
      key: Key('question_three_option_${option.name}'),
      container: true,
      label: label,
      hint: hint,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      button: true,
      enabled: enabled,
      onTap: enabled ? () => onSelected(option) : null,
      child: ExcludeSemantics(
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: enabled ? () => onSelected(option) : null,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? AppColors.primaryStrong
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hint,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomUnitSelector extends StatelessWidget {
  const _CustomUnitSelector({
    required this.selectedUnit,
    required this.enabled,
    required this.onSelected,
  });

  final TravelCustomUnit? selectedUnit;
  final bool enabled;
  final ValueChanged<TravelCustomUnit> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stackButtons =
            constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(16) >= 25.6;
        final List<Widget> buttons = <Widget>[
          _CustomUnitButton(
            unit: TravelCustomUnit.minutes,
            label: 'Minutes',
            selected: selectedUnit == TravelCustomUnit.minutes,
            enabled: enabled,
            onSelected: onSelected,
          ),
          _CustomUnitButton(
            unit: TravelCustomUnit.miles,
            label: 'Miles',
            selected: selectedUnit == TravelCustomUnit.miles,
            enabled: enabled,
            onSelected: onSelected,
          ),
        ];

        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              buttons[0],
              const SizedBox(height: 8),
              buttons[1],
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: buttons[0]),
            const SizedBox(width: 10),
            Expanded(child: buttons[1]),
          ],
        );
      },
    );
  }
}

class _CustomUnitButton extends StatelessWidget {
  const _CustomUnitButton({
    required this.unit,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final TravelCustomUnit unit;
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<TravelCustomUnit> onSelected;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = OutlinedButton.styleFrom(
      minimumSize: const Size(48, 52),
      backgroundColor: selected ? AppColors.surfaceBlue : AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primaryStrong : AppColors.outline,
        width: selected ? 2 : 1,
      ),
      foregroundColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );

    return Semantics(
      key: Key('question_three_unit_${unit.name}'),
      container: true,
      label: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      enabled: enabled,
      onTap: enabled ? () => onSelected(unit) : null,
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: enabled ? () => onSelected(unit) : null,
          style: style,
          child: Text(label),
        ),
      ),
    );
  }
}

class _TravelOptionSpec {
  const _TravelOptionSpec({
    required this.option,
    required this.label,
    required this.hint,
  });

  final TravelComfortOption option;
  final String label;
  final String hint;
}

const List<_TravelOptionSpec> _travelOptions = <_TravelOptionSpec>[
  _TravelOptionSpec(
    option: TravelComfortOption.fewMinutes,
    label: 'A few minutes',
    hint: 'A short nearby trip.',
  ),
  _TravelOptionSpec(
    option: TravelComfortOption.quarterMile,
    label: 'About 1/4 mile',
    hint: 'Roughly a short neighborhood distance.',
  ),
  _TravelOptionSpec(
    option: TravelComfortOption.halfMile,
    label: 'About 1/2 mile',
    hint: 'A moderate nearby distance.',
  ),
  _TravelOptionSpec(
    option: TravelComfortOption.oneMile,
    label: 'About 1 mile',
    hint: 'A longer local trip.',
  ),
  _TravelOptionSpec(
    option: TravelComfortOption.moreThanOneMile,
    label: 'More than 1 mile',
    hint: 'A longer trip usually works.',
  ),
  _TravelOptionSpec(
    option: TravelComfortOption.depends,
    label: 'It depends',
    hint: 'Your comfort changes with the route, time, or conditions.',
  ),
  _TravelOptionSpec(
    option: TravelComfortOption.noDistanceRestriction,
    label: 'No distance restriction',
    hint: 'Distance is not a limit for this answer.',
  ),
  _TravelOptionSpec(
    option: TravelComfortOption.custom,
    label: 'Custom',
    hint: 'Enter your own time or distance.',
  ),
];
