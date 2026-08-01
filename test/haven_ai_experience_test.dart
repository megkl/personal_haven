import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/core/utils/assistant_command_text.dart';
import 'package:personal_haven/data/models/haven_chat_message.dart';
import 'package:personal_haven/data/models/haven_conversation.dart';
import 'package:personal_haven/presentation/screens/home/widgets/haven_ai_suggestions.dart';
import 'package:personal_haven/presentation/screens/home/widgets/haven_ai_shopping_command.dart';
import 'package:personal_haven/services/ai_assistant_service.dart';

void main() {
  testWidgets('Ask Haven starts with the four companion pathways', (
    tester,
  ) async {
    String? selectedPrompt;
    final companionSuggestions = havenAiQuickSuggestions
        .where(
          (suggestion) => const {
            'Reflect',
            'Organize',
            'Make a plan',
            'Get unstuck',
          }.contains(suggestion.label),
        )
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HavenAiSuggestionRail(
            prompts: const [],
            quickSuggestions: companionSuggestions,
            onPromptSelected: (prompt) => selectedPrompt = prompt,
          ),
        ),
      ),
    );

    expect(find.text('Reflect'), findsOneWidget);
    await tester.tap(find.text('Reflect'));
    expect(selectedPrompt, 'Help me understand what is on my mind');
    expect(companionSuggestions.map((suggestion) => suggestion.label), [
      'Reflect',
      'Organize',
      'Make a plan',
      'Get unstuck',
    ]);
  });

  test('chat history accepts only valid user and assistant records', () {
    final createdAt = DateTime.utc(2026, 7, 31, 10);
    final message = AiChatHistoryMessage.fromMap({
      'role': 'assistant',
      'content': '  Let us choose one small next step.  ',
      'createdAt': Timestamp.fromDate(createdAt),
    });

    expect(message?.text, 'Let us choose one small next step.');
    expect(message?.isUser, isFalse);
    expect(message?.createdAt?.toUtc(), createdAt);
    expect(
      AiChatHistoryMessage.fromMap({
        'role': 'system',
        'content': 'hidden instructions',
      }),
      isNull,
    );
    expect(
      AiChatHistoryMessage.fromMap({'role': 'user', 'content': '   '}),
      isNull,
    );
  });

  test('chat history hides incomplete AI turns', () {
    const orphan = AiChatHistoryMessage(
      text: 'hello',
      isUser: true,
      createdAt: null,
    );
    const user = AiChatHistoryMessage(
      text: 'Help me plan',
      isUser: true,
      createdAt: null,
    );
    const assistant = AiChatHistoryMessage(
      text: 'What are you planning for?',
      isUser: false,
      createdAt: null,
    );

    final complete = AiChatHistoryMessage.completeTurns([
      orphan,
      user,
      assistant,
    ]);

    expect(complete, [user, assistant]);
  });

  test('task commands remove greetings and polite request prefixes', () {
    expect(
      AssistantCommandText.removeConversationalPrefix(
        'Hi Haven, I would like to add a task - Testing out AI features',
      ),
      'add a task - Testing out AI features',
    );
    expect(
      AssistantCommandText.removeConversationalPrefix(
        'Haven AI: I want to create a goal',
      ),
      'create a goal',
    );
  });

  test('priority parsing recognizes negated priority answers', () {
    expect(AssistantCommandText.hasNegatedPriority('not high'), isTrue);
    expect(
      AssistantCommandText.hasNegatedPriority("it isn't very high priority"),
      isTrue,
    );
    expect(AssistantCommandText.hasNegatedPriority('high'), isFalse);
    expect(AssistantCommandText.hasNegatedPriority('not urgent'), isFalse);
  });

  test('named shopping list command separates its title and products', () {
    final command = HavenAiShoppingCommand.parse(
      'Create a shopping list named, August Month shopping list, with this '
      'items, rice 1kg, flour 2kg. Cooking oil 500g',
    );

    expect(command, isNotNull);
    expect(command!.listTitle, 'August Month shopping list');
    expect(command.items, hasLength(3));
    expect(
      command.items.map((item) => '${item.itemName}|${item.quantity}').toList(),
      ['Rice|1kg', 'Flour|2kg', 'Cooking oil|500g'],
    );
  });

  test('named list supports add with the following items', () {
    final command = HavenAiShoppingCommand.parse(
      'Add a shopping list named August with the following items, rice 2kg, '
      'flour 2kg, bread 1 piece, chocolate 400g bar',
    );

    expect(command, isNotNull);
    expect(command!.listTitle, 'August');
    expect(
      command.items.map((item) => '${item.itemName}|${item.quantity}').toList(),
      ['Rice|2kg', 'Flour|2kg', 'Bread|1 piece', 'Chocolate bar|400g'],
    );
  });

  test('conversation and message records preserve live metadata', () {
    final updatedAt = DateTime.utc(2026, 7, 31, 15, 30);
    final conversation = HavenConversation.fromMap('conversation-1', {
      'title': '  Plan my week  ',
      'createdAt': Timestamp.fromDate(updatedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': 'Start with Monday.',
      'messageCount': 2,
    });
    final message = HavenChatMessage.fromMap('message-1', {
      'content': '  Start with Monday. ',
      'role': 'assistant',
      'createdAt': Timestamp.fromDate(updatedAt),
      'status': 'failed',
    });

    expect(conversation.title, 'Plan my week');
    expect(conversation.messageCount, 2);
    expect(conversation.updatedAt?.toUtc(), updatedAt);
    expect(message.content, 'Start with Monday.');
    expect(message.isUser, isFalse);
    expect(message.status, HavenMessageStatus.failed);
    expect(message.createdAt?.toUtc(), updatedAt);
  });
}
