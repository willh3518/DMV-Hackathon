import 'package:flutter/material.dart';

import 'chat_message.dart';
import 'openai_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.systemPrompt});

  final String systemPrompt;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _service = OpenAiService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];

  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, content: text));
      _inputController.clear();
      _isSending = true;
      _error = null;
    });
    _scrollToEnd();

    try {
      final reply = await _service.sendMessage(text, systemPrompt: widget.systemPrompt);
      setState(() {
        _messages.add(ChatMessage(role: ChatRole.assistant, content: reply));
      });
    } on OpenAiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _isSending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat spike'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'OpenAI · gpt-4o',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Say something to start the conversation.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(alignment: Alignment.centerLeft, child: Text('Waiting for reply…')),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Type a message…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        tooltip: 'Send message',
                        onPressed: _isSending ? null : _send,
                        icon: const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${isUser ? 'You' : 'Assistant'} said',
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'You' : 'Assistant',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(message.content),
            ],
          ),
        ),
      ),
    );
  }
}
