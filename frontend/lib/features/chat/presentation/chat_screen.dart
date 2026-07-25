import 'package:accessibility_frontend/contracts/discovery_gateway.dart';
import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/domain/chat/chat_models.dart';
import 'package:flutter/material.dart';

typedef ChatResultsBuilder =
    Widget Function(BuildContext context, DiscoveryResultsPayload payload);

/// The conversational place-discovery workspace.
///
/// This screen owns only presentation state. Matching and recommendation
/// content are supplied by [DiscoveryGateway] and [resultsBuilder].
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.gateway,
    required this.suggestedPrompts,
    required this.location,
    required this.headingFocusNode,
    required this.resultsBuilder,
    required this.onLocationSupport,
    required this.onSessionExpired,
    required this.onReauthenticate,
    super.key,
  });

  static const Key headingFocusKey = Key('chat_heading_focus');
  static const Key transcriptKey = Key('chat_transcript');
  static const Key composerKey = Key('chat_composer');
  static const Key sendButtonKey = Key('chat_send_button');
  static const Key liveRegionKey = Key('chat_live_region');
  static const Key pendingStatusKey = Key('chat_pending_status');
  static const Key errorStatusKey = Key('chat_error_status');
  static const Key retryButtonKey = Key('chat_retry_button');
  static const Key headerLocationButtonKey = Key('chat_header_location_button');
  static const Key locationButtonKey = Key('chat_location_button');
  static const Key resultsKey = Key('chat_results');
  static const Key noResultsKey = Key('chat_no_results');
  static const Key sessionExpiredKey = Key('chat_session_expired');
  static const Key reauthenticateButtonKey = Key('chat_reauthenticate_button');

  final DiscoveryGateway gateway;
  final List<ChatSuggestedPrompt> suggestedPrompts;
  final ChatLocationSummary location;
  final FocusNode headingFocusNode;
  final ChatResultsBuilder resultsBuilder;
  final VoidCallback onLocationSupport;
  final VoidCallback onSessionExpired;
  final VoidCallback onReauthenticate;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode(
    debugLabel: 'Chat request composer',
  );
  final FocusNode _errorFocusNode = FocusNode(
    debugLabel: 'Chat error',
    skipTraversal: true,
  );
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = <ChatMessage>[];
  DiscoveryResultsPayload? _resultsPayload;
  DiscoveryFailureReason? _failureReason;
  String? _conversationId;
  String? _failedMessageId;
  String? _noResultsMessageId;
  String _liveAnnouncement = '';
  int _messageSequence = 0;
  bool _isPending = false;

  bool get _sessionExpired =>
      _failureReason == DiscoveryFailureReason.sessionExpired;

  bool get _canSend =>
      !_isPending &&
      !_sessionExpired &&
      _composerController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _composerController.addListener(_handleComposerChanged);
    _requestFocus(widget.headingFocusNode);
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _composerController
      ..removeListener(_handleComposerChanged)
      ..dispose();
    _composerFocusNode.dispose();
    _errorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _requestFocus(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final ScrollPosition position = _scrollController.position;
      if (AppMotion.prefersReducedMotion(context)) {
        _scrollController.jumpTo(position.maxScrollExtent);
        return;
      }
      _scrollController.animateTo(
        position.maxScrollExtent,
        duration: AppMotion.resolveDuration(
          context,
          duration: const Duration(milliseconds: 220),
        ),
        curve: AppMotion.standardCurve,
      );
    });
  }

  String _nextMessageId(String role) {
    _messageSequence += 1;
    return '$role-$_messageSequence';
  }

  void _useSuggestion(ChatSuggestedPrompt prompt) {
    if (_isPending || _sessionExpired) {
      return;
    }
    _composerController.value = TextEditingValue(
      text: prompt.requestText,
      selection: TextSelection.collapsed(offset: prompt.requestText.length),
    );
    _requestFocus(_composerFocusNode);
  }

  Future<void> _sendRequest() async {
    if (!_canSend) {
      return;
    }

    final String requestText = _composerController.text.trim();
    final String userMessageId;
    final String? reusableMessageId = _failureReason == null
        ? null
        : _failedMessageId;

    if (reusableMessageId == null) {
      userMessageId = _nextMessageId('user');
      _messages.add(
        ChatMessage(
          id: userMessageId,
          role: ChatRole.user,
          kind: ChatMessageKind.standard,
          text: requestText,
        ),
      );
    } else {
      userMessageId = reusableMessageId;
      final int messageIndex = _messages.indexWhere(
        (ChatMessage message) => message.id == reusableMessageId,
      );
      if (messageIndex >= 0) {
        final ChatMessage previous = _messages[messageIndex];
        _messages[messageIndex] = ChatMessage(
          id: previous.id,
          role: previous.role,
          kind: previous.kind,
          text: requestText,
        );
      }
    }

    setState(() {
      _isPending = true;
      _failureReason = null;
      _failedMessageId = null;
      _noResultsMessageId = null;
      _resultsPayload = null;
      _liveAnnouncement = 'Searching for places that fit your request.';
      _composerController.clear();
    });
    _scrollToLatest();

    late final DiscoveryResult result;
    try {
      result = await widget.gateway.send(
        DiscoveryRequest(text: requestText, conversationId: _conversationId),
      );
    } on Object {
      if (mounted) {
        _showFailure(
          reason: DiscoveryFailureReason.serviceUnavailable,
          requestText: requestText,
          userMessageId: userMessageId,
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case DiscoveryClarification clarification:
        final ChatMessage message = ChatMessage(
          id: _nextMessageId('assistant'),
          role: ChatRole.assistant,
          kind: ChatMessageKind.clarification,
          text: clarification.message,
        );
        setState(() {
          _isPending = false;
          _conversationId = clarification.conversationId;
          _messages.add(message);
          _liveAnnouncement = 'Clarification needed. ${clarification.message}';
        });
        _requestFocus(_composerFocusNode);
      case DiscoveryResults results:
        final ChatMessage message = ChatMessage(
          id: _nextMessageId('assistant'),
          role: ChatRole.assistant,
          kind: ChatMessageKind.standard,
          text: results.message,
        );
        setState(() {
          _isPending = false;
          _conversationId = results.conversationId;
          _messages.add(message);
          _resultsPayload = results.payload;
          _liveAnnouncement = results.payload.announcementLabel;
        });
      case DiscoveryNoResults noResults:
        final String messageId = _nextMessageId('assistant');
        setState(() {
          _isPending = false;
          _conversationId = noResults.conversationId;
          _messages.add(
            ChatMessage(
              id: messageId,
              role: ChatRole.assistant,
              kind: ChatMessageKind.standard,
              text: noResults.message,
            ),
          );
          _noResultsMessageId = messageId;
          _liveAnnouncement = 'No matching places found. ${noResults.message}';
        });
      case DiscoveryFailure failure:
        _showFailure(
          reason: failure.reason,
          requestText: requestText,
          userMessageId: userMessageId,
        );
        if (failure.reason == DiscoveryFailureReason.sessionExpired) {
          widget.onSessionExpired();
        }
    }
    _scrollToLatest();
  }

  void _showFailure({
    required DiscoveryFailureReason reason,
    required String requestText,
    required String userMessageId,
  }) {
    if (reason == DiscoveryFailureReason.sessionExpired) {
      setState(() {
        _isPending = false;
        _failureReason = reason;
        _messages.clear();
        _resultsPayload = null;
        _noResultsMessageId = null;
        _failedMessageId = null;
        _conversationId = null;
        _composerController.clear();
        _liveAnnouncement =
            'Session expired. ${reason.userMessage} Sign in is available.';
      });
      _requestFocus(_errorFocusNode);
      return;
    }

    setState(() {
      _isPending = false;
      _failureReason = reason;
      _failedMessageId = userMessageId;
      _resultsPayload = null;
      _noResultsMessageId = null;
      _composerController.value = TextEditingValue(
        text: requestText,
        selection: TextSelection.collapsed(offset: requestText.length),
      );
      final String action = reason.canRetry
          ? 'Retry is available.'
          : 'Choose a location to continue.';
      _liveAnnouncement = 'Search error. ${reason.userMessage} $action';
    });
    _requestFocus(_errorFocusNode);
    _scrollToLatest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.canvasTop, AppColors.canvasBottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool largeText =
                  MediaQuery.textScalerOf(context).scale(1) >= 2;
              final bool keyboardVisible =
                  MediaQuery.viewInsetsOf(context).bottom > 0;
              final bool hideVisibleHeader =
                  largeText && (keyboardVisible || constraints.maxHeight < 500);
              final bool useCompactComposer =
                  largeText && (keyboardVisible || constraints.maxHeight < 700);

              return Column(
                children: <Widget>[
                  _buildLiveRegion(),
                  if (hideVisibleHeader)
                    _buildCompactHeading()
                  else
                    _buildHeader(context),
                  Expanded(
                    child: _sessionExpired
                        ? _buildSessionExpired(context)
                        : _buildTranscript(
                            context,
                            showCompactLocationAction: hideVisibleHeader,
                          ),
                  ),
                  if (!_sessionExpired)
                    _buildComposer(
                      context,
                      useCompactLayout: useCompactComposer,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeading() {
    return Focus(
      key: ChatScreen.headingFocusKey,
      focusNode: widget.headingFocusNode,
      child: Semantics(
        header: true,
        label: 'Find a place',
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLiveRegion() {
    return Semantics(
      key: ChatScreen.liveRegionKey,
      container: true,
      liveRegion: true,
      label: _liveAnnouncement,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final Widget heading = Focus(
      key: ChatScreen.headingFocusKey,
      focusNode: widget.headingFocusNode,
      child: Semantics(
        header: true,
        child: Text(
          'Find a place',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
    final Widget locationButton = Semantics(
      button: true,
      enabled: !_isPending,
      label:
          'Change search location. Current location: '
          '${widget.location.label}',
      onTap: _isPending ? null : widget.onLocationSupport,
      child: ExcludeSemantics(
        child: largeText
            ? IconButton(
                key: ChatScreen.headerLocationButtonKey,
                onPressed: _isPending ? null : widget.onLocationSupport,
                tooltip: 'Change search location',
                icon: const Icon(Icons.location_on_outlined),
              )
            : TextButton.icon(
                key: ChatScreen.headerLocationButtonKey,
                onPressed: _isPending ? null : widget.onLocationSupport,
                icon: const Icon(Icons.location_on_outlined, size: 20),
                label: Text(
                  widget.location.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 14, 8),
      decoration: const BoxDecoration(
        color: Color(0xEFFFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.surfaceBlueStrong)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: heading),
          const SizedBox(width: 8),
          if (largeText) locationButton else Flexible(child: locationButton),
        ],
      ),
    );
  }

  Widget _buildCompactLocationAction(BuildContext context) {
    final bool enabled = !_isPending;
    return Semantics(
      button: true,
      enabled: enabled,
      label:
          'Change search location. Current location: '
          '${widget.location.label}',
      onTap: enabled ? widget.onLocationSupport : null,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: ChatScreen.headerLocationButtonKey,
            onPressed: enabled ? widget.onLocationSupport : null,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.surfaceBlueStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.location_on_outlined, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Location: ${widget.location.label}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscript(
    BuildContext context, {
    required bool showCompactLocationAction,
  }) {
    return ListView(
      key: ChatScreen.transcriptKey,
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      children: <Widget>[
        if (showCompactLocationAction) ...<Widget>[
          _buildCompactLocationAction(context),
          const SizedBox(height: 16),
        ],
        if (_messages.isEmpty) _buildEmptyState(context),
        for (final ChatMessage message in _messages) ...<Widget>[
          _AnimatedMessageBubble(
            key: ValueKey<String>(message.id),
            message: message,
            isNoResults: message.id == _noResultsMessageId,
          ),
          const SizedBox(height: 12),
        ],
        if (_isPending) ...<Widget>[
          _buildPendingStatus(context),
          const SizedBox(height: 12),
        ],
        if (_failureReason
            case final DiscoveryFailureReason failure) ...<Widget>[
          _buildFailureStatus(context, failure),
          const SizedBox(height: 12),
        ],
        if (_resultsPayload case final DiscoveryResultsPayload payload)
          KeyedSubtree(
            key: ChatScreen.resultsKey,
            child: widget.resultsBuilder(context, payload),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          container: true,
          label:
              'How can I help? Describe a restaurant or activity and what '
              'would make it work well for you.',
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(8),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.primaryStrong,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'How can I help?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Describe a restaurant or activity and what would make '
                    'it work well for you.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.suggestedPrompts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          Text(
            'Try a suggestion',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final ChatSuggestedPrompt prompt
              in widget.suggestedPrompts) ...<Widget>[
            Semantics(
              button: true,
              enabled: !_isPending,
              label: 'Use suggestion: ${prompt.label}',
              onTap: _isPending ? null : () => _useSuggestion(prompt),
              child: ExcludeSemantics(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: ValueKey<String>('chat_suggestion_${prompt.id}'),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(48, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(
                        color: AppColors.surfaceBlueStrong,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _isPending ? null : () => _useSuggestion(prompt),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.arrow_outward_rounded,
                          color: AppColors.primaryStrong,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prompt.label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _buildPendingStatus(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        key: ChatScreen.pendingStatusKey,
        container: true,
        label: 'Searching for places that fit your request.',
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceBlueStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryStrong,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Looking for a good fit…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailureStatus(
    BuildContext context,
    DiscoveryFailureReason failure,
  ) {
    final bool locationUnavailable =
        failure == DiscoveryFailureReason.locationUnavailable;
    final String actionLabel = locationUnavailable
        ? 'Choose location'
        : 'Retry search';

    return Focus(
      key: ChatScreen.errorStatusKey,
      focusNode: _errorFocusNode,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryStrong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    failure.userMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: locationUnavailable
                  ? ChatScreen.locationButtonKey
                  : ChatScreen.retryButtonKey,
              onPressed: locationUnavailable
                  ? widget.onLocationSupport
                  : _sendRequest,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionExpired(BuildContext context) {
    return Focus(
      key: ChatScreen.sessionExpiredKey,
      focusNode: _errorFocusNode,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ExcludeSemantics(
                  child: Icon(
                    Icons.lock_clock_outlined,
                    color: AppColors.primaryStrong,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  DiscoveryFailureReason.sessionExpired.userMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: ChatScreen.reauthenticateButtonKey,
                    onPressed: widget.onReauthenticate,
                    child: const Text('Sign in again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context, {
    required bool useCompactLayout,
  }) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final Widget field = TextField(
      key: ChatScreen.composerKey,
      controller: _composerController,
      focusNode: _composerFocusNode,
      enabled: !_isPending,
      minLines: 1,
      maxLines: useCompactLayout
          ? 1
          : largeText
          ? 2
          : 4,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) {
        if (_canSend) {
          _sendRequest();
        }
      },
      decoration: InputDecoration(
        labelText: largeText ? 'Search request' : 'What are you looking for?',
        hintText: largeText ? null : 'Try “A quiet Italian restaurant nearby”',
      ),
    );
    final Widget sendButton = Semantics(
      button: true,
      enabled: _canSend,
      label: _isPending ? 'Sending request' : 'Send request',
      onTap: _canSend ? _sendRequest : null,
      child: ExcludeSemantics(
        child: useCompactLayout
            ? IconButton.filled(
                key: ChatScreen.sendButtonKey,
                onPressed: _canSend ? _sendRequest : null,
                tooltip: 'Send request',
                icon: const Icon(Icons.arrow_upward_rounded),
              )
            : FilledButton.icon(
                key: ChatScreen.sendButtonKey,
                onPressed: _canSend ? _sendRequest : null,
                icon: const Icon(Icons.arrow_upward_rounded),
                label: Text(_isPending ? 'Sending' : 'Send'),
              ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        border: Border(top: BorderSide(color: AppColors.surfaceBlueStrong)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: largeText && !useCompactLayout
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[field, const SizedBox(height: 10), sendButton],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: field),
                const SizedBox(width: 10),
                sendButton,
              ],
            ),
    );
  }
}

class _AnimatedMessageBubble extends StatelessWidget {
  const _AnimatedMessageBubble({
    required this.message,
    required this.isNoResults,
    super.key,
  });

  final ChatMessage message;
  final bool isNoResults;

  @override
  Widget build(BuildContext context) {
    final bool fromUser = message.role == ChatRole.user;
    final BorderRadius borderRadius = fromUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(8),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(24),
          );
    final String semanticsPrefix = fromUser
        ? 'You said'
        : message.kind == ChatMessageKind.clarification
        ? 'Clarification'
        : 'Assistant said';

    return TweenAnimationBuilder<double>(
      duration: AppMotion.resolveDuration(
        context,
        duration: const Duration(milliseconds: 220),
      ),
      curve: AppMotion.standardCurve,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset:
                AppMotion.resolveTravel(context, const Offset(0, 8)) *
                (1 - value),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Semantics(
          key: isNoResults ? ChatScreen.noResultsKey : null,
          container: true,
          label: '$semanticsPrefix: ${message.text}',
          child: ExcludeSemantics(
            child: FractionallySizedBox(
              widthFactor: MediaQuery.textScalerOf(context).scale(1) >= 2
                  ? 0.96
                  : 0.84,
              alignment: fromUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: fromUser
                      ? AppColors.surfaceBlueStrong
                      : AppColors.surface,
                  borderRadius: borderRadius,
                  border: fromUser
                      ? null
                      : Border.all(color: AppColors.surfaceBlueStrong),
                ),
                child: Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
