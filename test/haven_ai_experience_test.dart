import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/core/utils/assistant_command_text.dart';
import 'package:personal_haven/presentation/screens/home/widgets/haven_ai_suggestions.dart';
import 'package:personal_haven/services/ai_assistant_service.dart';

void main() {
  testWidgets('Ask Haven starts with the four companion pathways', (
    tester,
  ) async {
    String? selectedPrompt;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HavenAiSuggestionRail(
            prompts: const [],
            onPromptSelected: (prompt) => selectedPrompt = prompt,
          ),
        ),
      ),
    );

    expect(find.text('Reflect'), findsOneWidget);
    await tester.tap(find.text('Reflect'));
    expect(selectedPrompt, 'Help me understand what is on my mind');
    expect(
      havenAiQuickSuggestions.take(4).map((suggestion) => suggestion.label),
      ['Reflect', 'Organize', 'Make a plan', 'Get unstuck'],
    );
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
}
