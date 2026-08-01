import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/utils/assistant_command_text.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/data/models/haven_chat_message.dart';
import 'package:personal_haven/data/models/haven_conversation.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/data/models/transaction.dart';
import 'package:personal_haven/providers/budget_provider.dart';
import 'package:personal_haven/providers/currency_provider.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:personal_haven/providers/food_provider.dart';
import 'package:personal_haven/providers/goal_provider.dart';
import 'package:personal_haven/providers/journal_provider.dart';
import 'package:personal_haven/providers/mood_provider.dart';
import 'package:personal_haven/providers/shopping_list_provider.dart';
import 'package:personal_haven/providers/task_provider.dart';
import 'package:personal_haven/presentation/screens/home/widgets/haven_ai_message_widgets.dart';
import 'package:personal_haven/presentation/screens/home/widgets/haven_ai_shopping_command.dart';
import 'package:personal_haven/presentation/screens/home/widgets/haven_ai_suggestions.dart';
import 'package:personal_haven/services/ai_assistant_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HavenAiChatSheet extends ConsumerStatefulWidget {
  const HavenAiChatSheet({super.key});

  @override
  ConsumerState<HavenAiChatSheet> createState() => _HavenAiChatSheetState();
}

class _HavenAiChatSheetState extends ConsumerState<HavenAiChatSheet> {
  static const _welcomeText =
      'Hi, I am Haven. I can help you make sense of what is on your mind, organize your ideas, build a realistic plan, or find your next small step. What would feel most useful right now?';

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiAssistantService = AiAssistantService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<HavenAiChatMessage> _messages = [];
  StreamSubscription<List<HavenConversation>>? _conversationSubscription;
  StreamSubscription<List<HavenChatMessage>>? _messageSubscription;
  List<HavenConversation> _conversations = const [];
  String? _conversationId;
  bool _isCreatingConversation = false;
  bool _didAttemptLegacyImport = false;
  bool _isLoadingHistory = true;
  bool _isWorking = false;
  bool _isListening = false;
  bool _speechReady = false;
  bool _voiceResultHandled = false;
  String _lastRecognizedAction = '';
  _AssistantDraft? _assistantDraft;
  _GuidedTaskDraft? _taskDraft;
  _GuidedActionDraft? _guidedDraft;
  List<String> _promptSuggestions = const [];
  String? _pendingConversationInput;

  @override
  void initState() {
    super.initState();
    _watchConversations();
  }

