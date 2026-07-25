import 'dart:ui' show Tristate;

import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/design_system/components/multi_select_option_tile.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/design_system/components/status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('multi-select exposes and updates selected semantics', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    bool selected = false;

    await tester.pumpWidget(
      _TestApp(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MultiSelectOptionTile(
              label: 'Quiet environment',
              description: 'Prefer spaces with lower background noise.',
              selected: selected,
              onChanged: (bool value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );

    final Finder tile = find.bySemanticsLabel(
      'Quiet environment. Prefer spaces with lower background noise.',
    );
    SemanticsNode node = tester.getSemantics(tile);
    SemanticsData data = node.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.flagsCollection.isSelected, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(selected, isTrue);
    node = tester.getSemantics(tile);
    data = node.getSemanticsData();
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('multi-select supports keyboard activation and visible focus', (
    WidgetTester tester,
  ) async {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    bool selected = false;

    await tester.pumpWidget(
      _TestApp(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MultiSelectOptionTile(
              label: 'Step-free access',
              selected: selected,
              autofocus: true,
              focusNode: focusNode,
              onChanged: (bool value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled multi-select is not actionable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    bool called = false;

    await tester.pumpWidget(
      _TestApp(
        child: MultiSelectOptionTile(
          label: 'Accessible parking',
          selected: false,
          enabled: false,
          onChanged: (bool value) => called = true,
        ),
      ),
    );

    final Finder tile = find.bySemanticsLabel('Accessible parking');
    final SemanticsNode node = tester.getSemantics(tile);
    final SemanticsData data = node.getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);

    await tester.tap(tile);
    await tester.pump();
    expect(called, isFalse);
    semantics.dispose();
  });

  testWidgets('components remain usable at 3.2x text on a small screen', (
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

    await tester.pumpWidget(
      _TestApp(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SectionSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MultiSelectOptionTile(
                  label: 'Detailed explanations',
                  description:
                      'Give me extra context so I can make a comfortable '
                      'decision.',
                  selected: true,
                  onChanged: (bool value) {},
                ),
                const SizedBox(height: 16),
                const AppStatusIndicator(
                  kind: AppStatusKind.unknown,
                  label: 'Restroom maneuverability',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Detailed explanations'), findsOneWidget);
    expect(find.text('Unknown: Restroom maneuverability'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status treatments include distinct visible icon and text cues', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const _TestApp(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppStatusIndicator(
              kind: AppStatusKind.strength,
              label: 'Step-free entrance',
            ),
            AppStatusIndicator(
              kind: AppStatusKind.concern,
              label: 'Noise after 7 PM',
            ),
            AppStatusIndicator(
              kind: AppStatusKind.unknown,
              label: 'Large-text menu',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Strength: Step-free entrance'), findsOneWidget);
    expect(find.text('Concern: Noise after 7 PM'), findsOneWidget);
    expect(find.text('Unknown: Large-text menu'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    expect(
      find.bySemanticsLabel('Strength: Step-free entrance'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Concern: Noise after 7 PM'), findsOneWidget);
    expect(find.bySemanticsLabel('Unknown: Large-text menu'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('multi-select meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: MultiSelectOptionTile(
          label: 'Patient staff',
          selected: false,
          onChanged: (bool value) {},
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
    );
  }
}
