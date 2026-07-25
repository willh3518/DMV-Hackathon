import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/profile/presentation/legal_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../profile_test_support.dart';

void main() {
  testWidgets('loaded placeholder is explicit and renders supplied body', (
    WidgetTester tester,
  ) async {
    final TestProfileGateway gateway = TestProfileGateway(
      loadLegal: (LegalDocumentKind kind) async {
        return const LegalContentLoaded(
          document: LegalDocument(
            kind: LegalDocumentKind.privacy,
            title: 'Privacy placeholder',
            body: 'Synthetic supplied placeholder body.',
            isPlaceholder: true,
          ),
        );
      },
    );
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    expect(find.text('Privacy placeholder'), findsOneWidget);
    expect(find.byKey(LegalDocumentScreen.placeholderKey), findsOneWidget);
    expect(
      find.textContaining('this is not production legal content'),
      findsOneWidget,
    );
    expect(find.text('Synthetic supplied placeholder body.'), findsOneWidget);
  });

  testWidgets(
    'failure shows no stale body and Retry renders supplied content',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int resultIndex = 0;
      final TestProfileGateway gateway = TestProfileGateway(
        loadLegal: (LegalDocumentKind kind) async {
          resultIndex += 1;
          return resultIndex == 1
              ? const LegalContentFailure(
                  reason: ProfileOperationFailureReason.networkUnavailable,
                )
              : const LegalContentLoaded(
                  document: LegalDocument(
                    kind: LegalDocumentKind.privacy,
                    title: 'Privacy placeholder',
                    body: 'Synthetic retry content.',
                    isPlaceholder: true,
                  ),
                );
        },
      );
      await tester.pumpWidget(_app(gateway));
      await tester.pumpAndSettle();

      expect(find.text('Content did not load'), findsOneWidget);
      expect(find.byKey(LegalDocumentScreen.bodyKey), findsNothing);

      final SemanticsNode retryNode = tester.getSemantics(
        find.byKey(LegalDocumentScreen.statusKey),
      );
      expect(
        retryNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      retryNode.owner!.performAction(retryNode.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(gateway.legalCount, 2);
      expect(find.text('Synthetic retry content.'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('unavailable content is honest and offers Retry', (
    WidgetTester tester,
  ) async {
    final TestProfileGateway gateway = TestProfileGateway(
      loadLegal: (LegalDocumentKind kind) async =>
          const LegalContentUnavailable(),
    );
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    expect(find.text('Content is unavailable'), findsOneWidget);
    expect(
      find.textContaining('Approved content has not been supplied'),
      findsOneWidget,
    );
    expect(find.byKey(LegalDocumentScreen.retryButtonKey), findsOneWidget);
  });

  testWidgets('legal surface supports accessibility and 3.2x text', (
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

    final TestProfileGateway gateway = TestProfileGateway();
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();
    final Finder body = find.byKey(LegalDocumentScreen.bodyKey);
    await tester.ensureVisible(body);
    await tester.pump();

    expect(find.byKey(LegalDocumentScreen.scrollViewKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

Widget _app(TestProfileGateway gateway) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: LegalDocumentScreen(
        gateway: gateway,
        kind: LegalDocumentKind.privacy,
        onBack: () {},
      ),
    ),
  );
}