  void _watchConversations() {
    _conversationSubscription = _aiAssistantService.watchConversations().listen(
      (conversations) {
        if (!mounted) return;
        setState(() => _conversations = conversations);
        if (conversations.isEmpty) {
          final shouldImportLegacy = !_didAttemptLegacyImport;
          _didAttemptLegacyImport = true;
          unawaited(_createConversation(importLegacy: shouldImportLegacy));
          return;
        }
        final currentStillExists = conversations.any(
          (conversation) => conversation.id == _conversationId,
        );
        if (!currentStillExists) {
          _selectConversation(conversations.first.id);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isLoadingHistory = false;
          _messages
            ..clear()
            ..add(
              const HavenAiChatMessage(
                text: 'I could not load your conversations just now.',
                isUser: false,
              ),
            );
        });
      },
    );
  }

  Future<void> _createConversation({bool importLegacy = false}) async {
    if (_isCreatingConversation) return;
    _isCreatingConversation = true;
    try {
      final id = await _aiAssistantService.createConversation(
        importLegacy: importLegacy,
      );
      if (mounted) _selectConversation(id);
    } catch (_) {
      if (mounted) {
        _reply('I could not start a new conversation. Please try again.');
      }
    } finally {
      _isCreatingConversation = false;
    }
  }

  void _selectConversation(String conversationId) {
    if (_conversationId == conversationId && _messageSubscription != null) {
      return;
    }
    final previousSubscription = _messageSubscription;
    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }
    _conversationId = conversationId;
    _assistantDraft = null;
    _taskDraft = null;
    _guidedDraft = null;
    _pendingConversationInput = null;
    _promptSuggestions = const [];
    if (mounted) {
      setState(() {
        _isLoadingHistory = true;
        _isWorking = false;
        _messages.clear();
      });
    }
    _messageSubscription = _aiAssistantService
        .watchMessages(conversationId)
        .listen(
          (messages) {
            if (!mounted || _conversationId != conversationId) return;
            setState(() {
              _messages
                ..clear()
                ..addAll(
                  messages.isEmpty
                      ? const [
                          HavenAiChatMessage(text: _welcomeText, isUser: false),
                        ]
                      : messages.map(
                          (message) => HavenAiChatMessage(
                            text: message.content,
                            isUser: message.isUser,
                            createdAt: message.createdAt,
                            status: message.status,
                          ),
                        ),
                );
              _isLoadingHistory = false;
            });
            _scrollToBottom();
          },
          onError: (_) {
            if (!mounted || _conversationId != conversationId) return;
            setState(() {
              _isLoadingHistory = false;
              _messages
                ..clear()
                ..add(
                  const HavenAiChatMessage(
                    text: 'I could not load this conversation.',
                    isUser: false,
                  ),
                );
            });
          },
        );
  }

  @override
  void dispose() {
    final conversationSubscription = _conversationSubscription;
    final messageSubscription = _messageSubscription;
    if (conversationSubscription != null) {
      unawaited(conversationSubscription.cancel());
    }
    if (messageSubscription != null) {
      unawaited(messageSubscription.cancel());
    }
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceAction() async {
    if (_isWorking || _isLoadingHistory) return;

    if (_isListening) {
      await _finishVoiceAction(sendIfPossible: true);
      return;
    }

    _speechReady =
        _speechReady ||
        await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              Future.microtask(() => _finishVoiceAction(sendIfPossible: true));
            }
          },
          onError: (error) {
            if (!mounted) return;
            _voiceResultHandled = true;
            setState(() => _isListening = false);
            final message = error.errorMsg == 'error_permission'
                ? 'Microphone permission is needed for voice actions.'
                : 'I could not hear that clearly. Try the mic again.';
            _reply(message);
          },
        );

    if (!_speechReady) {
      _reply('Speech recognition is not available on this device.');
      return;
    }

    _lastRecognizedAction = '';
    _voiceResultHandled = false;
    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) async {
        _lastRecognizedAction = result.recognizedWords;
        if (mounted) {
          setState(() => _controller.text = _lastRecognizedAction);
        }
        if (result.finalResult && _lastRecognizedAction.trim().isNotEmpty) {
          await _finishVoiceAction(sendIfPossible: true);
        }
      },
    );
  }

  Future<void> _finishVoiceAction({required bool sendIfPossible}) async {
    if (_voiceResultHandled) return;
    final text = _lastRecognizedAction.trim();
    if (!sendIfPossible || text.isEmpty) {
      if (mounted) setState(() => _isListening = false);
      return;
    }

    _voiceResultHandled = true;
    await _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
    await _send(text);
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isWorking || _isLoadingHistory) return;
    final conversationId = _conversationId;
    if (conversationId == null) {
      await _createConversation();
      return;
    }

    _controller.clear();
    setState(() {
      _messages.add(
        HavenAiChatMessage(
          text: text,
          isUser: true,
          createdAt: DateTime.now(),
          status: HavenMessageStatus.sending,
        ),
      );
      _promptSuggestions = const [];
      _isWorking = true;
      _pendingConversationInput = text;
    });
    _scrollToBottom();

    if (_assistantDraft != null) {
      await _continueAssistantDraft(text);
      return;
    }
    if (_taskDraft != null) {
      await _continueTaskFlow(text);
      return;
    }
    if (_guidedDraft != null) {
      await _continueGuidedFlow(text);
      return;
    }

    final currencyCode =
        ref.read(currencyProvider).value ?? CurrencyFormatter.defaultCode;

    final structuredJournal = _structuredJournalInput(text);
    if (structuredJournal != null) {
      await _reviewStructuredJournal(structuredJournal);
      return;
    }

    final structuredShoppingCommand = HavenAiShoppingCommand.parse(text);
    if (structuredShoppingCommand?.hasMultipleItems == true) {
      await _reviewShoppingCommand(structuredShoppingCommand!);
      return;
    }

    AiAssistantResult? aiResult;
    try {
      aiResult = await _aiAssistantService.parseAction(text);
    } on AiAssistantLimitException catch (e) {
      _reply(e.message);
      return;
    }
    if (aiResult != null && aiResult.isConfident) {
      final handled = await _handleAiResult(aiResult, currencyCode);
      if (handled) return;
    }

    if (await _startAssistantDraftForRequest(text)) return;

    if (_startGuidedFlowForRequest(text)) return;

    final shoppingCommand = HavenAiShoppingCommand.parse(text);
    if (shoppingCommand != null) {
      await _reviewShoppingCommand(shoppingCommand);
      return;
    }

    final action = _HavenAction.parse(text);
    final command = action == null ? _PlannerCommand.parse(text) : null;
    if (command == null && action == null) {
      final result = await _aiAssistantService.chat(
        text,
        conversationId: conversationId,
      );
      _pendingConversationInput = null;
      if (result.persisted) {
        if (mounted) setState(() => _isWorking = false);
      } else {
        _reply(result.text ?? _helpReply(text), persist: false);
      }
      return;
    }

    try {
      if (command != null) {
        if (_shouldGuideTask(text, command)) {
          _startTaskFlow();
          return;
        }
        if (_shouldGuidePlannerCommand(text, command)) {
          _startGuidedFlow(_flowTypeForPlanner(command.type), title: null);
          return;
        }
        await _startAssistantDraft(
          _assistantDraftForPlannerCommand(command, currencyCode),
        );
      } else {
        if (_shouldGuideAction(text, action!)) {
          _startGuidedFlow(_flowTypeForAction(action.type), title: null);
          return;
        }
        if (action.type == _HavenActionType.summary) {
          _reply(_buildSummaryReply(currencyCode));
          return;
        }
        await _startAssistantDraft(_assistantDraftForHavenAction(action));
      }
    } catch (_) {
      _reply('I could not save that just now. Please try again.');
    }
  }

  bool _shouldGuideTask(String input, _PlannerCommand command) {
    if (command.type != _PlannerType.task) return false;
    final lower = input.toLowerCase().trim();
    return command.title == 'New task' ||
        RegExp(
          r'^(i\s+want\s+to\s+)?(add|create|make|set)\s+(a\s+)?(task|todo|reminder)$',
        ).hasMatch(lower) ||
        lower == 'task' ||
        lower == 'todo';
  }

  bool _shouldGuidePlannerCommand(String input, _PlannerCommand command) {
    final lower = input.toLowerCase().trim();
    if (command.type == _PlannerType.goal) {
      return command.title == 'New goal' ||
          RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|set)\s+(a\s+)?goal$',
          ).hasMatch(lower);
    }
    if (command.type == _PlannerType.event) {
      return command.title == 'New event' ||
          RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|schedule|plan)\s+(an?\s+)?(event|meeting|appointment)$',
          ).hasMatch(lower);
    }
    return false;
  }

  bool _shouldGuideAction(String input, _HavenAction action) {
    final lower = input.toLowerCase().trim();
    return switch (action.type) {
      _HavenActionType.mood => RegExp(
        r'^(log|add|record|track)?\s*(my\s+)?mood$',
      ).hasMatch(lower),
      _HavenActionType.food => RegExp(
        r'^(log|add|record|track)?\s*(food|meal|breakfast|lunch|dinner|snack)$',
      ).hasMatch(lower),
      _HavenActionType.journal => RegExp(
        r'^(write|add|create|save)?\s*(a\s+)?(journal|diary|reflection|note)$',
      ).hasMatch(lower),
      _HavenActionType.transaction => RegExp(
        r'^(log|add|record|track)?\s*(an?\s+)?(expense|income|transaction|spend)$',
      ).hasMatch(lower),
      _HavenActionType.summary => false,
    };
  }

  _GuidedFlowType _flowTypeForPlanner(_PlannerType type) {
    return switch (type) {
      _PlannerType.goal => _GuidedFlowType.goal,
      _PlannerType.event => _GuidedFlowType.event,
      _PlannerType.task => _GuidedFlowType.journal,
    };
  }

  _GuidedFlowType _flowTypeForAction(_HavenActionType type) {
    return switch (type) {
      _HavenActionType.mood => _GuidedFlowType.mood,
      _HavenActionType.food => _GuidedFlowType.food,
      _HavenActionType.journal => _GuidedFlowType.journal,
      _HavenActionType.transaction => _GuidedFlowType.transaction,
      _HavenActionType.summary => _GuidedFlowType.journal,
    };
  }

  bool _startGuidedFlowForRequest(String input) {
    final lower = input.toLowerCase().trim();
    final type = switch (lower) {
      final value
          when RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|set)\s+(a\s+)?goal$',
          ).hasMatch(value) =>
        _GuidedFlowType.goal,
      final value
          when RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|schedule|plan)\s+(an?\s+)?(event|meeting|appointment)$',
          ).hasMatch(value) =>
        _GuidedFlowType.event,
      final value
          when RegExp(
            r'^(log|add|record|track)?\s*(my\s+)?mood$',
          ).hasMatch(value) =>
        _GuidedFlowType.mood,
      final value
          when RegExp(
            r'^(log|add|record|track)?\s*(food|meal|breakfast|lunch|dinner|snack)$',
          ).hasMatch(value) =>
        _GuidedFlowType.food,
      final value
          when RegExp(
            r'^(write|add|create|save)?\s*(a\s+)?(journal|diary|reflection|note)$',
          ).hasMatch(value) =>
        _GuidedFlowType.journal,
      final value
          when RegExp(
            r'^(log|add|record|track)?\s*(an?\s+)?(expense|income|transaction|spend)$',
          ).hasMatch(value) =>
        _GuidedFlowType.transaction,
      final value
          when RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|make)?\s*(a\s+)?(shopping\s+)?(list|shopping item|grocery item)$',
          ).hasMatch(value) =>
        _GuidedFlowType.shopping,
      _ => null,
    };

    if (type == null) return false;
    _startGuidedFlow(type);
    return true;
  }

  Future<bool> _startAssistantDraftForRequest(String input) async {
    final lower = input.toLowerCase().trim();
    final intent = switch (lower) {
      final value
          when RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|make|set)\s+(a\s+)?(task|todo|reminder)$',
          ).hasMatch(value) =>
        'task',
      final value
          when RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|set)\s+(a\s+)?goal$',
          ).hasMatch(value) =>
        'goal',
      final value
          when RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|schedule|plan)\s+(an?\s+)?(event|meeting|appointment)$',
          ).hasMatch(value) =>
        'event',
      final value
          when RegExp(
            r'^(log|add|record|track)?\s*(my\s+)?mood$',
          ).hasMatch(value) =>
        'mood',
      final value
          when RegExp(
            r'^(log|add|record|track)?\s*(food|meal|breakfast|lunch|dinner|snack)$',
          ).hasMatch(value) =>
        'food',
      final value
          when RegExp(
            r'^(write|add|create|save)?\s*(a\s+)?(journal|diary|reflection|note)$',
          ).hasMatch(value) =>
        'journal',
      final value
          when RegExp(
            r'^(log|add|record|track)?\s*(an?\s+)?(expense|income|transaction|spend)$',
          ).hasMatch(value) =>
        'transaction',
      final value
          when RegExp(
            r'^(i\s+want\s+to\s+)?(add|create|make)?\s*(a\s+)?(shopping\s+)?(list|shopping item|grocery item)$',
          ).hasMatch(value) =>
        'shopping',
      _ => null,
    };
    if (intent == null) return false;
    await _startAssistantDraft(
      _AssistantDraft(intent: intent, fields: const {}),
      userInput: input,
    );
    return true;
  }

  Future<void> _startAssistantDraft(
    _AssistantDraft draft, {
    String? reply,
    String userInput = '',
  }) async {
    final normalized = draft.copyWith(
      missingFields: _missingFieldsForDraft(draft),
      suggestedPrompts: draft.suggestedPrompts.isEmpty
          ? _suggestionsForField(draft.intent, _firstMissingField(draft))
          : draft.suggestedPrompts,
    );
    _assistantDraft = normalized;
    final firstMissing = _firstMissingField(normalized);
    if (firstMissing == null) {
      _askToConfirmDraft(normalized, reply: reply);
      return;
    }
    await _replyForField(
      intent: normalized.intent,
      field: firstMissing,
      question: reply ?? _questionForField(normalized.intent, firstMissing),
      userInput: userInput,
      fields: normalized.fields,
      fallbackPrompts: normalized.suggestedPrompts,
    );
  }

  Future<void> _continueAssistantDraft(String input) async {
    var draft = _assistantDraft;
    if (draft == null) return;

    final lower = input.toLowerCase().trim();
    if (lower == 'cancel' || lower == 'stop') {
      _assistantDraft = null;
      _reply('No problem. I cancelled that draft.');
      return;
    }

    final edit = _parseDraftEdit(input);
    if (edit != null) {
      draft = draft.put(
        edit.$1,
        _normalizeDraftField(draft.intent, edit.$1, edit.$2),
      );
      _assistantDraft = draft;
      _askToConfirmDraft(draft, reply: 'Updated ${_labelForField(edit.$1)}.');
      return;
    }

    final changeField = _parseChangeFieldRequest(draft.intent, input);
    if (changeField != null) {
      draft = draft.copyWith(
        missingFields: [changeField],
        awaitingConfirmation: false,
      );
      _assistantDraft = draft;
      await _replyForField(
        intent: draft.intent,
        field: changeField,
        question: _questionForField(draft.intent, changeField),
        userInput: input,
        fields: draft.fields,
        fallbackPrompts: _suggestionsForField(draft.intent, changeField),
      );
      return;
    }

    if (_isConfirmation(input)) {
      await _saveAssistantDraft(draft);
      return;
    }

    if (_isNegativeConfirmation(input)) {
      _reply('What should I change?', prompts: _changePromptsForDraft(draft));
      return;
    }

    final missing = _firstMissingField(draft);
    if (missing != null) {
      draft = draft.put(
        missing,
        _normalizeDraftField(draft.intent, missing, input),
      );
      if (draft.intent == 'goal' && missing == 'targetValue') {
        draft = draft.put('unit', _parseTargetValue(input).$2);
      }
      draft = draft.copyWith(missingFields: _missingFieldsForDraft(draft));
      _assistantDraft = draft;
      final nextMissing = _firstMissingField(draft);
      if (nextMissing == null) {
        _askToConfirmDraft(draft);
      } else {
        await _replyForField(
          intent: draft.intent,
          field: nextMissing,
          question: _questionForField(draft.intent, nextMissing),
          userInput: input,
          fields: draft.fields,
          fallbackPrompts: _suggestionsForField(draft.intent, nextMissing),
        );
      }
      return;
    }

    _reply(
      'Should I save this?',
      prompts: const ['Save', 'Change something', 'Cancel'],
    );
  }

  (String, String)? _parseDraftEdit(String input) {
    final match = RegExp(
      r'^(?:change|make|set|update)\s+([a-zA-Z ]+?)\s+(?:to|as)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(input.trim());
    if (match == null) return null;
    final rawField = match.group(1)!.toLowerCase().trim();
    final field = switch (rawField) {
      'time' || 'date' || 'deadline' || 'due date' => 'dueDateText',
      'urgency' || 'priority' => 'priority',
      'amount' || 'target' => 'amount',
      'category' => 'category',
      'location' || 'place' => 'location',
      'title' || 'name' => 'title',
      'meal' || 'meal type' => 'mealType',
      'item' || 'shopping item' || 'grocery item' => 'itemName',
      'quantity' || 'count' => 'quantity',
      'mood' || 'feeling' => 'label',
      _ => rawField.replaceAll(' ', ''),
    };
    return (field, match.group(2)!.trim());
  }

  String? _parseChangeFieldRequest(String intent, String input) {
    final lower = input.toLowerCase().trim();
    if (!lower.startsWith('change ') && !lower.startsWith('edit ')) {
      return null;
    }
    if (lower.contains('time') ||
        lower.contains('date') ||
        lower.contains('deadline')) {
      if (intent == 'event') return 'dateText';
      if (intent == 'goal') return 'targetDateText';
      return 'dueDateText';
    }
    if (lower.contains('urgency') || lower.contains('priority')) {
      return 'priority';
    }
    if (lower.contains('amount')) return 'amount';
    if (lower.contains('target')) return 'targetValue';
    if (lower.contains('category')) return 'category';
    if (lower.contains('location') || lower.contains('place')) {
      return 'location';
    }
    if (lower.contains('title') || lower.contains('name')) return 'title';
    if (lower.contains('meal')) return 'mealType';
    if (lower.contains('food')) return 'foodName';
    if (lower.contains('item') || lower.contains('grocery')) return 'itemName';
    if (lower.contains('quantity') || lower.contains('count')) {
      return 'quantity';
    }
    if (lower.contains('mood') || lower.contains('feeling')) return 'label';
    return null;
  }

  bool _isConfirmation(String input) {
    final lower = input.toLowerCase().trim();
    return lower == 'yes' ||
        lower == 'save' ||
        lower == 'confirm' ||
        lower == 'looks good' ||
        lower == 'go ahead' ||
        lower == 'add it';
  }

  bool _isNegativeConfirmation(String input) {
    final lower = input.toLowerCase().trim();
    return lower == 'no' ||
        lower == 'change something' ||
        lower == 'edit' ||
        lower == 'not yet';
  }

  List<String> _missingFieldsForDraft(_AssistantDraft draft) {
    final required = switch (draft.intent) {
      'task' => ['title', 'priority', 'dueDateText'],
      'goal' => ['title', 'targetValue', 'targetDateText'],
      'event' => ['title', 'dateText'],
      'mood' => ['label'],
      'food' => ['mealType', 'foodName'],
      'journal' => ['title', 'content'],
      'transaction' => ['type', 'amount', 'category'],
      'shopping' => ['itemName'],
      _ => <String>[],
    };
    return required.where((field) => !_hasDraftField(draft, field)).toList();
  }

  bool _hasDraftField(_AssistantDraft draft, String field) {
    final value = draft.fields[field];
    if (value == null) return false;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower.isNotEmpty && lower != 'null';
    }
    return true;
  }

  String? _firstMissingField(_AssistantDraft draft) {
    final missing = draft.missingFields.isEmpty
        ? _missingFieldsForDraft(draft)
        : draft.missingFields;
    return missing.isEmpty ? null : missing.first;
  }

  String _questionForField(String intent, String field) {
    return switch ((intent, field)) {
      ('task', 'title') => 'What kind of task should I add?',
      ('task', 'priority') => 'How urgent is it?',
      ('task', 'dueDateText') => 'When should I remind you?',
      ('goal', 'title') => 'What goal are we setting?',
      ('goal', 'targetValue') => 'What target should I track?',
      ('goal', 'targetDateText') => 'When is the target date?',
      ('event', 'title') => 'What event should I schedule?',
      ('event', 'dateText') => 'When is it?',
      ('mood', 'label') => 'How are you feeling?',
      ('food', 'mealType') => 'Which meal is this for?',
      ('food', 'foodName') => 'What did you eat?',
      ('journal', 'title') => 'What title should this journal entry have?',
      ('journal', 'content') => 'What would you like to write down?',
      ('transaction', 'type') => 'Is this income or an expense?',
      ('transaction', 'amount') => 'How much was it?',
      ('transaction', 'category') => 'Which category?',
      ('shopping', 'itemName') => 'What should I add to your shopping list?',
      ('shopping', 'quantity') => 'How much do you need?',
      _ => 'Tell me a little more.',
    };
  }

  List<String> _suggestionsForField(String intent, String? field) {
    if (field == null) return const ['Save', 'Change something', 'Cancel'];
    return switch ((intent, field)) {
      ('task', 'title') => const ['Call Mum', 'Pay rent', 'Finish report'],
      ('task', 'priority') => const ['Urgent', 'High', 'Medium', 'Low'],
      ('task', 'dueDateText') => const [
        'Today',
        'Tomorrow',
        'Next week',
        'No deadline',
      ],
      ('goal', 'title') => const ['Save money', 'Read more', 'Workout weekly'],
      ('goal', 'targetValue') => const ['KES 10000', '10 books', '30 workouts'],
      ('goal', 'targetDateText') => const [
        'December 31',
        'Next month',
        'No deadline',
      ],
      ('event', 'title') => const [
        'Team meeting',
        'Doctor appointment',
        'Dinner',
      ],
      ('event', 'dateText') => const [
        'Today at 3 PM',
        'Tomorrow at 10 AM',
        'Friday',
      ],
      ('mood', 'label') => const ['Happy', 'Calm', 'Neutral', 'Stressed'],
      ('food', 'mealType') => const ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
      ('food', 'foodName') => const [
        'Oatmeal',
        'Chicken rice bowl',
        'Smoothie',
      ],
      ('journal', 'title') => const [
        'Today’s reflection',
        'A grateful moment',
        'New idea',
      ],
      ('journal', 'content') => const [
        'I felt proud today',
        'Something I am grateful for',
        'An idea I want to remember',
      ],
      ('transaction', 'type') => const ['Expense', 'Income'],
      ('transaction', 'amount') => const ['KES 500', '1000', '2500'],
      ('transaction', 'category') => const [
        'Food',
        'Transport',
        'Groceries',
        'Bills',
      ],
      ('shopping', 'itemName') => const ['Milk', 'Eggs', 'Bread', 'Coffee'],
      ('shopping', 'quantity') => const ['1 ct', '1 gal', '4 ct', 'Skip'],
      _ => const [],
    };
  }

  Object? _normalizeDraftField(String intent, String field, String input) {
    if (field == 'priority') return _priorityFromPrompt(input) ?? input;
    if (field == 'amount' || field == 'targetValue') {
      return _parseTargetValue(input).$1 ?? input;
    }
    if (field == 'unit') return _parseTargetValue(input).$2;
    if (field == 'type') {
      return input.toLowerCase().contains('income') ? 'income' : 'expense';
    }
    if (field == 'label') return _MoodIntent.fromText(input).label;
    if (field == 'category' && intent == 'transaction') {
      final type = _assistantDraft?.string('type') ?? 'expense';
      return _HavenAction._transactionCategoryFor(input, type);
    }
    if (field == 'category' && intent == 'journal') {
      return JournalCategories.getByName(input)?.name ??
          _journalCategoryFor(input);
    }
    if (field == 'mealType') return input.toLowerCase();
    if (field == 'quantity' && intent == 'shopping' && lowerSkip(input)) {
      return '';
    }
    return input.trim();
  }

  void _askToConfirmDraft(_AssistantDraft draft, {String? reply}) {
    _assistantDraft = draft.copyWith(
      missingFields: const [],
      awaitingConfirmation: true,
    );
    _reply(
      '${reply == null ? '' : '$reply '}${_confirmationTextForDraft(draft)}',
      prompts: const ['Save', 'Change something', 'Cancel'],
    );
  }

  String _confirmationTextForDraft(_AssistantDraft draft) {
    final fields = draft.fields;
    return switch (draft.intent) {
      'task' =>
        'I’ll add a ${fields['priority']} priority task: “${fields['title']}”${_dateSuffix(fields['dueDateText'])}. Save it?',
      'goal' =>
        'I’ll add the goal “${fields['title']}” with target ${fields['targetValue']} ${fields['unit'] ?? 'count'}${_dateSuffix(fields['targetDateText'])}. Save it?',
      'event' =>
        'I’ll schedule “${fields['title']}”${_dateSuffix(fields['dateText'])}${fields['location'] == null ? '' : ' at ${fields['location']}'}. Save it?',
      'mood' => 'I’ll log your mood as ${fields['label']}. Save it?',
      'food' =>
        'I’ll log ${fields['foodName']} for ${fields['mealType']}. Save it?',
      'journal' =>
        'I’ll save “${fields['title']}” as a journal entry. Save it?',
      'transaction' =>
        'I’ll log ${fields['amount']} as ${fields['type']} in ${fields['category']}. Save it?',
      'shopping' => _shoppingConfirmationText(fields),
      _ => 'Should I save this?',
    };
  }

  String _shoppingConfirmationText(Map<String, dynamic> fields) {
    final shoppingItems = _shoppingItemsFromFields(fields);
    if (shoppingItems.length > 1) {
      final preview = shoppingItems
          .take(3)
          .map((item) {
            final quantity = item.quantity.isEmpty ? '' : ' (${item.quantity})';
            return '${item.itemName}$quantity';
          })
          .join(', ');
      final more = shoppingItems.length > 3
          ? ', and ${shoppingItems.length - 3} more'
          : '';
      return 'I’ll add $preview$more to your shopping list. Save it?';
    }

    final quantity =
        fields['quantity'] == null || fields['quantity'].toString().isEmpty
        ? ''
        : ' (${fields['quantity']})';
    return 'I’ll add ${fields['itemName']}$quantity to your shopping list. Save it?';
  }

  String _dateSuffix(Object? value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    if (_isNoDeadline(value.toString())) return '';
    return ' for ${value.toString()}';
  }

  List<String> _changePromptsForDraft(_AssistantDraft draft) {
    return switch (draft.intent) {
      'task' => const ['Change time', 'Change urgency', 'Change title'],
      'goal' => const ['Change target', 'Change date', 'Change title'],
      'event' => const ['Change time', 'Change location', 'Change title'],
      'transaction' => const [
        'Change amount',
        'Change category',
        'Change type',
      ],
      'shopping' => const ['Change item', 'Change quantity', 'Cancel'],
      _ => const ['Change title', 'Cancel'],
    };
  }

  Future<void> _saveAssistantDraft(_AssistantDraft draft) async {
    final fields = draft.fields;
    try {
      switch (draft.intent) {
        case 'task':
          final dueDateText = fields['dueDateText']?.toString();
          final noDeadline = dueDateText == null || _isNoDeadline(dueDateText);
          final parsedDate = noDeadline
              ? (null, false, null)
              : _PlannerCommand._parseDateTime(dueDateText);
          await ref
              .read(taskProvider.notifier)
              .addTask(
                title: _HavenAction._capitalize(fields['title'].toString()),
                dueDate: parsedDate.$1,
                priority: fields['priority']?.toString() ?? 'medium',
                category: _PlannerCommand._category(
                  fields['title'].toString().toLowerCase(),
                  _PlannerType.task,
                ),
              );
          break;
        case 'goal':
          final dateText = fields['targetDateText']?.toString();
          final noDeadline = dateText == null || _isNoDeadline(dateText);
          final parsedDate = noDeadline
              ? (null, false, null)
              : _PlannerCommand._parseDateTime(dateText);
          await ref
              .read(goalProvider.notifier)
              .addGoal(
                title: _HavenAction._capitalize(fields['title'].toString()),
                targetValue:
                    (fields['targetValue'] as num?)?.toDouble() ??
                    double.tryParse(fields['targetValue'].toString()) ??
                    1,
                unit: fields['unit']?.toString() ?? 'count',
                targetDate: parsedDate.$1,
                category: _PlannerCommand._category(
                  fields['title'].toString().toLowerCase(),
                  _PlannerType.goal,
                ),
              );
          break;
        case 'event':
          final dateText = fields['dateText'].toString();
          final parsedDate = _PlannerCommand._parseDateTime(dateText);
          final eventDate = parsedDate.$1 ?? DateTime.now();
          await ref
              .read(eventProvider.notifier)
              .addEvent(
                title: _HavenAction._capitalize(fields['title'].toString()),
                eventDate: DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                ),
                startTime: parsedDate.$2 ? eventDate : null,
                isAllDay: !parsedDate.$2,
                location: fields['location']?.toString(),
                category: _PlannerCommand._category(
                  fields['title'].toString().toLowerCase(),
                  _PlannerType.event,
                ),
              );
          break;
        case 'mood':
          final mood = _MoodIntent.fromText(fields['label'].toString());
          await ref
              .read(moodProvider.notifier)
              .logMood(
                mood.level,
                mood.emoji,
                moodLabel: mood.label,
                notes: fields['notes']?.toString(),
              );
          break;
        case 'food':
          await ref
              .read(foodProvider.notifier)
              .addEntry(
                mealType: fields['mealType']?.toString() ?? 'snack',
                foodName: _HavenAction._capitalize(
                  fields['foodName'].toString(),
                ),
                calories: fields['calories'] is num
                    ? (fields['calories'] as num).toInt()
                    : int.tryParse(fields['calories']?.toString() ?? ''),
              );
          break;
        case 'journal':
          final inferredCategory =
              fields['category']?.toString() ??
              _journalCategoryFor(
                '${fields['title'] ?? ''} ${fields['content']}',
              );
          final journal = _cleanJournalFields(
            title: fields['title']?.toString(),
            content: fields['content'].toString(),
            category: inferredCategory,
          );
          final category =
              JournalCategories.getByName(journal.category ?? '') ??
              JournalCategories.getByName('Notes');
          await ref
              .read(journalProvider.notifier)
              .addEntry(
                title: _HavenAction._capitalize(journal.title),
                content: journal.content,
                category: category?.name ?? 'Notes',
                emoji: category?.emoji,
                tags: _HavenAction._tagsFor(journal.content),
              );
          break;
        case 'transaction':
          await ref
              .read(transactionProvider.notifier)
              .addTransaction(
                type: fields['type']?.toString() ?? 'expense',
                amount:
                    (fields['amount'] as num?)?.toDouble() ??
                    double.tryParse(fields['amount'].toString()) ??
                    0,
                category: fields['category']?.toString() ?? 'Other',
                description:
                    fields['description']?.toString() ??
                    fields['category']?.toString(),
              );
          break;
        case 'shopping':
          final shoppingItems = _shoppingItemsFromFields(fields);
          if (shoppingItems.length > 1) {
            for (final item in shoppingItems) {
              await ref
                  .read(shoppingListProvider.notifier)
                  .addItem(
                    listTitle: fields['listTitle']?.toString(),
                    name: item.itemName,
                    quantity: item.quantity,
                  );
            }
            break;
          }
          await ref
              .read(shoppingListProvider.notifier)
              .addItem(
                listTitle: fields['listTitle']?.toString(),
                name: fields['itemName'].toString(),
                quantity: fields['quantity']?.toString() ?? '',
              );
          break;
      }
      _assistantDraft = null;
      _reply('Done. I saved it.');
    } catch (_) {
      _reply('I could not save that just now. Please try again.');
    }
  }

  void _startTaskFlow() {
    _taskDraft = const _GuidedTaskDraft();
    _reply(
      'Sure. What kind of task should I add?',
      prompts: const ['Call Mum', 'Pay rent', 'Finish report'],
    );
  }

  void _startGuidedFlow(
    _GuidedFlowType type, {
    String? title,
    Map<String, dynamic> fields = const {},
  }) {
    _guidedDraft = _GuidedActionDraft(type: type, fields: {...fields});
    if (title != null && title.trim().isNotEmpty) {
      _guidedDraft = _guidedDraft!.put(
        'title',
        _HavenAction._capitalize(title),
      );
    }

    switch (type) {
      case _GuidedFlowType.goal:
        _reply(
          'Sure. What goal are we setting?',
          prompts: const ['Save money', 'Read more', 'Workout weekly'],
        );
        break;
      case _GuidedFlowType.event:
        _reply(
          'Sure. What event should I schedule?',
          prompts: const ['Team meeting', 'Doctor appointment', 'Dinner'],
        );
        break;
      case _GuidedFlowType.mood:
        _reply(
          'How are you feeling?',
          prompts: const ['Happy', 'Calm', 'Neutral', 'Stressed'],
        );
        break;
      case _GuidedFlowType.food:
        _reply(
          'Which meal is this for?',
          prompts: const ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
        );
        break;
      case _GuidedFlowType.journal:
        _reply(
          'What title should this journal entry have?',
          prompts: const [
            'Today’s reflection',
            'A grateful moment',
            'New idea',
          ],
        );
        break;
      case _GuidedFlowType.transaction:
        _reply(
          'Is this income or an expense?',
          prompts: const ['Expense', 'Income'],
        );
        break;
      case _GuidedFlowType.shopping:
        _reply(
          'What should I add to your shopping list?',
          prompts: const ['Milk', 'Eggs', 'Bread', 'Coffee'],
        );
        break;
    }
  }

  Future<void> _continueGuidedFlow(String input) async {
    final draft = _guidedDraft;
    if (draft == null) return;

    final lower = input.toLowerCase().trim();
    if (lower == 'cancel' || lower == 'stop') {
      _guidedDraft = null;
      _reply('No problem. I cancelled that draft.');
      return;
    }

    switch (draft.type) {
      case _GuidedFlowType.goal:
        await _continueGoalFlow(draft, input);
        break;
      case _GuidedFlowType.event:
        await _continueEventFlow(draft, input);
        break;
      case _GuidedFlowType.mood:
        await _continueMoodFlow(draft, input);
        break;
      case _GuidedFlowType.food:
        await _continueFoodFlow(draft, input);
        break;
      case _GuidedFlowType.journal:
        await _continueJournalFlow(draft, input);
        break;
      case _GuidedFlowType.transaction:
        await _continueTransactionFlow(draft, input);
        break;
      case _GuidedFlowType.shopping:
        await _continueShoppingFlow(draft, input);
        break;
    }
  }

  Future<void> _continueShoppingFlow(
    _GuidedActionDraft draft,
    String input,
  ) async {
    switch (draft.step) {
      case 0:
        _guidedDraft = draft
            .put('itemName', _HavenAction._capitalize(input))
            .next();
        _reply(
          'How much do you need?',
          prompts: const ['1 ct', '1 gal', '4 ct', 'Skip'],
        );
        break;
      default:
        final quantity = lowerSkip(input) ? '' : input.trim();
        _guidedDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'shopping',
            fields: {
              'itemName': draft.string('itemName'),
              'quantity': quantity,
            },
          ),
        );
    }
  }

  Future<void> _continueGoalFlow(_GuidedActionDraft draft, String input) async {
    switch (draft.step) {
      case 0:
        _guidedDraft = draft
            .put('title', _HavenAction._capitalize(input))
            .next();
        _reply(
          'What target should I track?',
          prompts: const ['KES 10000', '10 books', '30 workouts'],
        );
        break;
      case 1:
        final target = _parseTargetValue(input);
        if (target.$1 == null) {
          _reply(
            'Give me a number to track, like “KES 10000” or “10 books”.',
            prompts: const ['KES 10000', '10 books', '30 workouts'],
          );
          return;
        }
        _guidedDraft = draft
            .put('targetValue', target.$1)
            .put('unit', target.$2)
            .next();
        _reply(
          'When is the target date?',
          prompts: const ['December 31', 'Next month', 'No deadline'],
        );
        break;
      default:
        final noDeadline = _isNoDeadline(input);
        final parsedDate = noDeadline
            ? (null, false, null)
            : _PlannerCommand._parseDateTime(input);
        if (!noDeadline && parsedDate.$1 == null) {
          _reply(
            'Tell me a target date, or choose “No deadline”.',
            prompts: const ['December 31', 'Next month', 'No deadline'],
          );
          return;
        }
        _guidedDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'goal',
            fields: {
              'title': draft.string('title'),
              'targetValue': draft.doubleValue('targetValue'),
              'unit': draft.string('unit') ?? 'count',
              'targetDateText': noDeadline ? 'No deadline' : input.trim(),
            },
          ),
        );
    }
  }

  Future<void> _continueEventFlow(
    _GuidedActionDraft draft,
    String input,
  ) async {
    switch (draft.step) {
      case 0:
        _guidedDraft = draft
            .put('title', _HavenAction._capitalize(input))
            .next();
        _reply(
          'When is it?',
          prompts: const ['Today at 3 PM', 'Tomorrow at 10 AM', 'Friday'],
        );
        break;
      case 1:
        final parsedDate = _PlannerCommand._parseDateTime(input);
        if (parsedDate.$1 == null) {
          _reply(
            'I need a date or time for the event.',
            prompts: const ['Today at 3 PM', 'Tomorrow at 10 AM', 'Friday'],
          );
          return;
        }
        _guidedDraft = draft
            .put('dateTime', parsedDate.$1)
            .put('hasTime', parsedDate.$2)
            .put('dateText', input.trim())
            .next();
        _reply(
          'Where is it?',
          prompts: const ['Office', 'Home', 'Online', 'Skip location'],
        );
        break;
      default:
        final location = lowerSkip(input)
            ? null
            : _HavenAction._capitalize(input);
        _guidedDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'event',
            fields: {
              'title': draft.string('title'),
              'dateText': draft.string('dateText'),
              'location': location,
            },
          ),
        );
    }
  }

  Future<void> _continueMoodFlow(_GuidedActionDraft draft, String input) async {
    switch (draft.step) {
      case 0:
        final mood = _MoodIntent.fromText(input);
        _guidedDraft = draft
            .put('moodLabel', mood.label)
            .put('moodEmoji', mood.emoji)
            .put('moodLevel', mood.level)
            .next();
        _reply(
          'Want to add a note?',
          prompts: const ['Skip note', 'Slow morning', 'Feeling grateful'],
        );
        break;
      default:
        final notes = lowerSkip(input) ? null : input.trim();
        _guidedDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'mood',
            fields: {
              'label': draft.string('moodLabel') ?? 'Neutral',
              'notes': notes,
            },
          ),
        );
    }
  }

  Future<void> _continueFoodFlow(_GuidedActionDraft draft, String input) async {
    switch (draft.step) {
      case 0:
        _guidedDraft = draft.put('mealType', input.toLowerCase()).next();
        _reply(
          'What did you eat?',
          prompts: const ['Oatmeal', 'Chicken rice bowl', 'Fruit smoothie'],
        );
        break;
      case 1:
        _guidedDraft = draft
            .put('foodName', _HavenAction._capitalize(input))
            .next();
        _reply(
          'How many calories? You can skip this.',
          prompts: const ['Skip calories', '300', '500'],
        );
        break;
      default:
        final calories = lowerSkip(input) ? null : int.tryParse(input.trim());
        _guidedDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'food',
            fields: {
              'mealType': draft.string('mealType') ?? 'snack',
              'foodName': draft.string('foodName'),
              'calories': calories,
            },
          ),
        );
    }
  }

  Future<void> _continueJournalFlow(
    _GuidedActionDraft draft,
    String input,
  ) async {
    switch (draft.step) {
      case 0:
        _guidedDraft = draft
            .put('title', _HavenAction._capitalize(input))
            .next();
        _reply(
          'What would you like to write down?',
          prompts: const [
            'I felt proud today',
            'Something I am grateful for',
            'An idea I want to remember',
          ],
        );
        break;
      default:
        final content = input.trim();
        final title = draft.string('title')!;
        final category = _journalCategoryFor('$title $content');
        _guidedDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'journal',
            fields: {'title': title, 'content': content, 'category': category},
          ),
        );
    }
  }

  Future<void> _continueTransactionFlow(
    _GuidedActionDraft draft,
    String input,
  ) async {
    switch (draft.step) {
      case 0:
        final type = input.toLowerCase().contains('income')
            ? 'income'
            : 'expense';
        _guidedDraft = draft.put('transactionType', type).next();
        _reply('How much was it?', prompts: const ['KES 500', '1000', '2500']);
        break;
      case 1:
        final target = _parseTargetValue(input);
        if (target.$1 == null) {
          _reply(
            'Please enter an amount, like “KES 500”.',
            prompts: const ['KES 500', '1000', '2500'],
          );
          return;
        }
        _guidedDraft = draft.put('amount', target.$1).next();
        _reply(
          'Which category?',
          prompts: draft.string('transactionType') == 'income'
              ? const ['Salary', 'Freelance', 'Business', 'Other']
              : const ['Food', 'Transport', 'Groceries', 'Bills'],
        );
        break;
      default:
        final type = draft.string('transactionType') ?? 'expense';
        final category = _HavenAction._transactionCategoryFor(input, type);
        _guidedDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'transaction',
            fields: {
              'type': type,
              'amount': draft.doubleValue('amount'),
              'category': category,
            },
          ),
        );
    }
  }

  Future<void> _continueTaskFlow(String input) async {
    final draft = _taskDraft;
    if (draft == null) return;

    final lower = input.toLowerCase().trim();
    if (lower == 'cancel' || lower == 'stop') {
      _taskDraft = null;
      _reply('No problem. I cancelled that task draft.');
      return;
    }

    switch (draft.step) {
      case _TaskPromptStep.title:
        final title = _cleanTaskTitle(input);
        _taskDraft = draft.copyWith(
          title: title,
          step: _TaskPromptStep.priority,
        );
        _reply(
          'Got it: “$title”. How urgent is it?',
          prompts: const ['Urgent', 'High', 'Medium', 'Low'],
        );
        break;
      case _TaskPromptStep.priority:
        final priority = _priorityFromPrompt(input);
        if (priority == null) {
          if (AssistantCommandText.hasNegatedPriority(input)) {
            _reply(
              'Got it—not high. Would medium or low work better?',
              prompts: const ['Medium', 'Low'],
            );
            return;
          }
          _reply(
            'Choose an urgency: urgent, high, medium, or low.',
            prompts: const ['Urgent', 'High', 'Medium', 'Low'],
          );
          return;
        }
        _taskDraft = draft.copyWith(
          priority: priority,
          step: _TaskPromptStep.time,
        );
        _reply(
          'When should I remind you?',
          prompts: const ['Today', 'Tomorrow', 'Next week', 'No deadline'],
        );
        break;
      case _TaskPromptStep.time:
        final hasNoDeadline =
            lower.contains('no deadline') ||
            lower.contains('none') ||
            lower.contains('skip');
        final parsedTime = hasNoDeadline
            ? (null, false, null)
            : _PlannerCommand._parseDateTime(input);
        if (!hasNoDeadline && parsedTime.$1 == null) {
          _reply(
            'I need a time or date, or you can say “No deadline”.',
            prompts: const [
              'Today',
              'Tomorrow',
              'Friday at 5 PM',
              'No deadline',
            ],
          );
          return;
        }

        final completedDraft = draft.copyWith(
          dueDate: parsedTime.$1,
          hasTime: parsedTime.$2,
        );
        _taskDraft = null;
        _askToConfirmDraft(
          _AssistantDraft(
            intent: 'task',
            fields: {
              'title': completedDraft.title,
              'priority': completedDraft.priority ?? 'medium',
              'dueDateText': hasNoDeadline ? 'No deadline' : input.trim(),
            },
          ),
        );
        break;
    }
  }

  String _cleanTaskTitle(String input) {
    final parsed = _PlannerCommand.parse(input);
    final title = parsed?.type == _PlannerType.task
        ? parsed!.title
        : input.trim().replaceAll(RegExp(r'\s+'), ' ');
    return title.isEmpty ? 'New task' : title;
  }

  String? _priorityFromPrompt(String input) {
    final lower = input.toLowerCase();
    if (AssistantCommandText.hasNegatedPriority(lower)) return null;
    if (_isLowUrgency(lower)) return 'low';
    if (lower.contains('super urgent') ||
        lower.contains('very urgent') ||
        lower.contains('really urgent') ||
        lower.contains('urgent')) {
      return 'urgent';
    }
    if (lower.contains('high')) return 'high';
    if (lower.contains('medium') || lower.contains('normal')) return 'medium';
    if (lower.contains('low')) return 'low';
    return null;
  }

  bool _isLowUrgency(String lower) {
    return lower.contains('not urgent') ||
        lower.contains('not so urgent') ||
        lower.contains('not that urgent') ||
        lower.contains('no rush') ||
        lower.contains('can wait') ||
        lower.contains('whenever') ||
        lower.contains('later') ||
        lower.contains('low priority');
  }

  Future<bool> _handleAiResult(
    AiAssistantResult result,
    String currencyCode,
  ) async {
    if (result.intent == 'summary') {
      _reply(result.reply ?? _buildSummaryReply(currencyCode));
      return true;
    }
    if (result.intent == 'unknown') return false;

    final draft = _AssistantDraft(
      intent: result.intent,
      action: result.action,
      fields: _normalizedAiFields(result.intent, result.fields),
      missingFields: result.missingFields,
      suggestedPrompts: result.suggestedPrompts,
    );
    await _startAssistantDraft(draft, reply: result.reply);
    return true;
  }

  Future<void> _replyForField({
    required String intent,
    required String field,
    required String question,
    required String userInput,
    required Map<String, dynamic> fields,
    required List<String> fallbackPrompts,
  }) async {
    final prompts = await _smartPromptsForField(
      intent: intent,
      field: field,
      question: question,
      userInput: userInput,
      fields: fields,
      fallbackPrompts: fallbackPrompts,
    );
    _reply(question, prompts: prompts);
  }

  Future<List<String>> _smartPromptsForField({
    required String intent,
    required String field,
    required String question,
    required String userInput,
    required Map<String, dynamic> fields,
    required List<String> fallbackPrompts,
  }) async {
    final smartPrompts = await _aiAssistantService.generatePrompts(
      intent: intent,
      field: field,
      question: question,
      userInput: userInput,
      fields: fields,
      fallbackPrompts: fallbackPrompts,
    );
    if (smartPrompts == null || smartPrompts.isEmpty) return fallbackPrompts;

    final seen = <String>{};
    final prompts = smartPrompts
        .map((prompt) => prompt.trim())
        .where((prompt) => prompt.isNotEmpty && prompt.length <= 48)
        .where((prompt) => seen.add(prompt.toLowerCase()))
        .take(4)
        .toList(growable: false);

    return prompts.length >= 2 ? prompts : fallbackPrompts;
  }

  Map<String, dynamic> _normalizedAiFields(
    String intent,
    Map<String, dynamic> fields,
  ) {
    final normalized = <String, dynamic>{...fields};
    if (intent == 'task' && normalized['priority'] != null) {
      normalized['priority'] =
          _priorityFromPrompt(normalized['priority'].toString()) ??
          normalized['priority'];
    }
    if (intent == 'goal' && normalized['targetValue'] != null) {
      normalized['targetValue'] =
          (normalized['targetValue'] as num?)?.toDouble() ??
          double.tryParse(normalized['targetValue'].toString());
    }
    if (intent == 'transaction' && normalized['amount'] != null) {
      normalized['amount'] =
          (normalized['amount'] as num?)?.toDouble() ??
          double.tryParse(normalized['amount'].toString());
    }
    if (intent == 'journal') {
      final combined = [
        normalized['title']?.toString(),
        normalized['content']?.toString(),
      ].whereType<String>().join(' ');
      final structured = _structuredJournalInput(combined);
      if (structured != null) {
        normalized['title'] = structured.title;
        normalized['content'] = structured.content;
        normalized['category'] ??= structured.category;
      }
      final content = normalized['content']?.toString();
      if ((normalized['category'] == null ||
              normalized['category'].toString().trim().isEmpty) &&
          content != null &&
          content.trim().isNotEmpty) {
        normalized['category'] = _journalCategoryFor(
          '${normalized['title'] ?? ''} $content',
        );
      }
    }
    if (intent == 'shopping') {
      if (normalized['item'] != null && normalized['itemName'] == null) {
        normalized['itemName'] = normalized['item'];
      }
      if (normalized['items'] != null && normalized['shoppingItems'] == null) {
        normalized['shoppingItems'] = normalized['items'];
      }
      final shoppingItems = _shoppingItemsFromFields(normalized);
      if (shoppingItems.isNotEmpty) {
        normalized['shoppingItems'] = shoppingItems
            .map(
              (item) => {'itemName': item.itemName, 'quantity': item.quantity},
            )
            .toList(growable: false);
        normalized['itemName'] = shoppingItems.first.itemName;
        normalized['quantity'] = shoppingItems.first.quantity;
      }
      normalized['quantity'] = normalized['quantity']?.toString() ?? '';
    }
    return normalized;
  }

  List<HavenAiShoppingItem> _shoppingItemsFromFields(
    Map<String, dynamic> fields,
  ) {
    final rawItems = fields['shoppingItems'];
    if (rawItems is List) {
      return rawItems
          .map((raw) {
            if (raw is Map) {
              final itemName =
                  raw['itemName']?.toString() ?? raw['name']?.toString();
              if (itemName == null || itemName.trim().isEmpty) return null;
              return HavenAiShoppingItem(
                itemName: _HavenAction._capitalize(itemName.trim()),
                quantity:
                    raw['quantity']?.toString() ??
                    raw['amount']?.toString() ??
                    '',
              );
            }
            if (raw is String) {
              final parsedItems = HavenAiShoppingCommand.parseItems(raw);
              return parsedItems.isEmpty ? null : parsedItems.first;
            }
            return null;
          })
          .whereType<HavenAiShoppingItem>()
          .toList(growable: false);
    }

    final itemText =
        fields['itemName']?.toString() ?? fields['item']?.toString();
    if (itemText == null || itemText.trim().isEmpty) return const [];
    final parsedItems = HavenAiShoppingCommand.parseItems(itemText);
    if (parsedItems.length > 1) return parsedItems;
    return [
      HavenAiShoppingItem(
        itemName: _HavenAction._capitalize(itemText.trim()),
        quantity: fields['quantity']?.toString() ?? '',
      ),
    ];
  }

  String _labelForField(String field) {
    return field
        .replaceAll('dueDateText', 'time')
        .replaceAll('targetDateText', 'target date')
        .replaceAll('dateText', 'date')
        .replaceAll('mealType', 'meal')
        .replaceAll('foodName', 'food')
        .replaceAll('itemName', 'item')
        .replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2')
        .toLowerCase();
  }

  bool lowerSkip(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('skip') ||
        lower.contains('none') ||
        lower.contains('no ') ||
        lower == 'no';
  }

  bool _isNoDeadline(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('no deadline') ||
        lower.contains('none') ||
        lower.contains('skip');
  }

  (double?, String) _parseTargetValue(String input) {
    final match = RegExp(
      r'\b(?:(kes|ksh|usd|eur|gbp)\s*)?(\d+(?:[,.]\d+)?)(?:\s*(kes|ksh|usd|eur|gbp|kg|lbs|km|miles|minutes|mins|hours|hrs|books|pages|workouts|count|%))?\b',
      caseSensitive: false,
    ).firstMatch(input);
    if (match == null) return (null, 'count');
    final value = double.tryParse(match.group(2)!.replaceAll(',', ''));
    final unitToken = (match.group(1) ?? match.group(3))?.toLowerCase();
    return (value, _PlannerCommand._unitFor(unitToken) ?? 'count');
  }

  _AssistantDraft _assistantDraftForPlannerCommand(
    _PlannerCommand command,
    String currencyCode,
  ) {
    final dateText = command.dateTime == null
        ? null
        : DateFormat(
            command.hasTime ? 'MMMM d, yyyy at h:mm a' : 'MMMM d, yyyy',
          ).format(command.dateTime!);

    return switch (command.type) {
      _PlannerType.task => _AssistantDraft(
        intent: 'task',
        fields: {
          'title': command.title,
          'priority': command.priority ?? 'medium',
          'dueDateText': dateText ?? 'No deadline',
        },
      ),
      _PlannerType.goal => _AssistantDraft(
        intent: 'goal',
        fields: {
          'title': command.title,
          'targetValue': command.targetValue,
          'unit': command.unit ?? currencyCode,
          'targetDateText': dateText,
        },
      ),
      _PlannerType.event => _AssistantDraft(
        intent: 'event',
        fields: {
          'title': command.title,
          'dateText': dateText,
          'location': command.location,
        },
      ),
    };
  }

  Future<void> _reviewShoppingCommand(HavenAiShoppingCommand command) async {
    await _startAssistantDraft(
      _AssistantDraft(
        intent: 'shopping',
        fields: {
          'itemName': command.itemName,
          'quantity': command.quantity,
          'listTitle': command.listTitle,
          'shoppingItems': command.items
              .map(
                (item) => {
                  'itemName': item.itemName,
                  'quantity': item.quantity,
                },
              )
              .toList(growable: false),
        },
      ),
    );
  }

  _StructuredJournalInput? _structuredJournalInput(String input) {
    final lower = input.toLowerCase();
    final hasJournalLabels = _hasJournalLabels(input);
    if (!lower.contains('journal') && !hasJournalLabels) {
      return null;
    }

    final title = _labeledValue(input, ['title']);
    final content = _labeledValue(input, [
      'content',
      'description',
      'body',
      'entry',
      'note',
    ]);
    final category = _labeledValue(input, ['category']);
    if ((title == null || title.isEmpty) &&
        (content == null || content.isEmpty)) {
      return null;
    }

    return _cleanJournalFields(
      title: title,
      content: content ?? title!,
      category: category,
    );
  }

  bool _hasJournalLabels(String input) {
    return RegExp(
      r'(?:^|\s)(title|content|description|body|entry|note|category)\s*(?::|\s+)',
      caseSensitive: false,
    ).hasMatch(input);
  }

  String? _labeledValue(String input, List<String> labels) {
    final labelPattern = labels.map(RegExp.escape).join('|');
    final match = RegExp(
      '(?:^|\\s)($labelPattern)\\s*(?::\\s*|\\s+)(.+?)(?=\\s+(?:title|content|description|body|entry|note|category)\\s*(?::|\\s+)|\$)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(input);
    return match?.group(2)?.trim();
  }

  _StructuredJournalInput _cleanJournalFields({
    String? title,
    required String content,
    String? category,
  }) {
    final combined = [
      title,
      content,
      category == null || category.trim().isEmpty
          ? null
          : 'category: $category',
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    final labeledTitle = _labeledValue(combined, ['title']);
    final labeledContent = _labeledValue(combined, [
      'content',
      'description',
      'body',
      'entry',
      'note',
    ]);
    final labeledCategory = _labeledValue(combined, ['category']);

    final cleanContent = _stripJournalLabelPrefix(labeledContent ?? content, [
      'content',
      'description',
      'body',
      'entry',
      'note',
    ]);
    final fallbackTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : _HavenAction._journalTitleFor(cleanContent);
    final cleanTitle = _stripJournalLabelPrefix(labeledTitle ?? fallbackTitle, [
      'title',
    ]);
    final resolvedCategory =
        (labeledCategory ?? category)?.trim().isNotEmpty == true
        ? _stripJournalLabelPrefix(labeledCategory ?? category!, ['category'])
        : _journalCategoryFor('$cleanTitle $cleanContent');

    return _StructuredJournalInput(
      title: cleanTitle.isEmpty
          ? _HavenAction._journalTitleFor(cleanContent)
          : cleanTitle,
      content: cleanContent,
      category: resolvedCategory,
    );
  }

  String _stripJournalLabelPrefix(String value, List<String> labels) {
    final labelPattern = labels.map(RegExp.escape).join('|');
    return value
        .replaceFirst(
          RegExp('^\\s*(?:$labelPattern)\\s*:?\\s*', caseSensitive: false),
          '',
        )
        .trim();
  }

  Future<void> _reviewStructuredJournal(_StructuredJournalInput journal) async {
    final cleaned = _cleanJournalFields(
      title: journal.title,
      content: journal.content,
      category: journal.category,
    );
    final categoryName = cleaned.category?.trim().isNotEmpty == true
        ? cleaned.category!.trim()
        : _journalCategoryFor('${cleaned.title} ${cleaned.content}');
    await _startAssistantDraft(
      _AssistantDraft(
        intent: 'journal',
        fields: {
          'title': _HavenAction._capitalize(cleaned.title),
          'content': cleaned.content,
          'category': categoryName,
        },
      ),
    );
  }

  _AssistantDraft _assistantDraftForHavenAction(_HavenAction action) {
    return switch (action.type) {
      _HavenActionType.mood => _AssistantDraft(
        intent: 'mood',
        fields: {
          'label': (action.mood ?? _MoodIntent.fromText(action.title)).label,
          'notes': action.description,
        },
      ),
      _HavenActionType.food => _AssistantDraft(
        intent: 'food',
        fields: {
          'mealType': action.mealType ?? 'snack',
          'foodName': action.title,
          'calories': action.calories,
        },
      ),
      _HavenActionType.journal => _AssistantDraft(
        intent: 'journal',
        fields: {
          'title': action.title,
          'content': action.description ?? action.title,
          'category': action.category,
        },
      ),
      _HavenActionType.transaction => _AssistantDraft(
        intent: 'transaction',
        fields: {
          'type': action.transactionType ?? 'expense',
          'amount': action.amount,
          'category': action.category ?? 'Other',
          'description': action.description ?? action.title,
        },
      ),
      _HavenActionType.summary => throw StateError(
        'Summary actions do not create drafts.',
      ),
    };
  }

  void _reply(
    String text, {
    List<String> prompts = const [],
    bool persist = true,
  }) {
    if (!mounted) return;
    final userMessage = _pendingConversationInput;
    final conversationId = _conversationId;
    setState(() {
      _messages.add(HavenAiChatMessage(text: text, isUser: false));
      _promptSuggestions = prompts;
      _isWorking = false;
      _pendingConversationInput = null;
    });
    if (persist && userMessage != null && conversationId != null) {
      unawaited(
        _persistLocalExchange(
          conversationId: conversationId,
          userMessage: userMessage,
          assistantMessage: text,
        ),
      );
    }
    _scrollToBottom();
  }

  Future<void> _persistLocalExchange({
    required String conversationId,
    required String userMessage,
    required String assistantMessage,
  }) async {
    try {
      await _aiAssistantService.saveLocalExchange(
        conversationId: conversationId,
        userMessage: userMessage,
        assistantMessage: assistantMessage,
      );
    } catch (_) {
      if (!mounted || _conversationId != conversationId) return;
      final index = _messages.lastIndexWhere(
        (message) =>
            message.isUser &&
            message.text == userMessage &&
            message.status == HavenMessageStatus.sending,
      );
      if (index == -1) return;
      final failedMessage = _messages[index];
      setState(() {
        _messages[index] = HavenAiChatMessage(
          text: failedMessage.text,
          isUser: true,
          createdAt: failedMessage.createdAt,
          status: HavenMessageStatus.failed,
        );
      });
    }
  }

  String _helpReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('help') ||
        lower.contains('what can') ||
        lower.contains('how do')) {
      return 'You can ask me to add tasks, goals, events, shopping items, moods, meals, journal entries, income, and expenses. Try “Pay rent Friday”, “Add milk to shopping list”, “Log mood calm”, “Spent KES 500 on groceries”, or “Journal: I felt proud today”.';
    }

    return 'I can help add tasks, goals, events, shopping items, moods, meals, journal entries, income, and expenses. Try “remind me to…”, “add eggs to shopping list”, “log mood…”, “spent…”, “ate…”, or “journal: …”.';
  }

  String _buildSummaryReply(String currencyCode) {
    final tasks = ref.read(taskProvider);
    final goals = ref.read(goalProvider);
    final events = ref.read(eventProvider);
    final transactions = ref.read(transactionProvider);
    final food = ref.read(foodProvider);
    final mood = ref.read(moodProvider).todayMood;

    final balance = CurrencyFormatter.format(
      transactions.balance,
      currencyCode,
    );
    final moodText = mood == null
        ? 'No mood logged today yet.'
        : 'Today mood: ${mood.moodLabel ?? 'Mood'} ${mood.moodEmoji}.';

    return [
      'Here is today at a glance:',
      '${tasks.pendingCount} pending tasks, ${tasks.todayTasks.length} due today.',
      '${events.todayCount} events today, ${goals.activeCount} active goals.',
      '$moodText Food: ${food.todayCalories} calories logged.',
      'Month balance: $balance.',
    ].join('\n');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Scaffold(
            backgroundColor: context.colors.cardColor,
            drawer: _buildConversationDrawer(),
            body: Column(
              children: [
                _buildHeader(),
                _buildHero(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    itemCount:
                        _messages.length +
                        (_isWorking || _isLoadingHistory ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const HavenAiTypingBubble();
                      }
                      return HavenAiMessageBubble(message: _messages[index]);
                    },
                  ),
                ),
                _buildComposer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationDrawer() {
    return Drawer(
      backgroundColor: context.colors.cardColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your conversations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close history',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: _isCreatingConversation
                    ? null
                    : () {
                        Navigator.pop(context);
                        unawaited(_createConversation());
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New conversation'),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _conversations.isEmpty
                  ? Center(
                      child: Text(
                        'Your conversations will appear here.',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                      itemCount: _conversations.length,
                      itemBuilder: (drawerContext, index) {
                        final conversation = _conversations[index];
                        final selected = conversation.id == _conversationId;
                        return Card(
                          elevation: 0,
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.11)
                              : Colors.transparent,
                          child: ListTile(
                            selected: selected,
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: selected
                                  ? AppColors.primaryDark
                                  : context.colors.textSecondary,
                            ),
                            title: Text(
                              conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _conversationSubtitle(conversation),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(drawerContext);
                              _selectConversation(conversation.id);
                            },
                            trailing: PopupMenuButton<_ConversationMenuAction>(
                              tooltip: 'Conversation options',
                              onSelected: (action) {
                                switch (action) {
                                  case _ConversationMenuAction.rename:
                                    unawaited(
                                      _renameConversation(conversation),
                                    );
                                    break;
                                  case _ConversationMenuAction.delete:
                                    unawaited(
                                      _deleteConversation(conversation),
                                    );
                                    break;
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: _ConversationMenuAction.rename,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Rename'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _ConversationMenuAction.delete,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.delete_outline_rounded),
                                    title: Text('Delete'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _conversationSubtitle(HavenConversation conversation) {
    final lastMessage = conversation.lastMessage?.trim();
    if (lastMessage?.isNotEmpty == true) return lastMessage!;
    final updatedAt = conversation.updatedAt;
    if (updatedAt != null) {
      return DateFormat('MMM d, h:mm a').format(updatedAt);
    }
    return conversation.messageCount == 0 ? 'Start a new thought' : 'Ask Haven';
  }

  Future<void> _renameConversation(HavenConversation conversation) async {
    final controller = TextEditingController(text: conversation.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Conversation title'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || title == conversation.title) return;
    try {
      await _aiAssistantService.renameConversation(conversation.id, title);
    } catch (_) {
      _reply('I could not rename that conversation. Please try again.');
    }
  }

  Future<void> _deleteConversation(HavenConversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          '“${conversation.title}” and its messages will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _aiAssistantService.deleteConversation(conversation.id);
    } catch (_) {
      _reply('I could not delete that conversation. Please try again.');
    }
  }

  Widget _buildHeader() {
    String? selectedTitle;
    for (final conversation in _conversations) {
      if (conversation.id == _conversationId) {
        selectedTitle = conversation.title;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          Builder(
            builder: (headerContext) => IconButton(
              tooltip: 'Conversation history',
              onPressed: () => Scaffold.of(headerContext).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Ask Haven',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  selectedTitle ?? 'Reflect • organize • grow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close assistant',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A calmer place to think',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Share what is on your mind. We will find clarity and a useful next step.',
                  style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          border: Border(top: BorderSide(color: context.colors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HavenAiSuggestionRail(
              prompts: _promptSuggestions,
              onPromptSelected: _send,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoadingHistory,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Listening… speak naturally'
                            : 'Share a thought or ask Haven...',
                        filled: true,
                        fillColor: context.colors.cardColor2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _isListening
                        ? 'Stop voice request'
                        : 'Ask Haven by voice',
                    onPressed: _isWorking || _isLoadingHistory
                        ? null
                        : _toggleVoiceAction,
                    style: IconButton.styleFrom(
                      backgroundColor: _isListening
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : context.colors.cardColor2,
                      foregroundColor: _isListening
                          ? AppColors.primaryDark
                          : context.colors.textSecondary,
                    ),
                    icon: Icon(
                      _isListening
                          ? Icons.graphic_eq_rounded
                          : Icons.mic_none_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _isWorking || _isLoadingHistory ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.45,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'AI can make mistakes. Review details before saving actions.',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 10.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _PlannerType { task, goal, event }

enum _ConversationMenuAction { rename, delete }

enum _TaskPromptStep { title, priority, time }

enum _GuidedFlowType { goal, event, mood, food, journal, transaction, shopping }

class _GuidedTaskDraft {
  final _TaskPromptStep step;
  final String? title;
  final String? priority;
  final DateTime? dueDate;
  final bool hasTime;

  const _GuidedTaskDraft({
    this.step = _TaskPromptStep.title,
    this.title,
    this.priority,
    this.dueDate,
    this.hasTime = false,
  });

  _GuidedTaskDraft copyWith({
    _TaskPromptStep? step,
    String? title,
    String? priority,
    DateTime? dueDate,
    bool? hasTime,
  }) {
    return _GuidedTaskDraft(
      step: step ?? this.step,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
    );
  }
}

class _GuidedActionDraft {
  final _GuidedFlowType type;
  final int step;
  final Map<String, dynamic> fields;

  const _GuidedActionDraft({
    required this.type,
    this.step = 0,
    this.fields = const {},
  });

  _GuidedActionDraft put(String key, Object? value) {
    return _GuidedActionDraft(
      type: type,
      step: step,
      fields: {...fields, key: value},
    );
  }

  _GuidedActionDraft next() {
    return _GuidedActionDraft(type: type, step: step + 1, fields: fields);
  }

  String? string(String key) {
    final value = fields[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  double? doubleValue(String key) {
    final value = fields[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? intValue(String key) {
    final value = fields[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool boolValue(String key) {
    final value = fields[key];
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  DateTime? date(String key) {
    final value = fields[key];
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class _AssistantDraft {
  final String intent;
  final String action;
  final Map<String, dynamic> fields;
  final List<String> missingFields;
  final List<String> suggestedPrompts;
  final bool awaitingConfirmation;

  const _AssistantDraft({
    required this.intent,
    this.action = 'create',
    this.fields = const {},
    this.missingFields = const [],
    this.suggestedPrompts = const [],
    this.awaitingConfirmation = false,
  });

  _AssistantDraft copyWith({
    String? intent,
    String? action,
    Map<String, dynamic>? fields,
    List<String>? missingFields,
    List<String>? suggestedPrompts,
    bool? awaitingConfirmation,
  }) {
    return _AssistantDraft(
      intent: intent ?? this.intent,
      action: action ?? this.action,
      fields: fields ?? this.fields,
      missingFields: missingFields ?? this.missingFields,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      awaitingConfirmation: awaitingConfirmation ?? this.awaitingConfirmation,
    );
  }

  _AssistantDraft put(String key, Object? value) {
    return copyWith(
      fields: {...fields, key: value},
      awaitingConfirmation: false,
    );
  }

  String? string(String key) {
    final value = fields[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
  }
}

class _StructuredJournalInput {
  const _StructuredJournalInput({
    required this.title,
    required this.content,
    this.category,
  });

  final String title;
  final String content;
  final String? category;
}

class _PlannerCommand {
  final _PlannerType type;
  final String title;
  final String? description;
  final DateTime? dateTime;
  final DateTime? endTime;
  final bool hasTime;
  final String? priority;
  final String? category;
  final double? targetValue;
  final String? unit;
  final String? location;

  const _PlannerCommand({
    required this.type,
    required this.title,
    this.description,
    this.dateTime,
    this.endTime,
    this.hasTime = false,
    this.priority,
    this.category,
    this.targetValue,
    this.unit,
    this.location,
  });

  String get successMessage {
    final when = dateTime == null
        ? ''
        : hasTime
        ? ' for ${DateFormat('EEE, MMM d at h:mm a').format(dateTime!)}'
        : ' for ${DateFormat('EEE, MMM d').format(dateTime!)}';
    final noun = switch (type) {
      _PlannerType.task => 'task',
      _PlannerType.goal => 'goal',
      _PlannerType.event => 'event',
    };
    return 'Done. I added the $noun “$title”$when.';
  }

  static _PlannerCommand? parse(String input) {
    final normalized = _normalize(input);
    final lower = normalized.toLowerCase();
    final type = _typeFor(lower);
    if (type == null) return null;

    final dateResult = _parseDateTime(normalized);
    final description = _extractDescription(normalized);
    final location = type == _PlannerType.event
        ? _extractLocation(normalized)
        : null;
    final targetMatch = type == _PlannerType.goal
        ? RegExp(
            r'\b(?:(kes|ksh|usd|eur|gbp)\s*)?(\d+(?:[,.]\d+)?)(?:\s*(kes|ksh|usd|eur|gbp|kg|lbs|km|miles|minutes|mins|hours|hrs|books|pages|count|%))?\b',
            caseSensitive: false,
          ).firstMatch(normalized)
        : null;
    final target = targetMatch != null
        ? double.tryParse(targetMatch.group(2)!.replaceAll(',', ''))
        : null;
    final unitToken = (targetMatch?.group(1) ?? targetMatch?.group(3))
        ?.toLowerCase();
    final unit = _unitFor(unitToken);

    var title = _stripCommandPrefix(normalized, type);
    title = _removePlanningDetails(title).trim();
    title = _removeExtractedDetail(title, description);
    title = _removeExtractedDetail(title, location);
    if (type == _PlannerType.goal && targetMatch != null) {
      title = title
          .replaceFirst(targetMatch.group(0)!, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    title = title.replaceAll(RegExp(r'^[\s:,-]+|[\s,.-]+$'), '');

    if (title.isEmpty) {
      title = switch (type) {
        _PlannerType.task => 'New task',
        _PlannerType.goal => 'New goal',
        _PlannerType.event => 'New event',
      };
    } else if (type == _PlannerType.goal) {
      title = switch (title.toLowerCase()) {
        'save' => 'Save money',
        'read' => 'Read books',
        _ => title,
      };
    }
    title = title[0].toUpperCase() + title.substring(1);

    return _PlannerCommand(
      type: type,
      title: title,
      description: description,
      dateTime: dateResult.$1,
      endTime: dateResult.$3,
      hasTime: dateResult.$2,
      priority: _priority(lower),
      category: _category(lower, type),
      targetValue: target,
      unit: unit,
      location: location,
    );
  }

  static _PlannerType? _typeFor(String lower) {
    if (lower.contains('goal') ||
        lower.startsWith('save ') ||
        lower.startsWith('track ') ||
        lower.startsWith('build a habit') ||
        lower.startsWith('i want to save') ||
        lower.startsWith('i want to read')) {
      return _PlannerType.goal;
    }
    if (lower.contains('event') ||
        lower.contains('schedule') ||
        lower.contains('appointment') ||
        lower.contains('meeting') ||
        lower.contains('catch-up') ||
        lower.contains('catch up') ||
        lower.startsWith('lunch ') ||
        lower.startsWith('dinner ') ||
        lower.startsWith('coffee ')) {
      return _PlannerType.event;
    }
    if (lower.contains('task') ||
        lower.contains('todo') ||
        lower.startsWith('remind me') ||
        lower.startsWith('remember to') ||
        lower.startsWith('i need to') ||
        lower.startsWith('i have to') ||
        lower.startsWith('need to') ||
        lower.startsWith('call ') ||
        lower.startsWith('pay ') ||
        lower.startsWith('buy ') ||
        lower.startsWith('email ') ||
        lower.startsWith('finish ')) {
      return _PlannerType.task;
    }
    if (_parseDateTime(lower).$1 != null) return _PlannerType.task;
    return null;
  }

  static String _normalize(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
  }

  static String? _unitFor(String? unitToken) {
    if (unitToken == null) return null;
    if (unitToken == 'ksh') return 'KES';
    if (CurrencyFormatter.isCurrencyUnit(unitToken)) {
      return unitToken.toUpperCase();
    }
    return switch (unitToken) {
      'books' || 'pages' => 'count',
      'mins' => 'minutes',
      'hrs' => 'hours',
      _ => unitToken,
    };
  }

  static String _stripCommandPrefix(String input, _PlannerType type) {
    var title = AssistantCommandText.removeConversationalPrefix(input)
        .replaceFirst(
          RegExp(
            r'^(can you\s+)?(please\s+)?(add|create|make|set|schedule|plan|track)\s+(a|an|the)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(task|goal|event|todo|appointment|meeting)\s*(to|for|:)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(remind me to|remember to|i need to|i have to|need to|i want to)\s+',
            caseSensitive: false,
          ),
          '',
        );

    if (type == _PlannerType.goal) {
      title = title.replaceFirst(
        RegExp(r'^(goal\s+)?to\s+', caseSensitive: false),
        '',
      );
    }
    return title;
  }

  static String? _extractDescription(String input) {
    final match = RegExp(
      r'\b(?:note|notes|details|description)\s*:\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(input);
    return match?.group(1)?.trim();
  }

  static String? _extractLocation(String input) {
    final matches = RegExp(
      r'\b(?:at|in)\s+([a-z][a-z0-9 &,\-]+?)(?=\s+(?:today|tomorrow|on|by|from|at\s+\d|in\s+\d|next|this)\b|$)',
      caseSensitive: false,
    ).allMatches(input).toList();
    if (matches.isEmpty) return null;

    final value = matches.last.group(1)?.trim();
    if (value == null || RegExp(r'^\d').hasMatch(value)) return null;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _removeExtractedDetail(String title, String? detail) {
    if (detail == null || detail.isEmpty) return title;
    return title
        .replaceFirst(RegExp(RegExp.escape(detail), caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'\b(?:at|in|note|notes|details|description)\s*:?\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static (DateTime?, bool, DateTime?) _parseDateTime(String input) {
    final lower = input.toLowerCase();
    final now = DateTime.now();
    DateTime? date;

    final relativeMatch = RegExp(
      r'\bin\s+(\d+)\s+(minute|minutes|min|mins|hour|hours|hr|hrs|day|days|week|weeks)\b',
    ).firstMatch(lower);
    if (relativeMatch != null) {
      final amount = int.parse(relativeMatch.group(1)!);
      final unit = relativeMatch.group(2)!;
      final duration = switch (unit) {
        'minute' || 'minutes' || 'min' || 'mins' => Duration(minutes: amount),
        'hour' || 'hours' || 'hr' || 'hrs' => Duration(hours: amount),
        'week' || 'weeks' => Duration(days: amount * 7),
        _ => Duration(days: amount),
      };
      final relativeDate = now.add(duration);
      return (
        DateTime(
          relativeDate.year,
          relativeDate.month,
          relativeDate.day,
          relativeDate.hour,
          relativeDate.minute,
        ),
        unit.contains('hour') || unit.contains('min'),
        null,
      );
    }

    if (lower.contains('tomorrow')) {
      date = DateTime(now.year, now.month, now.day + 1);
    } else if (lower.contains('today') || lower.contains('tonight')) {
      date = DateTime(now.year, now.month, now.day);
    } else if (lower.contains('next week')) {
      date = DateTime(now.year, now.month, now.day + 7);
    } else {
      const weekdays = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };
      for (final entry in weekdays.entries) {
        if (!lower.contains(entry.key)) continue;
        var days = (entry.value - now.weekday) % 7;
        if (days == 0 || lower.contains('next ${entry.key}')) days += 7;
        date = DateTime(now.year, now.month, now.day + days);
        break;
      }
    }

    final numericDate = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
    ).firstMatch(lower);
    if (numericDate != null) {
      var year = int.tryParse(numericDate.group(3) ?? '') ?? now.year;
      if (year < 100) year += 2000;
      date = DateTime(
        year,
        int.parse(numericDate.group(2)!),
        int.parse(numericDate.group(1)!),
      );
    }

    const months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    for (final entry in months.entries) {
      if (!lower.contains(entry.key)) continue;
      final monthMatch = RegExp(
        '(?:on|by|before|until)?\\s*${entry.key}\\s*(\\d{1,2})?(?:st|nd|rd|th)?(?:,?\\s*(\\d{4}))?',
      ).firstMatch(lower);
      var year = int.tryParse(monthMatch?.group(2) ?? '') ?? now.year;
      final day = int.tryParse(monthMatch?.group(1) ?? '');
      if (year == now.year && entry.value < now.month) year++;
      date = day == null
          ? DateTime(year, entry.value + 1, 0)
          : DateTime(year, entry.value, day);
      break;
    }

    final timeMatch = RegExp(
      r'\b(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    ).firstMatch(lower);
    final twentyFourHour = RegExp(
      r'\bat\s+([01]?\d|2[0-3]):([0-5]\d)\b',
    ).firstMatch(lower);
    final rangeMatch = RegExp(
      r'\bfrom\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s+(?:to|-)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
      caseSensitive: false,
    ).firstMatch(lower);

    var hasTime = false;
    var hour = 0;
    var minute = 0;
    DateTime? endTime;
    if (rangeMatch != null) {
      final start = _clockParts(
        rangeMatch.group(1)!,
        rangeMatch.group(2),
        rangeMatch.group(3) ?? rangeMatch.group(6),
      );
      final end = _clockParts(
        rangeMatch.group(4)!,
        rangeMatch.group(5),
        rangeMatch.group(6) ?? rangeMatch.group(3),
      );
      hour = start.$1;
      minute = start.$2;
      hasTime = true;
      final base = date ?? DateTime(now.year, now.month, now.day);
      endTime = DateTime(base.year, base.month, base.day, end.$1, end.$2);
    } else if (timeMatch != null) {
      final parsed = _clockParts(
        timeMatch.group(1)!,
        timeMatch.group(2),
        timeMatch.group(3),
      );
      hour = parsed.$1;
      minute = parsed.$2;
      hasTime = true;
    } else if (twentyFourHour != null) {
      hour = int.parse(twentyFourHour.group(1)!);
      minute = int.parse(twentyFourHour.group(2)!);
      hasTime = true;
    }

    if (date == null && hasTime) {
      date = DateTime(now.year, now.month, now.day);
      final candidate = DateTime(date.year, date.month, date.day, hour, minute);
      if (candidate.isBefore(now)) {
        date = date.add(const Duration(days: 1));
      }
    }
    if (date != null && hasTime) {
      date = DateTime(date.year, date.month, date.day, hour, minute);
      if (endTime != null) {
        endTime = DateTime(
          date.year,
          date.month,
          date.day,
          endTime.hour,
          endTime.minute,
        );
        if (endTime.isBefore(date)) {
          endTime = endTime.add(const Duration(days: 1));
        }
      }
    }

    return (date, hasTime, endTime);
  }

  static (int, int) _clockParts(
    String hourValue,
    String? minuteValue,
    String? periodValue,
  ) {
    var hour = int.parse(hourValue);
    final minute = int.tryParse(minuteValue ?? '') ?? 0;
    final period = periodValue?.toLowerCase();
    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;
    return (hour, minute);
  }

  static String _removePlanningDetails(String value) {
    return value
        .replaceAll(
          RegExp(
            r'\b(today|tonight|tomorrow|next week|this week|next)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\b(next|this)\s+week\b', caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'\b(?:on|by|before|until)?\s*(january|february|march|april|may|june|july|august|september|october|november|december)(?:\s+\d{1,2})?(?:st|nd|rd|th)?(?:,?\s+\d{4})?\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\bin\s+\d+\s+(minutes?|mins?|hours?|hrs?|days?|weeks?)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\b\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?\b'), '')
        .replaceAll(
          RegExp(
            r'\bfrom\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?\s+(?:to|-)\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(?:at\s*)?\d{1,2}(?::\d{2})?\s*(?:am|pm)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\bat\s+\d{1,2}:\d{2}\b'), '')
        .replaceAll(RegExp(r'\bby\b', caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'\b(urgent|high|medium|low)(?:\s+priority)?\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\s,.-]+$'), '');
  }

  static String _priority(String value) {
    if (_isLowUrgency(value)) return 'low';
    if (AssistantCommandText.hasNegatedPriority(value)) return 'medium';
    if (value.contains('urgent')) return 'urgent';
    if (value.contains('high priority')) return 'high';
    if (value.contains('low priority')) return 'low';
    return 'medium';
  }

  static bool _isLowUrgency(String value) {
    return value.contains('not urgent') ||
        value.contains('not so urgent') ||
        value.contains('not that urgent') ||
        value.contains('no rush') ||
        value.contains('can wait') ||
        value.contains('whenever') ||
        value.contains('later') ||
        value.contains('low priority');
  }

  static String _category(String value, _PlannerType type) {
    if (value.contains('work') || value.contains('meeting')) return 'work';
    if (value.contains('money') ||
        value.contains('save') ||
        value.contains('finance')) {
      return 'finance';
    }
    if (value.contains('fitness') ||
        value.contains('workout') ||
        value.contains('health')) {
      return switch (type) {
        _PlannerType.task => 'wellness',
        _PlannerType.goal => 'fitness',
        _PlannerType.event => 'health',
      };
    }
    if (value.contains('learn') ||
        value.contains('read') ||
        value.contains('study')) {
      return type == _PlannerType.task ? 'personal' : 'learning';
    }
    return 'personal';
  }
}

enum _HavenActionType { mood, food, journal, transaction, summary }

class _HavenAction {
  final _HavenActionType type;
  final String title;
  final String? description;
  final DateTime? dateTime;
  final String? category;
  final List<String> tags;
  final _MoodIntent? mood;
  final String? mealType;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final String? transactionType;
  final double? amount;

  const _HavenAction({
    required this.type,
    required this.title,
    this.description,
    this.dateTime,
    this.category,
    this.tags = const [],
    this.mood,
    this.mealType,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.transactionType,
    this.amount,
  });

  static _HavenAction? parse(String input) {
    final normalized = _PlannerCommand._normalize(input);
    final lower = normalized.toLowerCase();

    if (_isSummaryRequest(lower)) {
      return const _HavenAction(
        type: _HavenActionType.summary,
        title: 'Summary',
      );
    }

    if (_isMoodRequest(lower)) return _parseMood(normalized);
    if (_isFoodRequest(lower)) return _parseFood(normalized);
    if (_isJournalRequest(lower)) return _parseJournal(normalized);
    if (_isTransactionRequest(lower)) return _parseTransaction(normalized);

    return null;
  }

  static bool _isSummaryRequest(String lower) {
    return lower.contains('summary') ||
        lower.contains('today at a glance') ||
        lower.contains('how am i doing') ||
        lower.contains('what is on today') ||
        lower.contains("what's on today") ||
        lower.contains('show my day') ||
        lower.contains('daily check');
  }

  static bool _isMoodRequest(String lower) {
    return lower.contains('mood') ||
        lower.startsWith('i feel ') ||
        lower.startsWith('feeling ') ||
        lower.startsWith('log feeling ');
  }

  static bool _isFoodRequest(String lower) {
    return lower.contains('calories') ||
        lower.contains('protein') ||
        lower.startsWith('ate ') ||
        lower.startsWith('had ') ||
        lower.startsWith('log breakfast') ||
        lower.startsWith('log lunch') ||
        lower.startsWith('log dinner') ||
        lower.startsWith('log snack') ||
        lower.startsWith('add breakfast') ||
        lower.startsWith('add lunch') ||
        lower.startsWith('add dinner') ||
        lower.startsWith('add snack');
  }

  static bool _isJournalRequest(String lower) {
    return lower.startsWith('journal') ||
        lower.startsWith('write journal') ||
        lower.startsWith('add journal') ||
        lower.startsWith('diary') ||
        lower.startsWith('note to self') ||
        lower.startsWith('reflection');
  }

  static bool _isTransactionRequest(String lower) {
    return lower.startsWith('spent ') ||
        lower.startsWith('paid ') ||
        lower.startsWith('bought ') ||
        lower.startsWith('earned ') ||
        lower.startsWith('received ') ||
        lower.startsWith('income ') ||
        lower.startsWith('expense ') ||
        lower.contains(' add income') ||
        lower.contains(' add expense') ||
        RegExp(
          r'\b(spend|expense|income|salary|freelance|refund)\b',
        ).hasMatch(lower);
  }

  static _HavenAction _parseMood(String input) {
    var value = input
        .replaceFirst(
          RegExp(
            r'^(please\s+)?(log|add|record|track)?\s*(my\s+)?mood\s*(as|:)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(r'^(i feel|feeling|log feeling)\s+', caseSensitive: false),
          '',
        )
        .trim();
    final notes = _PlannerCommand._extractDescription(value);
    value = _withoutDetail(value, notes);
    final mood = _MoodIntent.fromText(value);

    return _HavenAction(
      type: _HavenActionType.mood,
      title: mood.label,
      description: notes,
      mood: mood,
    );
  }

  static _HavenAction _parseFood(String input) {
    final dateResult = _PlannerCommand._parseDateTime(input);
    final mealType = _mealTypeFor(input);
    final calories = _intBefore(input, ['calorie', 'calories', 'cal']);
    final protein = _intBefore(input, ['protein', 'g protein']);
    final carbs = _intBefore(input, ['carbs', 'carbohydrates']);
    final fat = _intBefore(input, ['fat']);
    final notes = _PlannerCommand._extractDescription(input);

    var title = input
        .replaceFirst(
          RegExp(
            r'^(please\s+)?(log|add|record|track)?\s*(breakfast|lunch|dinner|snack|meal)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(RegExp(r'^(ate|had)\s+', caseSensitive: false), '')
        .trim();
    title = _removeNutrition(title);
    title = _withoutDetail(title, notes);
    title = _stripTrailingConnectors(title);
    if (title.isEmpty) title = 'Food entry';

    return _HavenAction(
      type: _HavenActionType.food,
      title: _capitalize(title),
      description: notes,
      dateTime: dateResult.$1,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  static _HavenAction _parseJournal(String input) {
    final dateResult = _PlannerCommand._parseDateTime(input);
    var content = input
        .replaceFirst(
          RegExp(
            r'^(please\s+)?(write|add|create|save)?\s*(a\s+)?(journal entry|journal|diary|reflection|note to self)\s*(entry)?\s*(about|:)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    content = _PlannerCommand._removePlanningDetails(content).trim();
    final labeledTitle = _labeledText(content, ['title']);
    final labeledContent = _labeledText(content, [
      'content',
      'description',
      'body',
      'entry',
      'note',
    ]);
    final labeledCategory = _labeledText(content, ['category']);
    if (labeledTitle != null || labeledContent != null) {
      content = labeledContent ?? labeledTitle ?? content;
    }
    if (content.isEmpty) content = 'Journal entry';

    final category = labeledCategory ?? _journalCategoryFor(content);
    final tags = _tagsFor(content);
    final title = labeledTitle ?? _journalTitleFor(content);

    return _HavenAction(
      type: _HavenActionType.journal,
      title: title,
      description: content,
      dateTime: dateResult.$1,
      category: category,
      tags: tags,
    );
  }

  static String? _labeledText(String input, List<String> labels) {
    final labelPattern = labels.map(RegExp.escape).join('|');
    final match = RegExp(
      '(?:^|\\s)($labelPattern)\\s*(?::\\s*|\\s+)(.+?)(?=\\s+(?:title|content|description|body|entry|note|category)\\s*(?::|\\s+)|\$)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(input);
    return match?.group(2)?.trim();
  }

  static _HavenAction? _parseTransaction(String input) {
    final dateResult = _PlannerCommand._parseDateTime(input);
    final lower = input.toLowerCase();
    final type =
        lower.contains('earned') ||
            lower.contains('received') ||
            lower.contains('income') ||
            lower.contains('salary') ||
            lower.contains('freelance') ||
            lower.contains('refund')
        ? 'income'
        : 'expense';
    final amountMatch = RegExp(
      r'\b(?:(kes|ksh|usd|eur|gbp)\s*)?(\d+(?:[,.]\d+)?)(?:\s*(kes|ksh|usd|eur|gbp))?\b',
      caseSensitive: false,
    ).firstMatch(input);
    final amount = amountMatch == null
        ? null
        : double.tryParse(amountMatch.group(2)!.replaceAll(',', ''));
    if (amount == null) return null;
    final amountText = amountMatch!.group(0)!;

    final category = _transactionCategoryFor(input, type);
    final notes = _PlannerCommand._extractDescription(input);
    var description = input
        .replaceFirst(
          RegExp(
            r'^(please\s+)?(log|add|record|track)?\s*(an?\s+)?(income|expense)?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(spent|paid|bought|earned|received)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(amountText, '')
        .trim();
    description = description
        .replaceFirst(RegExp(r'^(on|for|from)\s+', caseSensitive: false), '')
        .trim();
    description = _PlannerCommand._removePlanningDetails(description).trim();
    description = _withoutDetail(description, notes);
    if (description.isEmpty) description = category;

    return _HavenAction(
      type: _HavenActionType.transaction,
      title: _capitalize(description),
      description: notes ?? _capitalize(description),
      dateTime: dateResult.$1,
      category: category,
      transactionType: type,
      amount: amount,
    );
  }

  static String? _mealTypeFor(String value) {
    final lower = value.toLowerCase();
    for (final meal in ['breakfast', 'lunch', 'dinner', 'snack']) {
      if (lower.contains(meal)) return meal;
    }
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 21) return 'dinner';
    return 'snack';
  }

  static int? _intBefore(String input, List<String> labels) {
    for (final label in labels) {
      final match = RegExp(
        '(\\d+)\\s*(?:g\\s*)?${RegExp.escape(label)}\\b',
        caseSensitive: false,
      ).firstMatch(input);
      if (match != null) return int.tryParse(match.group(1)!);
    }
    return null;
  }

  static String _removeNutrition(String value) {
    return value
        .replaceAll(
          RegExp(
            r'\b\d+\s*(?:g\s*)?(calories|cal|protein|carbs|carbohydrates|fat)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _transactionCategoryFor(String input, String type) {
    final lower = input.toLowerCase();
    final categories = type == 'income'
        ? TransactionCategories.incomeCategories
        : TransactionCategories.expenseCategories;
    for (final category in categories) {
      if (lower.contains(category.name.toLowerCase())) return category.name;
    }
    if (type == 'income') {
      if (lower.contains('salary')) return 'Salary';
      if (lower.contains('freelance')) return 'Freelance';
      if (lower.contains('refund')) return 'Refund';
      if (lower.contains('gift')) return 'Gift';
      return 'Other';
    }
    if (lower.contains('grocery') || lower.contains('groceries')) {
      return 'Groceries';
    }
    if (lower.contains('rent')) return 'Rent';
    if (lower.contains('uber') ||
        lower.contains('taxi') ||
        lower.contains('bus')) {
      return 'Transport';
    }
    if (lower.contains('food') ||
        lower.contains('lunch') ||
        lower.contains('dinner')) {
      return 'Food';
    }
    if (lower.contains('bill') ||
        lower.contains('electric') ||
        lower.contains('water')) {
      return 'Bills';
    }
    return 'Other';
  }

  static List<String> _tagsFor(String value) {
    final lower = value.toLowerCase();
    final tags = <String>[];
    for (final tag in [
      'gratitude',
      'work',
      'health',
      'goals',
      'ideas',
      'dreams',
      'personal',
    ]) {
      if (lower.contains(tag)) tags.add(tag);
    }
    return tags;
  }

  static String _journalTitleFor(String content) {
    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'Journal entry';
    final title = words.take(6).join(' ');
    return _capitalize(title.length < content.length ? '$title...' : title);
  }

  static String _withoutDetail(String value, String? detail) {
    if (detail == null || detail.isEmpty) return value;
    return value
        .replaceFirst(RegExp(RegExp.escape(detail), caseSensitive: false), '')
        .replaceAll(
          RegExp(
            r'\b(note|notes|details|description)\s*:?\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _stripTrailingConnectors(String value) {
    return value
        .replaceAll(
          RegExp(r'\b(with|and|for|note|notes)\s*:?\s*$', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[\s,.-]+$'), '')
        .trim();
  }

  static String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

class _MoodIntent {
  final String label;
  final String emoji;
  final int level;

  const _MoodIntent({
    required this.label,
    required this.emoji,
    required this.level,
  });

  static _MoodIntent fromText(String input) {
    final lower = input.toLowerCase();
    for (final option in MoodOptions.all) {
      if (input.contains(option.emoji) ||
          lower.contains(option.label.toLowerCase())) {
        return _MoodIntent(
          label: option.label,
          emoji: option.emoji,
          level: option.level,
        );
      }
    }
    if (lower.contains('good') ||
        lower.contains('great') ||
        lower.contains('proud')) {
      return const _MoodIntent(label: 'Happy', emoji: '😊', level: 5);
    }
    if (lower.contains('okay') || lower.contains('fine')) {
      return const _MoodIntent(label: 'Neutral', emoji: '😐', level: 3);
    }
    if (lower.contains('worried') || lower.contains('nervous')) {
      return const _MoodIntent(label: 'Anxious', emoji: '😰', level: 2);
    }
    if (lower.contains('exhausted') || lower.contains('sleepy')) {
      return const _MoodIntent(label: 'Tired', emoji: '😴', level: 2);
    }
    return const _MoodIntent(label: 'Neutral', emoji: '😐', level: 3);
  }
}

String _journalCategoryFor(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('grateful') ||
      lower.contains('gratitude') ||
      lower.contains('thank')) {
    return 'Gratitude';
  }
  if (lower.contains('goal') || lower.contains('progress')) return 'Goals';
  if (lower.contains('health') ||
      lower.contains('workout') ||
      lower.contains('mood')) {
    return 'Health';
  }
  if (lower.contains('work') || lower.contains('meeting')) return 'Work';
  if (lower.contains('idea') ||
      lower.contains('invent') ||
      lower.contains('build')) {
    return 'Ideas';
  }
  if (lower.contains('dream')) return 'Dreams';
  if (lower.contains('personal') || lower.contains('family')) return 'Personal';
  return 'Notes';
}
