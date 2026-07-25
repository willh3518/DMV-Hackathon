import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:flutter/material.dart';

class QuestionOnePlaceholderScreen extends StatelessWidget {
  const QuestionOnePlaceholderScreen({
    required this.headingFocusNode,
    required this.onBack,
    this.enabled = true,
    super.key,
  });

  final FocusNode headingFocusNode;
  final VoidCallback onBack;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 36,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('onboarding_back_button'),
                      onPressed: enabled ? onBack : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Onboarding question 1 of 5',
                    value: '20 percent complete',
                    child: ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const LinearProgressIndicator(
                          value: 0.2,
                          minHeight: 10,
                          backgroundColor: AppColors.surfaceBlueStrong,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryStrong,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Question 1 of 5',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Focus(
                    key: const Key('question_one_heading_focus'),
                    focusNode: headingFocusNode,
                    child: Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        'What accommodations help you?',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Choose everything that helps you feel comfortable. '
                    'You can update this anytime.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.surfaceBlueStrong),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
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
                          'The next build will add choices such as step-free '
                          'access, quieter spaces, and staff assistance.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
