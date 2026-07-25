import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_spike/main.dart';

void main() {
  testWidgets('Chat page renders composer and empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatSpikeApp(systemPrompt: 'You are a test assistant.'));

    expect(find.text('Chat spike'), findsOneWidget);
    expect(find.text('Say something to start the conversation.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Message'), findsOneWidget);
  });
}
