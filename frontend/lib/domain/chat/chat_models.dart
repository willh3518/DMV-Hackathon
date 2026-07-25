enum ChatRole { user, assistant }

enum ChatMessageKind { standard, clarification }

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.kind,
    required this.text,
  });

  final String id;
  final ChatRole role;
  final ChatMessageKind kind;
  final String text;
}

final class ChatSuggestedPrompt {
  const ChatSuggestedPrompt({
    required this.id,
    required this.label,
    required this.requestText,
  });

  final String id;
  final String label;
  final String requestText;
}

final class ChatLocationSummary {
  const ChatLocationSummary({required this.label});

  final String label;
}

final class DiscoveryRequest {
  const DiscoveryRequest({required this.text, this.conversationId});

  final String text;
  final String? conversationId;
}

abstract interface class DiscoveryResultsPayload {
  int get resultCount;
  String get announcementLabel;
}

sealed class DiscoveryResult {
  const DiscoveryResult();
}

final class DiscoveryClarification extends DiscoveryResult {
  const DiscoveryClarification({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final String message;
}

final class DiscoveryResults extends DiscoveryResult {
  const DiscoveryResults({
    required this.conversationId,
    required this.message,
    required this.payload,
  });

  final String conversationId;
  final String message;
  final DiscoveryResultsPayload payload;
}

final class DiscoveryNoResults extends DiscoveryResult {
  const DiscoveryNoResults({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final String message;
}

enum DiscoveryFailureReason {
  networkUnavailable(
    userMessage: 'We could not connect. Check your connection and try again.',
    canRetry: true,
  ),
  locationUnavailable(
    userMessage: 'Choose a location before searching nearby.',
    canRetry: false,
  ),
  serviceUnavailable(
    userMessage: 'Place search is temporarily unavailable. Try again.',
    canRetry: true,
  ),
  sessionExpired(
    userMessage: 'Your session ended. Sign in again to continue.',
    canRetry: false,
  );

  const DiscoveryFailureReason({
    required this.userMessage,
    required this.canRetry,
  });

  final String userMessage;
  final bool canRetry;
}

final class DiscoveryFailure extends DiscoveryResult {
  const DiscoveryFailure({required this.reason});

  final DiscoveryFailureReason reason;
}
