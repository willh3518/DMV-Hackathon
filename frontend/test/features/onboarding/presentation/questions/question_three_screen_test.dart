import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_three_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Question 3 wording with walking rolling and transit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness());

    expect(
      find.text(
        'How far are you comfortable traveling without a private vehicle?',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('walking, rolling, or using transit'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not assume anything about your mobility'),
      findsOneWidget,
    );
    expect(find.text('Question 3 of 5'), findsOneWidget);
  });

  testWidgets(
    'single selection updates the controlled draft and selected semantics',
    (WidgetTester tester) async {
      TravelComfortDraft? lastChanged;
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildHarness(
            initialDraft: const TravelComfortDraft.skipped(),
            onChanged: (TravelComfortDraft draft) => lastChanged = draft,
          ),
        );

        await _tapAndSettle(tester, find.text('About 1/2 mile'));

        expect(lastChanged?.option, TravelComfortOption.halfMile);
        expect(lastChanged?.customValue, isEmpty);
        expect(lastChanged?.customUnit, isNull);
        expect(lastChanged?.skipped, isFalse);

        expect(
          tester.getSemantics(
            find.byKey(const Key('question_three_option_halfMile')),
          ),
          matchesSemantics(
            label: 'About 1/2 mile',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true,
            isInMutuallyExclusiveGroup: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'custom answer requires a positive value and unit before Continue',
    (WidgetTester tester) async {
      int continueCount = 0;
      TravelComfortDraft? lastChanged;

      await tester.pumpWidget(
        _buildHarness(
          onChanged: (TravelComfortDraft draft) => lastChanged = draft,
          onContinue: () => continueCount += 1,
        ),
      );

      await _tapAndSettle(tester, find.text('Custom'));

      expect(lastChanged?.option, TravelComfortOption.custom);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(OnboardingQuestionShell.continueButtonKey),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('question_three_custom_value_field')),
        '0',
      );
      await tester.pump();
      final Finder minutesButton = find.widgetWithText(
        OutlinedButton,
        'Minutes',
      );
      await tester.ensureVisible(minutesButton);
      await tester.pump();
      tester.widget<OutlinedButton>(minutesButton).onPressed?.call();
      await tester.pump();

      expect(lastChanged?.customValue, '0');
      expect(lastChanged?.customUnit, TravelCustomUnit.minutes);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(OnboardingQuestionShell.continueButtonKey),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('question_three_custom_value_field')),
        '12',
      );
      await tester.pump();

      expect(lastChanged?.customValue, '12');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(OnboardingQuestionShell.continueButtonKey),
            )
            .onPressed,
        isNotNull,
      );

      await _tapAndSettle(
        tester,
        find.byKey(OnboardingQuestionShell.continueButtonKey),
      );
      expect(continueCount, 1);
    },
  );

  testWidgets(
    'invalid custom draft values stay blocked by the shared domain predicate',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildHarness(
          initialDraft: const TravelComfortDraft(
            option: TravelComfortOption.custom,
            customValue: 'Infinity',
            customUnit: TravelCustomUnit.minutes,
          ),
        ),
      );

      expect(
        tester
            .widget<FilledButton>(
              find.byKey(OnboardingQuestionShell.continueButtonKey),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.text('Choose a positive finite value and one unit to continue.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'custom units update the draft and preserve explicit custom mode',
    (WidgetTester tester) async {
      TravelComfortDraft? lastChanged;

      await tester.pumpWidget(
        _buildHarness(
          initialDraft: const TravelComfortDraft(
            option: TravelComfortOption.custom,
            customValue: '8',
          ),
          onChanged: (TravelComfortDraft draft) => lastChanged = draft,
        ),
      );

      final Finder milesButton = find.widgetWithText(OutlinedButton, 'Miles');
      await tester.ensureVisible(milesButton);
      await tester.pump();
      tester.widget<OutlinedButton>(milesButton).onPressed?.call();
      await tester.pump();

      expect(lastChanged?.option, TravelComfortOption.custom);
      expect(lastChanged?.customValue, '8');
      expect(lastChanged?.customUnit, TravelCustomUnit.miles);
    },
  );

  testWidgets('unselected custom unit uses the stronger neutral outline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        initialDraft: const TravelComfortDraft(
          option: TravelComfortOption.custom,
        ),
      ),
    );

    final OutlinedButton minutesButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('question_three_unit_minutes')),
        matching: find.byType(OutlinedButton),
      ),
    );
    final BorderSide? side = minutesButton.style?.side?.resolve(
      <WidgetState>{},
    );

    expect(side?.color, AppColors.outline);
    expect(side?.width, 1);
  });

  testWidgets('Skip emits a distinct skipped draft and fires once', (
    WidgetTester tester,
  ) async {
    int skipCount = 0;
    final List<TravelComfortDraft> changedDrafts = <TravelComfortDraft>[];

    await tester.pumpWidget(
      _buildHarness(
        initialDraft: const TravelComfortDraft(
          option: TravelComfortOption.oneMile,
        ),
        onChanged: changedDrafts.add,
        onSkip: () => skipCount += 1,
      ),
    );

    await _tapAndSettle(
      tester,
      find.byKey(OnboardingQuestionShell.skipButtonKey),
    );

    expect(skipCount, 1);
    expect(changedDrafts, hasLength(1));
    expect(changedDrafts.single.option, isNull);
    expect(changedDrafts.single.customValue, isEmpty);
    expect(changedDrafts.single.customUnit, isNull);
    expect(changedDrafts.single.skipped, isTrue);
    expect(changedDrafts.single.hasAnswer, isFalse);
  });

  testWidgets('meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('supports 3.2x text on a 320x568 screen', (
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

    await tester.pumpWidget(_buildHarness());
    await _tapAndSettle(tester, find.text('Custom'));
    await tester.ensureVisible(
      find.byKey(OnboardingQuestionShell.continueButtonKey),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('question_three_unit_miles')),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('question_three_custom_value_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('question_three_unit_minutes')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('question_three_unit_miles')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion reveals custom controls without running animations',
    (WidgetTester tester) async {
      final MediaQueryData mediaQuery = MediaQueryData.fromView(
        tester.view,
      ).copyWith(disableAnimations: true);

      await tester.pumpWidget(_buildHarness(mediaQuery: mediaQuery));

      expect(find.byType(AnimatedSize), findsNothing);
      await _tapAndSettle(tester, find.text('Custom'));

      expect(
        find.byKey(const Key('question_three_custom_section')),
        findsOneWidget,
      );
      expect(find.byType(AnimatedSize), findsNothing);
    },
  );
}

