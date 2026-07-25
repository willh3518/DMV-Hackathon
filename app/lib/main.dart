import 'package:flutter/material.dart';

import 'chat/chat_page.dart';
import 'chat/prompt_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final systemPrompt = await loadSystemPrompt();
  runApp(ChatSpikeApp(systemPrompt: systemPrompt));
}

class ChatSpikeApp extends StatelessWidget {
  const ChatSpikeApp({super.key, required this.systemPrompt});

  final String systemPrompt;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Spike',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: ChatPage(systemPrompt: systemPrompt),
    );
  }
}
