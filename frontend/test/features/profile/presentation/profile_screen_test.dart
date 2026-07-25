import 'dart:async';

import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../profile_test_support.dart';

void main() {
  testWidgets('default Profile requests focus for its heading', (
    WidgetTester tester,
  ) async {
    final TestProfileGateway gateway = TestProfileGateway();
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    final Focus heading = tester.widget<Focus>(
      find.byKey(ProfileScreen.headingKey),
    );
    expect(heading.focusNode?.hasFocus, isTrue);
  });

  testWidgets(
    'supplied heading node can suppress initial focus and is not disposed',
    (WidgetTester tester) async {
      final FocusNode headingFocusNode = FocusNode(
        debugLabel: 'Coordinator Profile heading',
      );
      addTearDown(headingFocusNode.dispose);
      final TestProfileGateway gateway = TestProfileGateway();

      await tester.pumpWidget(
        _app(
          gateway,
          headingFocusNode: headingFocusNode,
          requestInitialHeadingFocus: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(headingFocusNode.hasFocus, isFalse);

      headingFocusNode.requestFocus();
      await tester.pump();
      expect(headingFocusNode.hasFocus, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(() => headingFocusNode.addListener(() {}), returnsNormally);
    },
  );

  testWidgets('initial loading does not expose fabricated profile summaries', (
    WidgetTester tester,
  ) async {
    final Completer<ProfileLoadResult> load = Completer<ProfileLoadResult>();
    final TestProfileGateway gateway = TestProfileGateway(
      loadProfile: () => load.future,
    );
    await tester.pumpWidget(_app(gateway));
    await tester.pump();

    expect(find.byKey(ProfileScreen.loadingKey), findsOneWidget);
    for (final ProfileSectionId section in ProfileSectionId.values) {
      expect(find.byKey(ProfileScreen.sectionKey(section)), findsNothing);
    }

    load.complete(const ProfileLoadSuccess(profile: mixedProfile));
    await tester.pumpAndSettle();
    expect(find.byKey(ProfileScreen.loadingKey), findsNothing);
    expect(
      find.byKey(ProfileScreen.sectionKey(ProfileSectionId.accommodations)),
      findsOneWidget,
    );
  });

  testWidgets(
    'load failure hides profile data and Retry renders five summaries',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int resultIndex = 0;
      final TestProfileGateway gateway = TestProfileGateway(
        loadProfile: () async {
          resultIndex += 1;
          return resultIndex == 1
              ? const ProfileLoadFailure(
                  reason: ProfileOperationFailureReason.networkUnavailable,
                )
              : const ProfileLoadSuccess(profile: mixedProfile);
        },
      );
      await tester.pumpWidget(_app(gateway));
      await tester.pumpAndSettle();

      expect(find.byKey(ProfileScreen.loadErrorKey), findsOneWidget);
      expect(
        find.byKey(ProfileScreen.sectionKey(ProfileSectionId.accommodations)),
        findsNothing,
      );

      final SemanticsNode retryNode = tester.getSemantics(
        find.byKey(ProfileScreen.loadErrorKey),
      );
      expect(
        retryNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      retryNode.owner!.performAction(retryNode.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(gateway.loadCount, 2);
      for (final ProfileSectionId section in ProfileSectionId.values) {
        expect(find.byKey(ProfileScreen.sectionKey(section)), findsOneWidget);
        expect(
          find.byKey(ProfileScreen.editSectionKey(section)),
          findsOneWidget,
        );
      }
      expect(find.text('Step-free access'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('0.5 miles'), findsOneWidget);
      expect(find.text('Museums'), findsOneWidget);
      expect(
        find.text('Something else: Synthetic community art classes'),
        findsOneWidget,
      );
      expect(find.text('None'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('load failure keeps sign out reachable and confirmed', (
    WidgetTester tester,
  ) async {
    int confirmedSignOuts = 0;
    final TestProfileGateway gateway = TestProfileGateway(
      loadProfile: () async => const ProfileLoadFailure(
        reason: ProfileOperationFailureReason.serviceUnavailable,
      ),
      signOut: () async => const SignOutConfirmed(),
    );
    await tester.pumpWidget(
      _app(gateway, onSignedOut: () => confirmedSignOuts += 1),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileScreen.loadErrorKey), findsOneWidget);
    for (final ProfileSectionId section in ProfileSectionId.values) {
      expect(find.byKey(ProfileScreen.sectionKey(section)), findsNothing);
    }
    expect(find.byKey(ProfileScreen.termsButtonKey), findsOneWidget);
    expect(find.byKey(ProfileScreen.privacyButtonKey), findsOneWidget);

    final Finder signOut = find.byKey(ProfileScreen.signOutButtonKey);
    await _tapVisible(tester, signOut);
    expect(gateway.signOutCount, 1);
    expect(confirmedSignOuts, 1);
  });

  testWidgets('failed save preserves edits and Retry confirms the same draft', (
    WidgetTester tester,
  ) async {
    final Completer<ProfileSaveResult> firstSave =
        Completer<ProfileSaveResult>();
    final TestProfileGateway gateway = TestProfileGateway(
      saveProfile: (ProfileSnapshot draft) {
        if (!firstSave.isCompleted) {
          return firstSave.future;
        }
        return Future<ProfileSaveResult>.value(const ProfileSaveConfirmed());
      },
    );
    await tester.pumpWidget(
      _app(
        gateway,
        onEditSection:
            (ProfileSectionId section, ProfileSnapshot current) async =>
                editedProfile,
      ),
    );
    await tester.pumpAndSettle();

    final Finder edit = find.byKey(
      ProfileScreen.editSectionKey(ProfileSectionId.accommodations),
    );
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(
      find.text('Something else: Synthetic seating request'),
      findsOneWidget,
    );

    final Finder save = find.byKey(ProfileScreen.saveButtonKey);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Saving changes'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    firstSave.complete(
      const ProfileSaveFailure(
        reason: ProfileOperationFailureReason.serviceUnavailable,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Profile changes were not saved'),
      findsOneWidget,
    );
    expect(
      find.text('Something else: Synthetic seating request'),
      findsOneWidget,
    );
    expect(find.text('Retry save'), findsOneWidget);

    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(gateway.saveCount, 2);
    expect(find.text('Profile changes saved.'), findsOneWidget);
  });

  testWidgets('legal callbacks are typed and sign out waits for confirmation', (
    WidgetTester tester,
  ) async {
    final List<LegalDocumentKind> openedLegal = <LegalDocumentKind>[];
    int signOutResultIndex = 0;
    int confirmedSignOuts = 0;
    final TestProfileGateway gateway = TestProfileGateway(
      signOut: () async {
        signOutResultIndex += 1;
        return signOutResultIndex == 1
            ? const SignOutFailure(
                reason: ProfileOperationFailureReason.networkUnavailable,
              )
            : const SignOutConfirmed();
      },
    );
    await tester.pumpWidget(
      _app(
        gateway,
        onOpenLegal: openedLegal.add,
        onSignedOut: () => confirmedSignOuts += 1,
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(ProfileScreen.termsButtonKey));
    await _tapVisible(tester, find.byKey(ProfileScreen.privacyButtonKey));
    expect(openedLegal, <LegalDocumentKind>[
      LegalDocumentKind.terms,
      LegalDocumentKind.privacy,
    ]);

    final Finder signOut = find.byKey(ProfileScreen.signOutButtonKey);
    await _tapVisible(tester, signOut);
    expect(confirmedSignOuts, 0);
    expect(find.textContaining('Sign out was not confirmed'), findsOneWidget);

    await _tapVisible(tester, signOut);
    expect(gateway.signOutCount, 2);
    expect(confirmedSignOuts, 1);
  });

  testWidgets('loaded profile meets accessibility guidelines', (
    WidgetTester tester,
  ) async {
    final TestProfileGateway gateway = TestProfileGateway();
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('profile remains usable at 3.2x text on a small screen', (
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

    final Finder delete = find.byKey(ProfileScreen.deleteAccountButtonKey);
    await tester.ensureVisible(delete);
    await tester.pump();

    expect(find.byKey(ProfileScreen.scrollViewKey), findsOneWidget);
    expect(delete, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  TestProfileGateway gateway, {
  ProfileSectionEditor? onEditSection,
  ValueChanged<LegalDocumentKind>? onOpenLegal,
  VoidCallback? onSignedOut,
  FocusNode? headingFocusNode,
  bool requestInitialHeadingFocus = true,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: ProfileScreen(
        gateway: gateway,
        onEditSection:
            onEditSection ??
            (ProfileSectionId section, ProfileSnapshot current) async => null,
        onOpenLegal: onOpenLegal ?? (LegalDocumentKind kind) {},
        onSignedOut: onSignedOut ?? () {},
        onAccountDeleted: () {},
        headingFocusNode: headingFocusNode,
        requestInitialHeadingFocus: requestInitialHeadingFocus,
      ),
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