Widget _buildHarness({
  TravelComfortDraft initialDraft = const TravelComfortDraft(),
  ValueChanged<TravelComfortDraft>? onChanged,
  VoidCallback? onContinue,
  VoidCallback? onSkip,
  MediaQueryData? mediaQuery,
}) {
  final Widget child = _QuestionThreeHarness(
    initialDraft: initialDraft,
    onChanged: onChanged,
    onContinue: onContinue,
    onSkip: onSkip,
  );

  return MaterialApp(
    theme: AppTheme.light,
    home: mediaQuery == null
        ? Scaffold(
            body: Stack(children: <Widget>[const BubbleBackdrop(), child]),
          )
        : MediaQuery(
            data: mediaQuery,
            child: Scaffold(
              body: Stack(children: <Widget>[const BubbleBackdrop(), child]),
            ),
          ),
  );
}

class _QuestionThreeHarness extends StatefulWidget {
  const _QuestionThreeHarness({
    required this.initialDraft,
    this.onChanged,
    this.onContinue,
    this.onSkip,
  });

  final TravelComfortDraft initialDraft;
  final ValueChanged<TravelComfortDraft>? onChanged;
  final VoidCallback? onContinue;
  final VoidCallback? onSkip;

  @override
  State<_QuestionThreeHarness> createState() => _QuestionThreeHarnessState();
}

class _QuestionThreeHarnessState extends State<_QuestionThreeHarness> {
  late TravelComfortDraft _draft;
  late final FocusNode _headingFocusNode;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _headingFocusNode = FocusNode(debugLabel: 'Question 3 heading');
  }

  @override
  void dispose() {
    _headingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuestionThreeScreen(
      draft: _draft,
      headingFocusNode: _headingFocusNode,
      enabled: true,
      onChanged: (TravelComfortDraft draft) {
        setState(() => _draft = draft);
        widget.onChanged?.call(draft);
      },
      onBack: () {},
      onSkip: widget.onSkip ?? () {},
      onContinue: widget.onContinue ?? () {},
    );
  }
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}
