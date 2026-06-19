import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:personal_haven/providers/currency_provider.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:personal_haven/providers/goal_provider.dart';
import 'package:personal_haven/providers/task_provider.dart';

class HavenAiChatSheet extends ConsumerStatefulWidget {
  const HavenAiChatSheet({super.key});

  @override
  ConsumerState<HavenAiChatSheet> createState() => _HavenAiChatSheetState();
}

class _HavenAiChatSheetState extends ConsumerState<HavenAiChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hi, I am Haven. Tell me what you want to plan and I can add a task, goal, or event for you.',
      isUser: false,
    ),
  ];
  bool _isWorking = false;

  static const _suggestions = [
    ('Add task', Icons.task_alt, 'Call Mum tomorrow at 6 PM'),
    ('Set goal', Icons.flag_outlined, 'Save KES 10000 by December 31'),
    (
      'Plan event',
      Icons.calendar_month_outlined,
      'Team catch-up Friday at 10 AM at the office',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isWorking) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isWorking = true;
    });
    _scrollToBottom();

    final command = _PlannerCommand.parse(text);
    final currencyCode =
        ref.read(currencyProvider).value ?? CurrencyFormatter.defaultCode;
    if (command == null) {
      _reply(_helpReply(text));
      return;
    }

    try {
      switch (command.type) {
        case _PlannerType.task:
          await ref
              .read(taskProvider.notifier)
              .addTask(
                title: command.title,
                description: command.description,
                dueDate: command.dateTime,
                priority: command.priority ?? 'medium',
                category: command.category ?? 'personal',
              );
          break;
        case _PlannerType.goal:
          await ref
              .read(goalProvider.notifier)
              .addGoal(
                title: command.title,
                description: command.description,
                targetValue: command.targetValue ?? 1,
                unit: command.unit ?? currencyCode,
                targetDate: command.dateTime,
                category: command.category ?? 'personal',
              );
          break;
        case _PlannerType.event:
          final eventDate = command.dateTime ?? DateTime.now();
          await ref
              .read(eventProvider.notifier)
              .addEvent(
                title: command.title,
                eventDate: DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                ),
                startTime: command.hasTime ? eventDate : null,
                endTime: command.endTime,
                isAllDay: !command.hasTime,
                location: command.location,
                category: command.category ?? 'personal',
              );
          break;
      }

      _reply(command.successMessage);
    } catch (_) {
      _reply('I could not save that just now. Please try again.');
    }
  }

  void _reply(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
      _isWorking = false;
    });
    _scrollToBottom();
  }

  String _helpReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('help') ||
        lower.contains('what can') ||
        lower.contains('how do')) {
      return 'You can ask me to add tasks, goals, and events. Try “Pay rent Friday”, “Save KES 10000 by December 31”, or “Dinner with Amina tomorrow at 7 PM at Java”.';
    }

    return 'I can help add a task, goal, or event. Try “remind me to…”, “create a goal to…”, or “schedule…”.';
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildHero(),
              _buildSuggestions(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  itemCount: _messages.length + (_isWorking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const _TypingBubble();
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
              ),
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close assistant',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Haven Assistant',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Private planning companion',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
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
                  'What can we make easier?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Describe it naturally. I will organize the details.',
                  style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, icon, prompt) = _suggestions[index];
          return ActionChip(
            onPressed: () => _send(prompt),
            avatar: Icon(icon, size: 17, color: AppColors.primaryDark),
            label: Text(label),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            labelStyle: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          border: Border(top: BorderSide(color: context.colors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask Haven to add something...',
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
            IconButton.filled(
              tooltip: 'Send',
              onPressed: _isWorking ? null : _send,
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : context.colors.cardColor2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : context.colors.textPrimary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.cardColor2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

enum _PlannerType { task, goal, event }

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
    var title = input
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
    if (value.contains('urgent')) return 'urgent';
    if (value.contains('high priority')) return 'high';
    if (value.contains('low priority')) return 'low';
    return 'medium';
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
