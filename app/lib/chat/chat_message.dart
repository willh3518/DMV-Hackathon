enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final ChatRole role;
  final String content;

  String get apiRole => role == ChatRole.user ? 'user' : 'assistant';

  Map<String, String> toApiJson() => {'role': apiRole, 'content': content};
}
