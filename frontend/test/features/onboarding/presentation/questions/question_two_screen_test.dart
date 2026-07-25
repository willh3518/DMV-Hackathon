import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_two_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('presents three semantic groups and honest dietary copy', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _HarnessController controller = _HarnessController();
    addTearDown(controller.dispose);

    try {
      await tester.pumpWidget(_testApp(controller));

      expect(find.text('Food and cuisines'), findsOneWidget);
      expect(find.text('Dietary requirements'), findsOneWidget);
      expect(
        find.text('Service, communication, and environment'),
        findsOneWidget,
      );

      for (final Key headingKey in <Key>[
        QuestionTwoScreen.foodHeadingKey,
        QuestionTwoScreen.dietaryHeadingKey,
        QuestionTwoScreen.experienceHeadingKey,
      ]) {
        final SemanticsData heading = tester
            .getSemantics(find.byKey(headingKey))
            .getSemanticsData();
        expect(heading.flagsCollection.isHeader, isTrue);
      }

      expect(
        find.textContaining(
          'We help surface these needs, but do not verify allergy safety.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('allergy-safe'), findsNothing);
      expect(find.textContaining('verified allergy-safe'), findsNothing);

      final FilledButton continueButton = tester.widget<FilledButton>(
        find.byKey(OnboardingQuestionShell.continueButtonKey),
      );
      expect(continueButton.onPressed, isNotNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('updates independent typed sets and clears skipped', (
    WidgetTester tester,
  ) async {
    final _HarnessController controller = _HarnessController(
      initialDraft: const ExperiencePreferencesDraft.skipped(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    await _tapOption(
      tester,
      QuestionTwoScreen.foodOptionKey(FoodPreference.italian),
    );
    expect(controller.draft.value.skipped, isFalse);
    expect(controller.draft.value.food, <FoodPreference>{
      FoodPreference.italian,
    });
    expect(controller.draft.value.dietaryRequirements, isEmpty);
    expect(controller.draft.value.experience, isEmpty);

    await _tapOption(
      tester,
      QuestionTwoScreen.dietaryOptionKey(DietaryRequirement.glutenFree),
    );
    await _tapOption(
      tester,
      QuestionTwoScreen.experienceOptionKey(
        ExperiencePreference.quieterEnvironment,
      ),
    );

    expect(controller.draft.value.food, <FoodPreference>{
      FoodPreference.italian,
    });
    expect(controller.draft.value.dietaryRequirements, <DietaryRequirement>{
      DietaryRequirement.glutenFree,
    });
    expect(controller.draft.value.experience, <ExperiencePreference>{
      ExperiencePreference.quieterEnvironment,
    });

    await _tapOption(
      tester,
      QuestionTwoScreen.foodOptionKey(FoodPreference.italian),
    );
    expect(controller.draft.value.food, isEmpty);
    expect(controller.draft.value.dietaryRequirements, <DietaryRequirement>{
      DietaryRequirement.glutenFree,
    });
    expect(controller.draft.value.experience, <ExperiencePreference>{
      ExperiencePreference.quieterEnvironment,
    });
  });

  testWidgets('custom dietary text stays a requirement and preserves choices', (
    WidgetTester tester,
  ) async {
    final _HarnessController controller = _HarnessController(
      initialDraft: const ExperiencePreferencesDraft(
        food: <FoodPreference>{FoodPreference.mexican},
        dietaryRequirements: <DietaryRequirement>{
          DietaryRequirement.vegetarian,
        },
        experience: <ExperiencePreference>{ExperiencePreference.patientStaff},
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    final Finder otherField = find.byKey(
      QuestionTwoScreen.otherDietaryFieldKey,
    );
    await tester.ensureVisible(otherField);
    await tester.enterText(otherField, 'No shellfish');
    await tester.pump();

    expect(controller.draft.value.otherDietaryRequirement, 'No shellfish');
    expect(controller.draft.value.food, <FoodPreference>{
      FoodPreference.mexican,
    });
    expect(controller.draft.value.dietaryRequirements, <DietaryRequirement>{
      DietaryRequirement.vegetarian,
    });
    expect(controller.draft.value.experience, <ExperiencePreference>{
      ExperiencePreference.patientStaff,
    });
    expect(controller.draft.value.skipped, isFalse);
    expect(
      find.text('Optional. Anything entered here remains a requirement.'),
      findsOneWidget,
    );
  });

  testWidgets('Skip records a distinct skipped draft before continuing', (
    WidgetTester tester,
  ) async {
    final _HarnessController controller = _HarnessController(
      initialDraft: const ExperiencePreferencesDraft(
        food: <FoodPreference>{FoodPreference.italian},
        otherDietaryRequirement: 'No peanuts',
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    final Finder skip = find.byKey(OnboardingQuestionShell.skipButtonKey);
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pump();

    expect(controller.skipCount, 1);
    expect(controller.draft.value.skipped, isTrue);
    expect(controller.draft.value.hasAnswer, isFalse);
    expect(controller.draft.value.food, isEmpty);
    expect(controller.draft.value.dietaryRequirements, isEmpty);
    expect(controller.draft.value.experience, isEmpty);
    expect(controller.draft.value.otherDietaryRequirement, isEmpty);
  });

  testWidgets('meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    final _HarnessController controller = _HarnessController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('remains usable at 3.2x text on a 320x568 screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final _HarnessController controller = _HarnessController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    final Finder continueButton = find.byKey(
      OnboardingQuestionShell.continueButtonKey,
    );
    await tester.ensureVisible(continueButton);
    await tester.pump();

    expect(find.byKey(QuestionTwoScreen.foodHeadingKey), findsOneWidget);
    expect(find.byKey(QuestionTwoScreen.dietaryHeadingKey), findsOneWidget);
    expect(find.byKey(QuestionTwoScreen.experienceHeadingKey), findsOneWidget);
    expect(continueButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapOption(WidgetTester tester, Key key) async {
  final Finder option = find.byKey(key);
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pump();
}

Widget _testApp(_HarnessController controller, {bool enabled = true}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: ValueListenableBuilder<ExperiencePreferencesDraft>(
        valueListenable: controller.draft,
        builder:
            (
              BuildContext context,
              ExperiencePreferencesDraft draft,
              Widget? child,
            ) {
              return QuestionTwoScreen(
                draft: draft,
                onChanged: (ExperiencePreferencesDraft value) {
                  controller.changes.add(value);
                  controller.draft.value = value;
                },
                headingFocusNode: controller.headingFocusNode,
                onBack: () => controller.backCount += 1,
                onSkip: () => controller.skipCount += 1,
                onContinue: () => controller.continueCount += 1,
                enabled: enabled,
              );
            },
      ),
    ),
  );
}

class _HarnessController {
  _HarnessController({
    ExperiencePreferencesDraft initialDraft =
        const ExperiencePreferencesDraft(),
  }) : draft = ValueNotifier<ExperiencePreferencesDraft>(initialDraft);

  final ValueNotifier<ExperiencePreferencesDraft> draft;
  final FocusNode headingFocusNode = FocusNode(
    debugLabel: 'Question 2 heading',
  );
  final List<ExperiencePreferencesDraft> changes =
      <ExperiencePreferencesDraft>[];
  int backCount = 0;
  int skipCount = 0;
  int continueCount = 0;

  void dispose() {
    draft.dispose();
    headingFocusNode.dispose();
  }
}
