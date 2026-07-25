import 'dart:ui' show Tristate;

import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_four_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'restaurant and activity selections update without auto-advancing',
    (WidgetTester tester) async {
      final _HarnessController controller = _HarnessController(
        initialDraft: const InterestsDraft.skipped(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_testApp(controller));

      expect(
        find.byType(MultiSelectOptionTile),
        findsNWidgets(InterestOption.values.length),
      );
      for (final InterestOption option in InterestOption.values) {
        expect(
          find.byKey(QuestionFourScreen.optionKey(option)),
          findsOneWidget,
        );
      }

      await _tapOption(tester, InterestOption.restaurantsAndCafes);
      await _tapOption(tester, InterestOption.museums);

      expect(controller.draft.value.skipped, isFalse);
      expect(controller.draft.value.options, <InterestOption>{
        InterestOption.restaurantsAndCafes,
        InterestOption.museums,
      });
      expect(controller.continueCount, 0);

      final Finder continueButton = find.byKey(
        OnboardingQuestionShell.continueButtonKey,
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(controller.continueCount, 1);
    },
  );

  testWidgets('custom interest text clears skipped without navigating', (
    WidgetTester tester,
  ) async {
    final _HarnessController controller = _HarnessController(
      initialDraft: const InterestsDraft.skipped(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    final Finder otherField = find.byKey(QuestionFourScreen.otherFieldKey);
    await tester.ensureVisible(otherField);
    await tester.enterText(otherField, 'Accessible pottery workshops');
    await tester.pump();

    expect(controller.draft.value.other, 'Accessible pottery workshops');
    expect(controller.draft.value.skipped, isFalse);
    expect(controller.draft.value.hasAnswer, isTrue);
    expect(controller.continueCount, 0);
    expect(
      find.text('Share only interests you want used for recommendations.'),
      findsOneWidget,
    );
  });

  testWidgets('Skip emits a distinct skipped draft before its callback', (
    WidgetTester tester,
  ) async {
    final _HarnessController controller = _HarnessController(
      initialDraft: const InterestsDraft(
        options: <InterestOption>{InterestOption.parksAndNature},
        other: 'Invented community event',
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));

    final Finder skipButton = find.byKey(OnboardingQuestionShell.skipButtonKey);
    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pump();

    expect(controller.skipCount, 1);
    expect(controller.draftAtSkip?.skipped, isTrue);
    expect(controller.draft.value.skipped, isTrue);
    expect(controller.draft.value.hasAnswer, isFalse);
    expect(controller.draft.value.options, isEmpty);
    expect(controller.draft.value.other, isEmpty);
    expect(controller.continueCount, 0);
  });

  testWidgets('exposes headed interest groups and selected option semantics', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _HarnessController controller = _HarnessController(
      initialDraft: const InterestsDraft(
        options: <InterestOption>{InterestOption.restaurantsAndCafes},
      ),
    );
    addTearDown(controller.dispose);

    try {
      await tester.pumpWidget(_testApp(controller));

      expect(find.text('Food and drink'), findsOneWidget);
      expect(find.text('Activities and outings'), findsOneWidget);

      for (final Key headingKey in <Key>[
        QuestionFourScreen.interestsHeadingKey,
        QuestionFourScreen.foodAndDrinkHeadingKey,
        QuestionFourScreen.activitiesHeadingKey,
      ]) {
        final SemanticsData heading = tester
            .getSemantics(find.byKey(headingKey))
            .getSemanticsData();
        expect(heading.flagsCollection.isHeader, isTrue);
      }

      final Finder foodAndDrinkSection = find.byKey(
        QuestionFourScreen.foodAndDrinkSectionKey,
      );
      final Finder activitiesSection = find.byKey(
        QuestionFourScreen.activitiesSectionKey,
      );
      expect(
        find.descendant(
          of: foodAndDrinkSection,
          matching: find.byKey(
            QuestionFourScreen.optionKey(InterestOption.restaurantsAndCafes),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: foodAndDrinkSection,
          matching: find.byKey(
            QuestionFourScreen.optionKey(InterestOption.museums),
          ),
        ),
        findsNothing,
      );
      for (final InterestOption option in InterestOption.values.skip(1)) {
        expect(
          find.descendant(
            of: activitiesSection,
            matching: find.byKey(QuestionFourScreen.optionKey(option)),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: activitiesSection,
          matching: find.byKey(
            QuestionFourScreen.optionKey(InterestOption.restaurantsAndCafes),
          ),
        ),
        findsNothing,
      );

      final SemanticsData selected = tester
          .getSemantics(
            find.byKey(
              QuestionFourScreen.optionKey(InterestOption.restaurantsAndCafes),
            ),
          )
          .getSemanticsData();
      expect(selected.flagsCollection.isButton, isTrue);
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      expect(selected.hasAction(SemanticsAction.tap), isTrue);

      final Finder otherField = find.byKey(QuestionFourScreen.otherFieldKey);
      await tester.ensureVisible(otherField);
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('Something else.*optional')),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
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

    final Finder otherField = find.byKey(QuestionFourScreen.otherFieldKey);
    await tester.ensureVisible(otherField);
    await tester.pump();
    final Finder continueButton = find.byKey(
      OnboardingQuestionShell.continueButtonKey,
    );
    await tester.ensureVisible(continueButton);
    await tester.pump();

    expect(find.byKey(QuestionFourScreen.interestsHeadingKey), findsOneWidget);
    expect(otherField, findsOneWidget);
    expect(continueButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapOption(WidgetTester tester, InterestOption option) async {
  final Finder finder = find.byKey(QuestionFourScreen.optionKey(option));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Widget _testApp(_HarnessController controller, {bool enabled = true}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: ValueListenableBuilder<InterestsDraft>(
        valueListenable: controller.draft,
        builder: (BuildContext context, InterestsDraft draft, Widget? child) {
          return QuestionFourScreen(
            draft: draft,
            onChanged: (InterestsDraft value) {
              controller.changes.add(value);
              controller.draft.value = value;
            },
            headingFocusNode: controller.headingFocusNode,
            onBack: () => controller.backCount += 1,
            onSkip: () {
              controller.draftAtSkip = controller.draft.value;
              controller.skipCount += 1;
            },
            onContinue: () => controller.continueCount += 1,
            enabled: enabled,
          );
        },
      ),
    ),
  );
}

class _HarnessController {
  _HarnessController({InterestsDraft initialDraft = const InterestsDraft()})
    : draft = ValueNotifier<InterestsDraft>(initialDraft);

  final ValueNotifier<InterestsDraft> draft;
  final FocusNode headingFocusNode = FocusNode(
    debugLabel: 'Question 4 heading',
  );
  final List<InterestsDraft> changes = <InterestsDraft>[];
  InterestsDraft? draftAtSkip;
  int backCount = 0;
  int skipCount = 0;
  int continueCount = 0;

  void dispose() {
    draft.dispose();
    headingFocusNode.dispose();
  }
}
