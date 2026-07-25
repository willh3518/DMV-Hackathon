import 'dart:ui' show Tristate;

import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_five_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionFiveScreen', () {
    testWidgets('uses function-first copy and renders every situation', (
      WidgetTester tester,
    ) async {
      final _HarnessController controller = _HarnessController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_testApp(controller));

      expect(
        find.text('Are there situations we should avoid or plan around?'),
        findsOneWidget,
      );
      expect(find.textContaining('not diagnoses'), findsOneWidget);
      expect(find.textContaining('selections are not ranked'), findsOneWidget);
      expect(find.byType(MultiSelectOptionTile), findsNWidgets(11));
      for (final PlanningSituation situation in PlanningSituation.values) {
        expect(
          find.byKey(QuestionFiveScreen.situationKey(situation)),
          findsOneWidget,
        );
      }
      expect(find.byKey(QuestionFiveScreen.otherFieldKey), findsOneWidget);
      expect(find.byKey(QuestionFiveScreen.noneKey), findsOneWidget);
      expect(
        tester
            .widget<MultiSelectOptionTile>(
              find.byKey(QuestionFiveScreen.noneKey),
            )
            .description,
        isNull,
      );
      expect(
        find.text('None of these situations affect the places I choose.'),
        findsNothing,
      );
      expect(find.text('Prefer not to say'), findsNothing);
      expect(
        find.byKey(const Key('question_five_prefer_not_to_say')),
        findsNothing,
      );

      final Finder orderedAnswers = find.descendant(
        of: find.byKey(OnboardingQuestionShell.contentKey),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is MultiSelectOptionTile ||
              widget.key == QuestionFiveScreen.otherFieldKey,
        ),
      );
      expect(
        orderedAnswers.evaluate().map((Element element) => element.widget.key),
        <Key>[
          for (final PlanningSituation situation in PlanningSituation.values)
            QuestionFiveScreen.situationKey(situation),
          QuestionFiveScreen.noneKey,
          QuestionFiveScreen.otherFieldKey,
        ],
      );
    });

    testWidgets('None and situation answers clear each other', (
      WidgetTester tester,
    ) async {
      final _HarnessController controller = _HarnessController(
        initialDraft: const PlanningSituationsDraft(
          situations: <PlanningSituation>{PlanningSituation.stairs},
          other: 'Steep ramps',
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_testApp(controller));

      await _tapOption(tester, QuestionFiveScreen.noneKey);

      expect(controller.draft.value.noneApply, isTrue);
      expect(controller.draft.value.skipped, isFalse);
      expect(controller.draft.value.situations, isEmpty);
      expect(controller.draft.value.other, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(QuestionFiveScreen.otherFieldKey))
            .controller
            ?.text,
        isEmpty,
      );

      await _tapOption(
        tester,
        QuestionFiveScreen.situationKey(PlanningSituation.largeCrowds),
      );

      expect(controller.draft.value.noneApply, isFalse);
      expect(controller.draft.value.skipped, isFalse);
      expect(controller.draft.value.situations, <PlanningSituation>{
        PlanningSituation.largeCrowds,
      });
    });

    testWidgets('custom text clears None and preserves situation choices', (
      WidgetTester tester,
    ) async {
      final _HarnessController controller = _HarnessController(
        initialDraft: const PlanningSituationsDraft.none(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_testApp(controller));

      final Finder otherField = find.byKey(QuestionFiveScreen.otherFieldKey);
      await tester.ensureVisible(otherField);
      await tester.enterText(otherField, 'Long waits without seating');
      await tester.pump();

      expect(controller.draft.value.other, 'Long waits without seating');
      expect(controller.draft.value.skipped, isFalse);
      expect(controller.draft.value.noneApply, isFalse);

      await _tapOption(
        tester,
        QuestionFiveScreen.situationKey(
          PlanningSituation.longPeriodsOfStanding,
        ),
      );

      expect(controller.draft.value.other, 'Long waits without seating');
      expect(controller.draft.value.situations, <PlanningSituation>{
        PlanningSituation.longPeriodsOfStanding,
      });
    });

    testWidgets('keeps None and Skip as distinct states', (
      WidgetTester tester,
    ) async {
      final _HarnessController controller = _HarnessController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_testApp(controller));

      await _tapOption(tester, QuestionFiveScreen.noneKey);
      expect(controller.draft.value.noneApply, isTrue);
      expect(controller.draft.value.skipped, isFalse);

      controller.events.clear();
      await _tapOption(tester, OnboardingQuestionShell.skipButtonKey);

      expect(controller.draft.value.noneApply, isFalse);
      expect(controller.draft.value.skipped, isTrue);
      expect(controller.draft.value.hasAnswer, isFalse);
      expect(controller.skipCount, 1);
      expect(controller.events, <String>['changed', 'skip']);
    });

    testWidgets('exposes selected semantics and a labeled custom field', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _HarnessController controller = _HarnessController(
        initialDraft: const PlanningSituationsDraft(
          situations: <PlanningSituation>{PlanningSituation.loudEnvironments},
        ),
      );
      addTearDown(controller.dispose);

      try {
        await tester.pumpWidget(_testApp(controller));

        final SemanticsData selectedData = tester
            .getSemantics(find.bySemanticsLabel('Loud environments'))
            .getSemanticsData();
        expect(selectedData.flagsCollection.isButton, isTrue);
        expect(selectedData.flagsCollection.isSelected, Tristate.isTrue);
        expect(selectedData.hasAction(SemanticsAction.tap), isTrue);
        expect(find.bySemanticsLabel('None'), findsOneWidget);

        final Finder otherField = find.byKey(QuestionFiveScreen.otherFieldKey);
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

      final Finder otherField = find.byKey(QuestionFiveScreen.otherFieldKey);
      await tester.ensureVisible(otherField);
      await tester.pump();

      final Finder continueButton = find.byKey(
        OnboardingQuestionShell.continueButtonKey,
      );
      await tester.ensureVisible(continueButton);
      await tester.pump();

      expect(find.byKey(OnboardingQuestionShell.scrollViewKey), findsOneWidget);
      expect(find.byKey(QuestionFiveScreen.noneKey), findsOneWidget);
      expect(otherField, findsOneWidget);
      expect(find.text('Prefer not to say'), findsNothing);
      expect(continueButton, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _tapOption(WidgetTester tester, Key key) async {
  final Finder option = find.byKey(key);
  await tester.ensureVisible(option);
  await tester.pump();
  await tester.tap(option);
  await tester.pump();
}

Widget _testApp(_HarnessController controller, {bool enabled = true}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: ValueListenableBuilder<PlanningSituationsDraft>(
        valueListenable: controller.draft,
        builder:
            (
              BuildContext context,
              PlanningSituationsDraft draft,
              Widget? child,
            ) {
              return QuestionFiveScreen(
                draft: draft,
                onChanged: (PlanningSituationsDraft value) {
                  controller.events.add('changed');
                  controller.changes.add(value);
                  controller.draft.value = value;
                },
                headingFocusNode: controller.headingFocusNode,
                onBack: () => controller.backCount += 1,
                onSkip: () {
                  controller.events.add('skip');
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
  _HarnessController({
    PlanningSituationsDraft initialDraft = const PlanningSituationsDraft(),
  }) : draft = ValueNotifier<PlanningSituationsDraft>(initialDraft);

  final ValueNotifier<PlanningSituationsDraft> draft;
  final FocusNode headingFocusNode = FocusNode(
    debugLabel: 'Question 5 heading',
  );
  final List<PlanningSituationsDraft> changes = <PlanningSituationsDraft>[];
  final List<String> events = <String>[];
  int backCount = 0;
  int skipCount = 0;
  int continueCount = 0;

  void dispose() {
    draft.dispose();
    headingFocusNode.dispose();
  }
}
