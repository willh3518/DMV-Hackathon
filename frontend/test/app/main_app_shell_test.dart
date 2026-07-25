import 'dart:async';

import 'package:accessibility_frontend/app/main_app_shell.dart';
import 'package:accessibility_frontend/contracts/discovery_gateway.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/chat/chat_models.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/chat/presentation/chat_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_one_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/onboarding_question_shell.dart';
import 'package:accessibility_frontend/features/profile/presentation/delete_account_dialog.dart';
import 'package:accessibility_frontend/features/profile/presentation/legal_document_screen.dart';
import 'package:accessibility_frontend/features/profile/presentation/profile_screen.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/place_detail_route.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/recommendation_card.dart';
import 'package:accessibility_frontend/fixtures/synthetic_profile_fixtures.dart';
import 'package:accessibility_frontend/fixtures/synthetic_recommendation_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('provides exactly the Chat and Profile destinations', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);

    final NavigationBar navigationBar = tester.widget<NavigationBar>(
      find.byKey(MainAppShell.navigationBarKey),
    );
    expect(navigationBar.destinations, hasLength(2));
    expect(find.byKey(MainAppShell.chatDestinationKey), findsOneWidget);
    expect(find.byKey(MainAppShell.profileDestinationKey), findsOneWidget);
    expect(find.text('Find a place'), findsOneWidget);
    expect(
      tester
          .widget<Focus>(find.byKey(ChatScreen.headingFocusKey))
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();

    expect(find.text('Your profile'), findsOneWidget);
    expect(
      tester
          .widget<Focus>(find.byKey(ProfileScreen.headingKey))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
    expect(find.byKey(ProfileScreen.termsButtonKey), findsOneWidget);
    expect(find.byKey(ProfileScreen.privacyButtonKey), findsOneWidget);
    expect(find.byKey(ProfileScreen.deleteAccountButtonKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat result cards open a provider-neutral place detail route', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);

    await tester.tap(find.byKey(const Key('chat_suggestion_quiet-italian')));
    await tester.pump();
    await tester.tap(find.byKey(ChatScreen.sendButtonKey));
    await tester.pumpAndSettle();

    expect(
      find.text(SyntheticRecommendationFixtures.restaurant.placeName),
      findsOneWidget,
    );
    expect(
      find.text(SyntheticRecommendationFixtures.activity.placeName),
      findsOneWidget,
    );

    final Finder detailsButton = find.byKey(
      RecommendationCard.detailsButtonKey(
        SyntheticRecommendationFixtures.restaurant.id,
      ),
    );
    await tester.ensureVisible(detailsButton);
    await tester.pump();
    await tester.tap(detailsButton);
    await tester.pumpAndSettle();

    expect(find.byKey(PlaceDetailRoute.headingFocusKey), findsOneWidget);
    expect(find.text('Business-declared evidence'), findsOneWidget);
    expect(find.text('Customer-observed evidence'), findsWidgets);
    expect(
      find.text('No declared or observed evidence was supplied yet.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile legal actions open clearly marked placeholder content', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);
    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();

    final Finder privacyButton = find.byKey(ProfileScreen.privacyButtonKey);
    await tester.ensureVisible(privacyButton);
    await tester.pump();
    await tester.tap(privacyButton);
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.byKey(LegalDocumentScreen.placeholderKey), findsOneWidget);
    expect(
      find.text(
        'Approved privacy language has not been supplied for this hackathon '
        'prototype.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile sections edit through the existing question UI', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);
    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();

    final Finder editAccommodations = find.byKey(
      ProfileScreen.editSectionKey(ProfileSectionId.accommodations),
    );
    await tester.ensureVisible(editAccommodations);
    await tester.pump();
    await tester.tap(editAccommodations);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final Finder parking = find.byKey(
      QuestionOneScreen.optionKey(AccommodationOption.accessibleParking),
    );
    await tester.ensureVisible(parking);
    await tester.tap(parking);
    await tester.pump();
    final Finder save = find.byKey(OnboardingQuestionShell.continueButtonKey);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Your profile'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          ProfileScreen.sectionKey(ProfileSectionId.accommodations),
        ),
        matching: find.text('Accessible parking'),
      ),
      findsOneWidget,
    );
    final FilledButton saveButton = tester.widget<FilledButton>(
      find.byKey(ProfileScreen.saveButtonKey),
    );
    expect(saveButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default prototype never claims deletion was accepted', (
    WidgetTester tester,
  ) async {
    await _pumpShell(tester);
    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();

    final Finder deleteAccount = find.byKey(
      ProfileScreen.deleteAccountButtonKey,
    );
    await tester.ensureVisible(deleteAccount);
    await tester.tap(deleteAccount);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DeleteAccountDialog.primaryButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Deletion was not confirmed'), findsOneWidget);
    expect(find.text('Request submitted'), findsNothing);
    expect(find.text('Deletion confirmed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-tab shell remains usable at 3.2x text', (
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

    await _pumpShell(tester);
    expect(find.byKey(ChatScreen.headingFocusKey), findsOneWidget);
    expect(find.bySemanticsLabel('Find a place'), findsOneWidget);
    _expectNoFlutterException(tester, 'initial Chat layout');

    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
    _expectNoFlutterException(tester, 'Profile layout');
  });

  testWidgets('session expiry locks Profile until reauthentication', (
    WidgetTester tester,
  ) async {
    bool reauthenticationRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainAppShell(
          initialProfile: SyntheticProfileFixtures.sampleProfile,
          discoveryGateway: const _SessionExpiredGateway(),
          onExitToLanding: () => reauthenticationRequested = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat_suggestion_quiet-italian')));
    await tester.pump();
    await tester.tap(find.byKey(ChatScreen.sendButtonKey));
    await tester.pumpAndSettle();

    final NavigationDestination profileDestination = tester
        .widget<NavigationDestination>(
          find.byKey(MainAppShell.profileDestinationKey),
        );
    expect(profileDestination.enabled, isFalse);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Your profile'), findsNothing);

    await tester.tap(find.byKey(ChatScreen.reauthenticateButtonKey));
    expect(reauthenticationRequested, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session expiry dismisses a protected profile route', (
    WidgetTester tester,
  ) async {
    final Completer<DiscoveryResult> response = Completer<DiscoveryResult>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainAppShell(
          initialProfile: SyntheticProfileFixtures.sampleProfile,
          discoveryGateway: _CompleterDiscoveryGateway(response),
          onExitToLanding: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat_suggestion_quiet-italian')));
    await tester.pump();
    await tester.tap(find.byKey(ChatScreen.sendButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(MainAppShell.profileDestinationKey));
    await tester.pumpAndSettle();

    final Finder editAccommodations = find.byKey(
      ProfileScreen.editSectionKey(ProfileSectionId.accommodations),
    );
    await tester.ensureVisible(editAccommodations);
    await tester.tap(editAccommodations);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('What accommodations help you?'), findsOneWidget);

    response.complete(
      const DiscoveryFailure(reason: DiscoveryFailureReason.sessionExpired),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('What accommodations help you?'), findsNothing);
    expect(find.text('Your profile'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MainAppShell(
        initialProfile: SyntheticProfileFixtures.sampleProfile,
        onExitToLanding: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectNoFlutterException(WidgetTester tester, String stage) {
  final Object? exception = tester.takeException();
  if (exception is FlutterError) {
    fail('$stage:\n${exception.toStringDeep()}');
  }
  expect(exception, isNull, reason: stage);
}

final class _SessionExpiredGateway implements DiscoveryGateway {
  const _SessionExpiredGateway();

  @override
  Future<DiscoveryResult> send(DiscoveryRequest request) async {
    return const DiscoveryFailure(
      reason: DiscoveryFailureReason.sessionExpired,
    );
  }
}

final class _CompleterDiscoveryGateway implements DiscoveryGateway {
  const _CompleterDiscoveryGateway(this.response);

  final Completer<DiscoveryResult> response;

  @override
  Future<DiscoveryResult> send(DiscoveryRequest request) => response.future;
}
