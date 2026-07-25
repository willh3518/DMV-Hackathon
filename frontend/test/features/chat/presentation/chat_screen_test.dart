import 'dart:async';

import 'package:accessibility_frontend/contracts/discovery_gateway.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/chat/chat_models.dart';
import 'package:accessibility_frontend/features/chat/presentation/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatScreen', () {
    testWidgets('opens on the heading and suggestions only fill the composer', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
        responses: <DiscoveryResult>[
          const DiscoveryNoResults(
            conversationId: 'conversation-1',
            message: 'No places found.',
          ),
        ],
      );
      try {
        await tester.pumpWidget(_buildApp(gateway: gateway));
        await tester.pump();

        final Focus heading = tester.widget<Focus>(
          find.byKey(ChatScreen.headingFocusKey),
        );
        expect(heading.focusNode?.hasFocus, isTrue);
        expect(find.text('How can I help?'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Use suggestion: Find a quiet restaurant nearby',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(
                find.byKey(
                  const ValueKey<String>('chat_suggestion_quiet-restaurant'),
                ),
              )
              .height,
          greaterThanOrEqualTo(48),
        );

        await _performSemanticsTap(
          tester,
          find.bySemanticsLabel(
            'Use suggestion: Find a quiet restaurant nearby',
          ),
        );

        expect(
          tester
              .widget<TextField>(find.byKey(ChatScreen.composerKey))
              .controller
              ?.text,
          'Find a quiet restaurant with step-free access nearby.',
        );
        expect(gateway.callCount, 0);
        expect(
          tester
              .widget<TextField>(find.byKey(ChatScreen.composerKey))
              .focusNode
              ?.hasFocus,
          isTrue,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('keyboard traversal reaches the location action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(
          gateway: _FakeDiscoveryGateway(responses: <DiscoveryResult>[]),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        _primaryFocusIsWithin(
          tester,
          find.byKey(ChatScreen.headerLocationButtonKey),
        ),
        isTrue,
      );
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(
                'Change search location. Current location: Near me',
              ),
            )
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      semantics.dispose();
    });

    testWidgets('disables whitespace submissions', (WidgetTester tester) async {
      final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
        responses: <DiscoveryResult>[],
      );
      await tester.pumpWidget(_buildApp(gateway: gateway));

      await tester.enterText(find.byKey(ChatScreen.composerKey), '   \n ');
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(find.byKey(ChatScreen.sendButtonKey))
            .onPressed,
        isNull,
      );
      expect(gateway.callCount, 0);
    });

    testWidgets(
      'guards duplicate sends and focuses the composer for clarification',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final Completer<DiscoveryResult> response =
            Completer<DiscoveryResult>();
        final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
          handler: (DiscoveryRequest _) => response.future,
        );
        await tester.pumpWidget(_buildApp(gateway: gateway));

        await tester.enterText(
          find.byKey(ChatScreen.composerKey),
          'Find a calm activity.',
        );
        await tester.pump();
        await _performSemanticsTap(
          tester,
          find.bySemanticsLabel('Send request'),
        );
        await tester.pump();
        await tester.tap(find.byKey(ChatScreen.sendButtonKey));
        await tester.pump();

        expect(gateway.callCount, 1);
        expect(find.text('Find a calm activity.'), findsOneWidget);
        expect(find.byKey(ChatScreen.pendingStatusKey), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.byKey(ChatScreen.sendButtonKey))
              .onPressed,
          isNull,
        );

        response.complete(
          const DiscoveryClarification(
            conversationId: 'conversation-1',
            message: 'Would you prefer an indoor or outdoor activity?',
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Would you prefer an indoor or outdoor activity?'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(ChatScreen.composerKey))
              .focusNode
              ?.hasFocus,
          isTrue,
        );
        semantics.dispose();
      },
    );

    testWidgets('renders coordinator results and announces a bounded summary', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      const _TestResultsPayload payload = _TestResultsPayload(
        resultCount: 3,
        announcementLabel: 'Three matching places are ready.',
      );
      DiscoveryResultsPayload? builtPayload;
      final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
        responses: <DiscoveryResult>[
          const DiscoveryResults(
            conversationId: 'conversation-1',
            message: 'Here are three places to consider.',
            payload: payload,
          ),
        ],
      );
      try {
        await tester.pumpWidget(
          _buildApp(
            gateway: gateway,
            resultsBuilder:
                (BuildContext context, DiscoveryResultsPayload value) {
                  builtPayload = value;
                  return const Text(
                    'Coordinator-owned recommendation content',
                    key: Key('test_results_content'),
                  );
                },
          ),
        );

        await _send(tester, 'Find an accessible restaurant.');
        await tester.pumpAndSettle();

        expect(gateway.callCount, 1);
        expect(find.byKey(ChatScreen.pendingStatusKey), findsNothing);
        expect(
          tester.getSemantics(find.byKey(ChatScreen.liveRegionKey)),
          matchesSemantics(
            isLiveRegion: true,
            label: 'Three matching places are ready.',
          ),
        );
        expect(builtPayload, same(payload));
        expect(find.byKey(ChatScreen.resultsKey), findsOneWidget);
        expect(find.byKey(const Key('test_results_content')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(ChatScreen.transcriptKey),
            matching: find.byWidgetPredicate(
              (Widget widget) =>
                  widget is Semantics && widget.properties.liveRegion == true,
            ),
          ),
          findsNothing,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('shows no-results as unknown rather than inaccessible', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
        responses: <DiscoveryResult>[
          const DiscoveryNoResults(
            conversationId: 'conversation-1',
            message:
                'I could not find enough reliable information for that request.',
          ),
        ],
      );
      try {
        await tester.pumpWidget(_buildApp(gateway: gateway));
        await _send(tester, 'Find somewhere quiet.');
        await tester.pumpAndSettle();

        expect(find.byKey(ChatScreen.noResultsKey), findsOneWidget);
        expect(
          find.text(
            'I could not find enough reliable information for that request.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('inaccessible'), findsNothing);
        expect(
          tester.getSemantics(find.byKey(ChatScreen.liveRegionKey)),
          matchesSemantics(
            isLiveRegion: true,
            label:
                'No matching places found. I could not find enough reliable '
                'information for that request.',
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    for (final DiscoveryFailureReason reason in <DiscoveryFailureReason>[
      DiscoveryFailureReason.networkUnavailable,
      DiscoveryFailureReason.serviceUnavailable,
    ]) {
      testWidgets(
        '${reason.name} restores editable text and retries without a duplicate',
        (WidgetTester tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          const String query = 'Find a quiet café nearby.';
          final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
            responses: <DiscoveryResult>[
              DiscoveryFailure(reason: reason),
              const DiscoveryNoResults(
                conversationId: 'conversation-1',
                message: 'No reliable matches yet.',
              ),
            ],
          );
          await tester.pumpWidget(_buildApp(gateway: gateway));

          await _send(tester, query);
          await tester.pumpAndSettle();

          expect(find.byKey(ChatScreen.errorStatusKey), findsOneWidget);
          expect(find.byKey(ChatScreen.retryButtonKey), findsOneWidget);
          expect(
            tester
                .widget<TextField>(find.byKey(ChatScreen.composerKey))
                .controller
                ?.text,
            query,
          );
          expect(
            tester
                .widget<Focus>(find.byKey(ChatScreen.errorStatusKey))
                .focusNode
                ?.hasFocus,
            isTrue,
          );
          expect(
            tester
                .getSemantics(find.byKey(ChatScreen.retryButtonKey))
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isTrue,
          );

          await tester.tap(find.byKey(ChatScreen.retryButtonKey));
          await tester.pumpAndSettle();

          expect(gateway.callCount, 2);
          expect(find.text(query), findsOneWidget);
          expect(find.byKey(ChatScreen.errorStatusKey), findsNothing);
          expect(find.byKey(ChatScreen.noResultsKey), findsOneWidget);
          semantics.dispose();
        },
      );
    }

    testWidgets('location failure preserves the request and offers support', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int locationSupportCount = 0;
      final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
        responses: <DiscoveryResult>[
          const DiscoveryFailure(
            reason: DiscoveryFailureReason.locationUnavailable,
          ),
        ],
      );
      await tester.pumpWidget(
        _buildApp(
          gateway: gateway,
          onLocationSupport: () => locationSupportCount += 1,
        ),
      );

      await _send(tester, 'Find a nearby museum.');
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(ChatScreen.composerKey))
            .controller
            ?.text,
        'Find a nearby museum.',
      );
      expect(find.byKey(ChatScreen.retryButtonKey), findsNothing);

      await _performSemanticsTap(
        tester,
        find.byKey(ChatScreen.locationButtonKey),
      );

      expect(locationSupportCount, 1);
      expect(gateway.callCount, 1);
      semantics.dispose();
    });

    testWidgets('session expiry removes protected conversation content', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int sessionExpiredCount = 0;
      int reauthenticateCount = 0;
      final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
        responses: <DiscoveryResult>[
          const DiscoveryResults(
            conversationId: 'conversation-1',
            message: 'I found one place.',
            payload: _TestResultsPayload(
              resultCount: 1,
              announcementLabel: 'One matching place is ready.',
            ),
          ),
          const DiscoveryFailure(reason: DiscoveryFailureReason.sessionExpired),
        ],
      );
      await tester.pumpWidget(
        _buildApp(
          gateway: gateway,
          onSessionExpired: () => sessionExpiredCount += 1,
          onReauthenticate: () => reauthenticateCount += 1,
        ),
      );

      await _send(tester, 'Private first request');
      await tester.pumpAndSettle();
      expect(find.byKey(ChatScreen.resultsKey), findsOneWidget);

      await _send(tester, 'Private second request');
      await tester.pumpAndSettle();

      expect(find.byKey(ChatScreen.sessionExpiredKey), findsOneWidget);
      expect(find.byKey(ChatScreen.transcriptKey), findsNothing);
      expect(find.byKey(ChatScreen.composerKey), findsNothing);
      expect(find.byKey(ChatScreen.resultsKey), findsNothing);
      expect(find.textContaining('Private'), findsNothing);
      expect(sessionExpiredCount, 1);
      expect(reauthenticateCount, 0);

      await _performSemanticsTap(
        tester,
        find.byKey(ChatScreen.reauthenticateButtonKey),
      );
      expect(sessionExpiredCount, 1);
      expect(reauthenticateCount, 1);
      semantics.dispose();
    });

    testWidgets('notifies the parent as soon as session expiry arrives', (
      WidgetTester tester,
    ) async {
      final Completer<DiscoveryResult> response = Completer<DiscoveryResult>();
      int sessionExpiredCount = 0;
      int reauthenticateCount = 0;
      final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
        handler: (DiscoveryRequest _) => response.future,
      );
      await tester.pumpWidget(
        _buildApp(
          gateway: gateway,
          onSessionExpired: () => sessionExpiredCount += 1,
          onReauthenticate: () => reauthenticateCount += 1,
        ),
      );

      await tester.enterText(
        find.byKey(ChatScreen.composerKey),
        'A private request',
      );
      await tester.pump();
      await tester.tap(find.byKey(ChatScreen.sendButtonKey));
      await tester.pump();

      expect(sessionExpiredCount, 0);
      expect(reauthenticateCount, 0);

      response.complete(
        const DiscoveryFailure(reason: DiscoveryFailureReason.sessionExpired),
      );
      await tester.idle();

      expect(sessionExpiredCount, 1);
      expect(reauthenticateCount, 0);

      await tester.pump();
      expect(find.byKey(ChatScreen.sessionExpiredKey), findsOneWidget);

      await tester.tap(find.byKey(ChatScreen.reauthenticateButtonKey));
      await tester.pump();
      expect(sessionExpiredCount, 1);
      expect(reauthenticateCount, 1);
    });

    testWidgets(
      'supports 3.2x text, 320 by 568 layout, reduced motion, and tap targets',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final _FakeDiscoveryGateway gateway = _FakeDiscoveryGateway(
          responses: <DiscoveryResult>[
            const DiscoveryNoResults(
              conversationId: 'conversation-1',
              message: 'No reliable matches yet.',
            ),
          ],
        );
        await tester.pumpWidget(
          _buildApp(
            gateway: gateway,
            textScaler: const TextScaler.linear(3.2),
            disableAnimations: true,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(ChatScreen.sendButtonKey)).height,
          greaterThanOrEqualTo(48),
        );
        await tester.ensureVisible(find.byKey(ChatScreen.composerKey));
        await _send(tester, 'Find a place.');
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widgetList<TweenAnimationBuilder<double>>(
                find.byType(TweenAnimationBuilder<double>),
              )
              .every(
                (TweenAnimationBuilder<double> animation) =>
                    animation.duration == AppMotion.reducedTransition,
              ),
          isTrue,
        );
      },
    );

    testWidgets('uses local height above persistent navigation at 3.2x text', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int locationSupportCount = 0;

      await tester.pumpWidget(
        _buildApp(
          gateway: _FakeDiscoveryGateway(responses: <DiscoveryResult>[]),
          onLocationSupport: () => locationSupportCount += 1,
          textScaler: const TextScaler.linear(3.2),
          disableAnimations: true,
          bottomNavigationHeight: 132,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(ChatScreen.headingFocusKey), findsOneWidget);
      expect(find.byKey(ChatScreen.headerLocationButtonKey), findsOneWidget);
      expect(find.byKey(ChatScreen.composerKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(ChatScreen.sendButtonKey)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(
                'Change search location. Current location: Near me',
              ),
            )
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await _performSemanticsTap(
        tester,
        find.bySemanticsLabel(
          'Change search location. Current location: Near me',
        ),
      );
      expect(locationSupportCount, 1);

      await tester.enterText(
        find.byKey(ChatScreen.composerKey),
        'Find a quiet restaurant.',
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Find a quiet restaurant.'), findsOneWidget);
      semantics.dispose();
    });
  });
}

