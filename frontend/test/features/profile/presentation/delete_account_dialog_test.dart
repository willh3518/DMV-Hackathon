import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/profile/presentation/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../profile_test_support.dart';

void main() {
  testWidgets('Cancel closes confirmation without making a request', (
    WidgetTester tester,
  ) async {
    final TestProfileGateway gateway = TestProfileGateway();
    await tester.pumpWidget(_harness(gateway));
    await _openDialog(tester);

    expect(find.text('Send a deletion request?'), findsOneWidget);
    expect(
      find.textContaining('will not be shown as deleted unless'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(DeleteAccountDialog.cancelButtonKey));
    await tester.pumpAndSettle();

    expect(gateway.deletionRequestCount, 0);
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('submitted, pending, and confirmed remain distinct', (
    WidgetTester tester,
  ) async {
    int statusIndex = 0;
    int confirmations = 0;
    final TestProfileGateway gateway = TestProfileGateway(
      requestDeletion: () async => const AccountDeletionSubmitted(),
      loadDeletionStatus: () async {
        statusIndex += 1;
        return statusIndex == 1
            ? const AccountDeletionPending()
            : const AccountDeletionConfirmed();
      },
    );
    await tester.pumpWidget(
      _harness(gateway, onConfirmed: () => confirmations += 1),
    );
    await _openDialog(tester);

    await tester.tap(find.byKey(DeleteAccountDialog.primaryButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Request submitted'), findsOneWidget);
    expect(
      find.textContaining('has not confirmed account deletion'),
      findsOneWidget,
    );
    expect(confirmations, 0);

    await tester.tap(find.byKey(DeleteAccountDialog.primaryButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Request pending'), findsOneWidget);
    expect(find.textContaining('not shown as deleted'), findsOneWidget);
    expect(confirmations, 0);

    await tester.tap(find.byKey(DeleteAccountDialog.primaryButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Deletion confirmed'), findsOneWidget);
    expect(confirmations, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Deletion confirmed'), findsOneWidget);
    expect(confirmations, 0);

    await tester.tap(find.byKey(DeleteAccountDialog.primaryButtonKey));
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('failure retries the operation that failed', (
    WidgetTester tester,
  ) async {
    int requestIndex = 0;
    final TestProfileGateway gateway = TestProfileGateway(
      requestDeletion: () async {
        requestIndex += 1;
        return requestIndex == 1
            ? const AccountDeletionFailure(
                reason: ProfileOperationFailureReason.serviceUnavailable,
              )
            : const AccountDeletionSubmitted();
      },
    );
    await tester.pumpWidget(_harness(gateway));
    await _openDialog(tester);

    await tester.tap(find.byKey(DeleteAccountDialog.primaryButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Deletion was not confirmed'), findsOneWidget);

    await tester.tap(find.byKey(DeleteAccountDialog.primaryButtonKey));
    await tester.pumpAndSettle();
    expect(gateway.deletionRequestCount, 2);
    expect(gateway.deletionStatusCount, 0);
    expect(find.text('Request submitted'), findsOneWidget);
  });

  testWidgets('confirmation meets accessibility guidelines at 3.2x text', (
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
    await tester.pumpWidget(_harness(gateway));
    await _openDialog(tester);

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

Widget _harness(TestProfileGateway gateway, {VoidCallback? onConfirmed}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return FilledButton(
            key: const Key('open_delete_dialog'),
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return DeleteAccountDialog(
                    gateway: gateway,
                    onDeletionConfirmed: onConfirmed ?? () {},
                  );
                },
              );
            },
            child: const Text('Open delete dialog'),
          );
        },
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_delete_dialog')));
  await tester.pumpAndSettle();
}
