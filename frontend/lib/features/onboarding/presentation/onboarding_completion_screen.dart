import 'dart:math' as math;

import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_completion_models.dart';
import 'package:flutter/material.dart';

enum OnboardingCompletionStage { ready, submitting, failure, confirmed }

class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({
    required this.stage,
    required this.headingFocusNode,
    required this.onBack,
    required this.onSubmit,
    required this.onRetry,
    required this.onContinue,
    this.failureReason,
    super.key,
  });

  static const Key scrollViewKey = Key('onboarding_completion_scroll_view');
  static const Key backButtonKey = Key('onboarding_completion_back_button');
  static const Key headingFocusKey = Key('onboarding_completion_heading_focus');
  static const Key statusKey = Key('onboarding_completion_status');
  static const Key errorStatusKey = Key('onboarding_completion_error_status');
  static const Key primaryButtonKey = Key(
    'onboarding_completion_primary_button',
  );

  final OnboardingCompletionStage stage;
  final OnboardingCompletionFailureReason? failureReason;
  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState
    extends State<OnboardingCompletionScreen> {
  bool _actionLocked = false;

  @override
  void didUpdateWidget(OnboardingCompletionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage ||
        oldWidget.failureReason != widget.failureReason) {
      _actionLocked = false;
    }
  }

  bool get _backEnabled =>
      !_actionLocked && widget.stage != OnboardingCompletionStage.submitting;

  VoidCallback? get _primaryAction {
    if (widget.stage == OnboardingCompletionStage.confirmed) {
      return widget.onContinue;
    }

    if (_actionLocked || widget.stage == OnboardingCompletionStage.submitting) {
      return null;
    }

    return switch (widget.stage) {
      OnboardingCompletionStage.ready => () => _handlePrimary(widget.onSubmit),
      OnboardingCompletionStage.failure => () => _handlePrimary(widget.onRetry),
      OnboardingCompletionStage.confirmed => widget.onContinue,
      OnboardingCompletionStage.submitting => null,
    };
  }

  String get _primaryLabel {
    return switch (widget.stage) {
      OnboardingCompletionStage.ready => 'Submit question responses',
      OnboardingCompletionStage.submitting =>
        'Submitting your question responses',
      OnboardingCompletionStage.failure => 'Retry submission',
      OnboardingCompletionStage.confirmed => 'Done for now',
    };
  }

  void _handlePrimary(VoidCallback callback) {
    if (_actionLocked) {
      return;
    }

    setState(() => _actionLocked = true);
    callback();
  }

  void _handlePopInvoked(bool didPop, Object? result) {
    if (didPop || !_backEnabled) {
      return;
    }

    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final _CompletionContent content = _contentForStage(
      widget.stage,
      widget.failureReason,
    );
    final bool reduceMotion = AppMotion.prefersReducedMotion(context);
    final Duration buttonAnimationDuration = reduceMotion
        ? Duration.zero
        : AppMotion.feedback;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvoked,
      child: SafeArea(
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const EdgeInsets basePadding = EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24,
              );
              final TextScaler textScaler = MediaQuery.textScalerOf(context);
              final double minimumContentHeight = math.max(
                0,
                constraints.maxHeight - basePadding.vertical,
              );
              final bool compactBackButton =
                  constraints.maxWidth < 360 || textScaler.scale(16) >= 25.6;

              return SingleChildScrollView(
                key: OnboardingCompletionScreen.scrollViewKey,
                padding: basePadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minimumContentHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: compactBackButton
                            ? TextButton(
                                key: OnboardingCompletionScreen.backButtonKey,
                                style: ButtonStyle(
                                  animationDuration: buttonAnimationDuration,
                                ),
                                onPressed: _backEnabled ? widget.onBack : null,
                                child: const Text('Back'),
                              )
                            : TextButton.icon(
                                key: OnboardingCompletionScreen.backButtonKey,
                                style: ButtonStyle(
                                  animationDuration: buttonAnimationDuration,
                                ),
                                onPressed: _backEnabled ? widget.onBack : null,
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: const Text('Back'),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _CompletionBadge(
                        label: content.badgeLabel,
                        icon: content.badgeIcon,
                      ),
                      const SizedBox(height: 22),
                      Focus(
                        key: OnboardingCompletionScreen.headingFocusKey,
                        focusNode: widget.headingFocusNode,
                        skipTraversal: true,
                        child: Semantics(
                          header: true,
                          liveRegion: true,
                          child: Text(
                            content.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        content.explanation,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 26),
                      Semantics(
                        key: content.isError
                            ? OnboardingCompletionScreen.errorStatusKey
                            : OnboardingCompletionScreen.statusKey,
                        liveRegion: content.liveRegion,
                        label: content.semanticsLabel,
                        child: ExcludeSemantics(
                          child: SectionSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _CompletionStatusHeader(
                                  icon: content.statusIcon,
                                  iconColor: content.statusIconColor,
                                  iconBackground: content.statusIconBackground,
                                  title: content.statusTitle,
                                  subtitle: content.statusSubtitle,
                                  reduceMotion: reduceMotion,
                                  animate: content.animateStatus,
                                ),
                                const SizedBox(height: 18),
                                for (
                                  int index = 0;
                                  index < content.detailLines.length;
                                  index += 1
                                ) ...<Widget>[
                                  if (index > 0) const SizedBox(height: 10),
                                  _CompletionDetailLine(
                                    text: content.detailLines[index],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _CompletionActions(
                        primaryLabel: _primaryLabel,
                        primaryAction: _primaryAction,
                        animationDuration: buttonAnimationDuration,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompletionActions extends StatelessWidget {
  const _CompletionActions({
    required this.primaryLabel,
    required this.primaryAction,
    required this.animationDuration,
  });

  final String primaryLabel;
  final VoidCallback? primaryAction;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextScaler textScaler = MediaQuery.textScalerOf(context);
        final bool stackActions =
            constraints.maxWidth < 280 || textScaler.scale(16) >= 25.6;
        final Widget primaryButton = FilledButton(
          key: OnboardingCompletionScreen.primaryButtonKey,
          style: ButtonStyle(animationDuration: animationDuration),
          onPressed: primaryAction,
          child: Text(primaryLabel),
        );

        if (stackActions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[primaryButton],
          );
        }

        return Row(children: <Widget>[Expanded(child: primaryButton)]);
      },
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.surfaceBlueStrong),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: AppColors.primaryStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionStatusHeader extends StatefulWidget {
  const _CompletionStatusHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.reduceMotion,
    required this.animate,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool reduceMotion;
  final bool animate;

  @override
  State<_CompletionStatusHeader> createState() =>
      _CompletionStatusHeaderState();
}

class _CompletionStatusHeaderState extends State<_CompletionStatusHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_CompletionStatusHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion ||
        oldWidget.animate != widget.animate) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (!widget.animate || widget.reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.iconBackground,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Icon(widget.icon, color: widget.iconColor, size: 28),
      ),
    );
    final Widget animatedIcon = widget.reduceMotion || !widget.animate
        ? icon
        : AnimatedBuilder(
            animation: _controller,
            child: icon,
            builder: (BuildContext context, Widget? child) {
              final double scale = 1 + (_controller.value * 0.04);
              return Transform.scale(scale: scale, child: child);
            },
          );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextScaler textScaler = MediaQuery.textScalerOf(context);
        final bool stackHeader =
            constraints.maxWidth < 360 || textScaler.scale(16) >= 25.6;
        final Widget textContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );

        if (stackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              animatedIcon,
              const SizedBox(height: 14),
              textContent,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            animatedIcon,
            const SizedBox(width: 14),
            Expanded(child: textContent),
          ],
        );
      },
    );
  }
}

