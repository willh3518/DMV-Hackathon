enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final ChatRole role;
  final String content;
}