Future<void> _send(WidgetTester tester, String request) async {
  await tester.enterText(find.byKey(ChatScreen.composerKey), request);
  await tester.pump();
  await tester.tap(find.byKey(ChatScreen.sendButtonKey));
  await tester.pump();
  await tester.idle();
  await tester.pump();
}

Future<void> _performSemanticsTap(WidgetTester tester, Finder finder) async {
  final SemanticsNode node = tester.getSemantics(finder);
  expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  await tester.tap(finder);
  await tester.pump();
}

bool _primaryFocusIsWithin(WidgetTester tester, Finder ancestorFinder) {
  final Element ancestor = tester.element(ancestorFinder);
  final BuildContext? focusContext =
      FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) {
    return false;
  }
  if (identical(focusContext, ancestor)) {
    return true;
  }

  bool isWithin = false;
  focusContext.visitAncestorElements((Element element) {
    isWithin = identical(element, ancestor);
    return !isWithin;
  });
  return isWithin;
}

Widget _buildApp({
  required DiscoveryGateway gateway,
  ChatResultsBuilder? resultsBuilder,
  VoidCallback? onLocationSupport,
  VoidCallback? onSessionExpired,
  VoidCallback? onReauthenticate,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  double? bottomNavigationHeight,
}) {
  final Widget chat = _ChatHarness(
    gateway: gateway,
    resultsBuilder: resultsBuilder,
    onLocationSupport: onLocationSupport,
    onSessionExpired: onSessionExpired,
    onReauthenticate: onReauthenticate,
  );
  return MaterialApp(
    theme: AppTheme.light,
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: child!,
      );
    },
    home: bottomNavigationHeight == null
        ? chat
        : Scaffold(
            body: chat,
            bottomNavigationBar: SizedBox(height: bottomNavigationHeight),
          ),
  );
}

