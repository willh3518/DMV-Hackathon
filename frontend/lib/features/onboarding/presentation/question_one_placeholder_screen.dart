import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';

class QuestionOnePlaceholderScreen extends StatelessWidget {
  const QuestionOnePlaceholderScreen({
    required this.headingFocusNode,
    required this.onBack,
    required this.onSkip,
    this.enabled = true,
    super.key,
  });

  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionShell(
      questionNumber: 1,
      questionCount: 5,
      title: 'What accommodations help you?',
      explanation:
          'Choose everything that helps you feel comfortable. '
          'You can update this anytime.',
      headingFocusNode: headingFocusNode,
      enabled: enabled,
      continueEnabled: false,
      onBack: onBack,
      onSkip: onSkip,
      onContinue: () {},
      child: SectionSurface(
        child: Column(
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 30,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your choices come next',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'The next build will add choices such as step-free access, '
              'quieter spaces, and staff assistance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