class _CompletionDetailLine extends StatelessWidget {
  const _CompletionDetailLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 8, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _CompletionContent {
  const _CompletionContent({
    required this.badgeLabel,
    required this.badgeIcon,
    required this.title,
    required this.explanation,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.statusIcon,
    required this.statusIconColor,
    required this.statusIconBackground,
    required this.detailLines,
    required this.semanticsLabel,
    this.liveRegion = false,
    this.animateStatus = false,
    this.isError = false,
  });

  final String badgeLabel;
  final IconData badgeIcon;
  final String title;
  final String explanation;
  final String statusTitle;
  final String statusSubtitle;
  final IconData statusIcon;
  final Color statusIconColor;
  final Color statusIconBackground;
  final List<String> detailLines;
  final String semanticsLabel;
  final bool liveRegion;
  final bool animateStatus;
  final bool isError;
}

_CompletionContent _contentForStage(
  OnboardingCompletionStage stage,
  OnboardingCompletionFailureReason? failureReason,
) {
  return switch (stage) {
    OnboardingCompletionStage.ready => const _CompletionContent(
      badgeLabel: 'Responses ready',
      badgeIcon: Icons.edit_note_rounded,
      title: 'Ready to submit your five question responses?',
      explanation:
          'Review what you shared, then submit when you are ready. You can still go back and change any of your five question responses before anything is submitted.',
      statusTitle: 'Submission is still your choice',
      statusSubtitle:
          'Nothing is submitted in this build until you press the button below.',
      statusIcon: Icons.lock_outline_rounded,
      statusIconColor: AppColors.primaryStrong,
      statusIconBackground: AppColors.surfaceBlue,
      detailLines: <String>[
        'All five onboarding responses remain editable before submission.',
        'Use Back if you want to revise any answer first.',
        'Submit is explicit so you can confirm the timing yourself.',
      ],
      semanticsLabel:
          'Ready to submit. Five question responses remain editable, and nothing is submitted until you press Submit question responses.',
    ),
    OnboardingCompletionStage.submitting => const _CompletionContent(
      badgeLabel: 'Submitting',
      badgeIcon: Icons.hourglass_top_rounded,
      title: 'Submitting your question responses',
      explanation:
          'Please wait while this build finishes the submission step. Back and repeated submission are disabled until this state changes.',
      statusTitle: 'Submission in progress',
      statusSubtitle:
          'We are working on your onboarding responses now. This status will update when the step finishes.',
      statusIcon: Icons.hourglass_top_rounded,
      statusIconColor: AppColors.primaryStrong,
      statusIconBackground: AppColors.surfaceBlue,
      detailLines: <String>[
        'Keep this screen open while the submission step finishes.',
        'You will get a confirmed or retry state here next.',
      ],
      semanticsLabel:
          'Submitting your question responses. Back and repeated submission are disabled until this state changes.',
      liveRegion: true,
      animateStatus: true,
    ),
    OnboardingCompletionStage.failure => _failureContent(failureReason),
    OnboardingCompletionStage.confirmed => const _CompletionContent(
      badgeLabel: 'Submission confirmed',
      badgeIcon: Icons.check_circle_rounded,
      title: 'Your profile setup is confirmed in this frontend build',
      explanation:
          'This build has confirmed the submission step for your onboarding responses. Discovery chat is still a later stage, so this screen stops at confirmation for now.',
      statusTitle: 'Confirmation is complete',
      statusSubtitle:
          'Your onboarding responses are confirmed here, and discovery chat will connect in a later stage.',
      statusIcon: Icons.check_circle_rounded,
      statusIconColor: AppColors.primaryStrong,
      statusIconBackground: AppColors.surfaceBlue,
      detailLines: <String>[
        'Your onboarding responses are confirmed in this frontend build.',
        'You can leave this step knowing the confirmation state is complete.',
      ],
      semanticsLabel:
          'Submission confirmed. Your profile setup is confirmed in this frontend build, and discovery chat will connect in a later stage.',
      liveRegion: true,
    ),
  };
}

_CompletionContent _failureContent(
  OnboardingCompletionFailureReason? failureReason,
) {
  final String reasonText = switch (failureReason) {
    OnboardingCompletionFailureReason.networkUnavailable =>
      'We could not connect right now. Check your connection and try again.',
    OnboardingCompletionFailureReason.serviceUnavailable =>
      'Submission is temporarily unavailable right now. Try again in a moment.',
    OnboardingCompletionFailureReason.unknown ||
    null => 'Something interrupted submission before it finished. Try again.',
  };

  return _CompletionContent(
    badgeLabel: 'Needs retry',
    badgeIcon: Icons.error_outline_rounded,
    title: 'We could not submit your responses',
    explanation:
        'Your onboarding responses are still visible in this build. You can retry now or go back to review them before trying again.',
    statusTitle: 'Retry is available',
    statusSubtitle: reasonText,
    statusIcon: Icons.error_outline_rounded,
    statusIconColor: const Color(0xFF8A4A17),
    statusIconBackground: const Color(0xFFFFF1E1),
    detailLines: const <String>[
      'No product name or technical system details are needed to recover here.',
      'Use Retry to attempt the submission again from this screen.',
    ],
    semanticsLabel: 'Submission failed. $reasonText Retry is available.',
    liveRegion: true,
    isError: true,
  );
}
