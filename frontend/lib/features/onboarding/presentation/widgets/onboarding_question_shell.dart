import 'dart:math' as math;

import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:flutter/material.dart';

/// Shared presentation frame for one onboarding question.
///
/// This widget intentionally owns no draft state, routing, transitions, or
/// question-specific choices. Integration should keep the shared bubble
/// backdrop outside this shell, disable the shell while a step transition is in
/// progress, and request [headingFocusNode] after the next step settles.
///
/// Forward transitions should fade/slide for about 300 milliseconds and Back
/// should reverse that direction. When animations are disabled, integration
/// should use a short settled crossfade without translation.
class OnboardingQuestionShell extends StatelessWidget {
  const OnboardingQuestionShell({
    required this.questionNumber,
    required this.questionCount,
    required this.title,
    required this.explanation,
    required this.child,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
    this.headingFocusNode,
    this.backFocusNode,
    this.skipFocusNode,
    this.continueFocusNode,
    this.enabled = true,
    this.continueEnabled = true,
    this.isLoading = false,
    this.loadingLabel = 'Saving your answer',
    this.continueLabel = 'Continue',
    super.key,
  }) : assert(questionCount > 0),
       assert(questionNumber > 0),
       assert(questionNumber <= questionCount);

  static const Key scrollViewKey = Key('onboarding_question_scroll_view');
  static const Key backButtonKey = Key('onboarding_question_back_button');
  static const Key progressKey = Key('onboarding_question_progress');
  static const Key headingFocusKey = Key('onboarding_question_heading_focus');
  static const Key contentKey = Key('onboarding_question_content');
  static const Key loadingStatusKey = Key('onboarding_question_loading_status');
  static const Key skipButtonKey = Key('onboarding_question_skip_button');
  static const Key continueButtonKey = Key(
    'onboarding_question_continue_button',
  );

  final int questionNumber;
  final int questionCount;
  final String title;
  final String explanation;
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final FocusNode? headingFocusNode;
  final FocusNode? backFocusNode;
  final FocusNode? skipFocusNode;
  final FocusNode? continueFocusNode;
  final bool enabled;
  final bool continueEnabled;
  final bool isLoading;
  final String loadingLabel;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final bool interactionsEnabled = enabled && !isLoading;
    final Duration buttonAnimationDuration =
        AppMotion.prefersReducedMotion(context)
        ? Duration.zero
        : AppMotion.feedback;
    final double progress = questionNumber / questionCount;
    final int progressPercent = (progress * 100).round();
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const EdgeInsets basePadding = EdgeInsets.fromLTRB(24, 12, 24, 24);
            final double minimumContentHeight = math.max(
              0,
              constraints.maxHeight - basePadding.vertical - keyboardInset,
            );

            return SingleChildScrollView(
              key: scrollViewKey,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: basePadding.copyWith(
                bottom: basePadding.bottom + keyboardInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minimumContentHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: backButtonKey,
                        focusNode: backFocusNode,
                        style: ButtonStyle(
                          animationDuration: buttonAnimationDuration,
                        ),
                        onPressed: interactionsEnabled ? onBack : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      key: progressKey,
                      label:
                          'Onboarding question $questionNumber of '
                          '$questionCount',
                      value: '$progressPercent percent complete',
                      child: ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: AppColors.surfaceBlueStrong,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryStrong,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Question $questionNumber of $questionCount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Focus(
                      key: headingFocusKey,
                      focusNode: headingFocusNode,
                      skipTraversal: true,
                      child: Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      explanation,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    ExcludeFocus(
                      excluding: !interactionsEnabled,
                      child: AbsorbPointer(
                        absorbing: !interactionsEnabled,
                        child: KeyedSubtree(key: contentKey, child: child),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (isLoading) ...<Widget>[
                      Semantics(
                        key: loadingStatusKey,
                        liveRegion: true,
                        label: loadingLabel,
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(
                                Icons.hourglass_top_rounded,
                                size: 22,
                                color: AppColors.primaryStrong,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  loadingLabel,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _QuestionActions(
                      skipFocusNode: skipFocusNode,
                      continueFocusNode: continueFocusNode,
                      interactionsEnabled: interactionsEnabled,
                      continueEnabled: interactionsEnabled && continueEnabled,
                      continueLabel: continueLabel,
                      onSkip: onSkip,
                      onContinue: onContinue,
                      animationDuration: buttonAnimationDuration,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestionActions extends StatelessWidget {
  const _QuestionActions({
    required this.interactionsEnabled,
    required this.continueEnabled,
    required this.continueLabel,
    required this.onSkip,
    required this.onContinue,
    required this.animationDuration,
    this.skipFocusNode,
    this.continueFocusNode,
  });

  final bool interactionsEnabled;
  final bool continueEnabled;
  final String continueLabel;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final Duration animationDuration;
  final FocusNode? skipFocusNode;
  final FocusNode? continueFocusNode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextScaler textScaler = MediaQuery.textScalerOf(context);
        final bool stackActions =
            constraints.maxWidth < 280 || textScaler.scale(16) >= 25.6;

        final Widget skipButton = TextButton(
          key: OnboardingQuestionShell.skipButtonKey,
          focusNode: skipFocusNode,
          style: ButtonStyle(animationDuration: animationDuration),
          onPressed: interactionsEnabled ? onSkip : null,
          child: const Text('Skip'),
        );
        final Widget continueButton = FilledButton(
          key: OnboardingQuestionShell.continueButtonKey,
          focusNode: continueFocusNode,
          style: ButtonStyle(animationDuration: animationDuration),
          onPressed: continueEnabled ? onContinue : null,
          child: Text(continueLabel),
        );

        if (stackActions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              skipButton,
              const SizedBox(height: 8),
              continueButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: skipButton),
            const SizedBox(width: 12),
            Expanded(child: continueButton),
          ],
        );
      },
    );
  }
}
