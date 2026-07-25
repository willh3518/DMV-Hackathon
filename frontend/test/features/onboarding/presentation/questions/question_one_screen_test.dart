import 'dart:ui' show Tristate;

import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_one_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionOneScreen', () {
    testWidgets(
      'selection updates the controlled draft without auto-advancing',
      (WidgetTester tester) async {
        final GlobalKey<_QuestionOneHarnessState> key =
            GlobalKey<_QuestionOneHarnessState>();
        await tester.pumpWidget(
          _testApp(
            child: _QuestionOneHarness(
              key: key,
              initialDraft: const AccommodationsDraft.skipped(),
            ),
          ),
        );

        expect(find.byType(MultiSelectOptionTile), findsNWidgets(10));
        for (final AccommodationOption option in AccommodationOption.values) {
          expect(
            find.byKey(QuestionOneScreen.optionKey(option)),
            findsOneWidget,
          );
        }

        final Finder stepFree = find.byKey(
          QuestionOneScreen.optionKey(AccommodationOption.stepFreeAccess),
        );
        await tester.tap(stepFree);
        await tester.pump();

        expect(
          key.currentState?.draft.options,
          contains(AccommodationOption.stepFreeAccess),
        );
        expect(key.currentState?.draft.skipped, isFalse);
        expect(key.currentState?.continueCount, 0);

        final Finder continueButton = find.byKey(
          OnboardingQuestionShell.continueButtonKey,
        );
        await tester.ensureVisible(continueButton);
        await tester.pump();
        await tester.tap(continueButton);

        expect(key.currentState?.continueCount, 1);
      },
    );

    testWidgets('Prefer not to say clears and stays exclusive from answers', (
      WidgetTester tester,
    ) async {
      final GlobalKey<_QuestionOneHarnessState> key =
          GlobalKey<_QuestionOneHarnessState>();
      await tester.pumpWidget(
        _testApp(
          child: _QuestionOneHarness(
            key: key,
            initialDraft: const AccommodationsDraft(
              options: <AccommodationOption>{
                AccommodationOption.accessibleParking,
              },
              other: 'A place to rest near the entrance',
            ),
          ),
        ),
      );

      expect(
        find.text('Record that you prefer not to share accommodation details.'),
        findsOneWidget,
      );
      expect(find.text('Skip sharing accommodation details.'), findsNothing);

      final Finder preferNotToSay = find.byKey(
        QuestionOneScreen.preferNotToSayKey,
      );
      await tester.ensureVisible(preferNotToSay);
      await tester.pump();
      await tester.tap(preferNotToSay);
      await tester.pump();

      expect(key.currentState?.draft.preferNotToSay, isTrue);
      expect(key.currentState?.draft.options, isEmpty);
      expect(key.currentState?.draft.other, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(QuestionOneScreen.otherFieldKey))
            .controller
            ?.text,
        isEmpty,
      );

      final Finder parking = find.byKey(
        QuestionOneScreen.optionKey(AccommodationOption.accessibleParking),
      );
      await tester.ensureVisible(parking);
      await tester.pump();
      await tester.tap(parking);
      await tester.pump();

      expect(key.currentState?.draft.preferNotToSay, isFalse);
      expect(
        key.currentState?.draft.options,
        contains(AccommodationOption.accessibleParking),
      );
    });

    testWidgets('custom text and Skip produce distinct controlled states', (
      WidgetTester tester,
    ) async {
      final GlobalKey<_QuestionOneHarnessState> key =
          GlobalKey<_QuestionOneHarnessState>();
      await tester.pumpWidget(
        _testApp(
          child: _QuestionOneHarness(
            key: key,
            initialDraft: const AccommodationsDraft.skipped(),
          ),
        ),
      );

      final Finder otherField = find.byKey(QuestionOneScreen.otherFieldKey);
      await tester.ensureVisible(otherField);
      await tester.enterText(otherField, 'Space for a mobility device');
      await tester.pump();

      expect(key.currentState?.draft.other, 'Space for a mobility device');
      expect(key.currentState?.draft.skipped, isFalse);
      expect(key.currentState?.draft.preferNotToSay, isFalse);

      final Finder skipButton = find.byKey(
        OnboardingQuestionShell.skipButtonKey,
      );
      await tester.ensureVisible(skipButton);
      await tester.pump();
      await tester.tap(skipButton);
      await tester.pump();

      expect(key.currentState?.draft.skipped, isTrue);
      expect(key.currentState?.draft.hasAnswer, isFalse);
      expect(key.currentState?.skipCount, 1);
    });

    testWidgets('exposes selected semantics and a labeled custom field', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _testApp(
            child: const _QuestionOneHarness(
              initialDraft: AccommodationsDraft(
                options: <AccommodationOption>{
                  AccommodationOption.stepFreeAccess,
                },
              ),
            ),
          ),
        );

        final SemanticsData selectedData = tester
            .getSemantics(find.bySemanticsLabel('Step-free access'))
            .getSemanticsData();
        expect(selectedData.flagsCollection.isButton, isTrue);
        expect(selectedData.flagsCollection.isSelected, Tristate.isTrue);
        expect(selectedData.hasAction(SemanticsAction.tap), isTrue);

        final Finder otherField = find.byKey(QuestionOneScreen.otherFieldKey);
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
      await tester.pumpWidget(_testApp(child: const _QuestionOneHarness()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('remains scrollable at 3.2x text on a 320x568 screen', (
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

      await tester.pumpWidget(_testApp(child: const _QuestionOneHarness()));

      final Finder preferNotToSay = find.byKey(
        QuestionOneScreen.preferNotToSayKey,
      );
      await tester.ensureVisible(preferNotToSay);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(OnboardingQuestionShell.continueButtonKey),
      );
      await tester.pump();

      expect(find.byKey(OnboardingQuestionShell.scrollViewKey), findsOneWidget);
      expect(preferNotToSay, findsOneWidget);
      expect(
        find.byKey(OnboardingQuestionShell.continueButtonKey),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _testApp({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

class _QuestionOneHarness extends StatefulWidget {
  const _QuestionOneHarness({
    this.initialDraft = const AccommodationsDraft(),
    super.key,
  });

  final AccommodationsDraft initialDraft;

  @override
  State<_QuestionOneHarness> createState() => _QuestionOneHarnessState();
}

class _QuestionOneHarnessState extends State<_QuestionOneHarness> {
  late AccommodationsDraft draft;
  late final FocusNode headingFocusNode;
  int continueCount = 0;
  int skipCount = 0;

  @override
  void initState() {
    super.initState();
    draft = widget.initialDraft;
    headingFocusNode = FocusNode(debugLabel: 'Question 1 test heading');
  }

  @override
  void dispose() {
    headingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuestionOneScreen(
      draft: draft,
      onChanged: (AccommodationsDraft nextDraft) {
        setState(() => draft = nextDraft);
      },
      headingFocusNode: headingFocusNode,
      onBack: () {},
      onSkip: () => skipCount += 1,
      onContinue: () => continueCount += 1,
    );
  }
}