class _ChatHarness extends StatefulWidget {
  const _ChatHarness({
    required this.gateway,
    this.resultsBuilder,
    this.onLocationSupport,
    this.onSessionExpired,
    this.onReauthenticate,
  });

  final DiscoveryGateway gateway;
  final ChatResultsBuilder? resultsBuilder;
  final VoidCallback? onLocationSupport;
  final VoidCallback? onSessionExpired;
  final VoidCallback? onReauthenticate;

  @override
  State<_ChatHarness> createState() => _ChatHarnessState();
}

class _ChatHarnessState extends State<_ChatHarness> {
  final FocusNode _headingFocusNode = FocusNode(
    debugLabel: 'Test chat heading',
    skipTraversal: true,
  );

  @override
  void dispose() {
    _headingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(
      gateway: widget.gateway,
      suggestedPrompts: const <ChatSuggestedPrompt>[
        ChatSuggestedPrompt(
          id: 'quiet-restaurant',
          label: 'Find a quiet restaurant nearby',
          requestText: 'Find a quiet restaurant with step-free access nearby.',
        ),
        ChatSuggestedPrompt(
          id: 'calm-activity',
          label: 'Find a calm indoor activity',
          requestText: 'Find a calm indoor activity with accessible seating.',
        ),
      ],
      location: const ChatLocationSummary(label: 'Near me'),
      headingFocusNode: _headingFocusNode,
      resultsBuilder:
          widget.resultsBuilder ??
          (BuildContext context, DiscoveryResultsPayload payload) {
            return Text('${payload.resultCount} result fixtures');
          },
      onLocationSupport: widget.onLocationSupport ?? () {},
      onSessionExpired: widget.onSessionExpired ?? () {},
      onReauthenticate: widget.onReauthenticate ?? () {},
    );
  }
}

class _FakeDiscoveryGateway implements DiscoveryGateway {
  _FakeDiscoveryGateway({
    this.responses = const <DiscoveryResult>[],
    this.handler,
  });

  final List<DiscoveryResult> responses;
  final Future<DiscoveryResult> Function(DiscoveryRequest request)? handler;
  int callCount = 0;

  @override
  Future<DiscoveryResult> send(DiscoveryRequest request) {
    final int responseIndex = callCount;
    callCount += 1;
    final Future<DiscoveryResult> Function(DiscoveryRequest request)?
    sendHandler = handler;
    if (sendHandler != null) {
      return sendHandler(request);
    }
    if (responseIndex >= responses.length) {
      throw StateError('No fake discovery response at $responseIndex.');
    }
    return Future<DiscoveryResult>.value(responses[responseIndex]);
  }
}

final class _TestResultsPayload implements DiscoveryResultsPayload {
  const _TestResultsPayload({
    required this.resultCount,
    required this.announcementLabel,
  });

  @override
  final int resultCount;

  @override
  final String announcementLabel;
}
