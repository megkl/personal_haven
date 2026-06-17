import 'package:equatable/equatable.dart';

/// Event model for calendar events
class Event extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? location;
  final String category; // 'personal', 'work', 'health', 'social', 'reminder'
  final String? color; // Hex color code
  final bool isRecurring;
  final String? recurrenceRule; // 'daily', 'weekly', 'monthly', 'yearly'
  final String? reminder; // '5min', '15min', '30min', '1hour', '1day'
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.location,
    this.category = 'personal',
    this.color,
    this.isRecurring = false,
    this.recurrenceRule,
    this.reminder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  /// Check if event is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return eventDate.isAfter(now) && eventDate.isBefore(weekFromNow);
  }

  /// Check if event has passed
  bool get isPast {
    final now = DateTime.now();
    if (endTime != null) {
      return endTime!.isBefore(now);
    }
    return eventDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Get formatted time string
  String get timeString {
    if (isAllDay) return 'All Day';
    if (startTime == null) return '';
    
    final hour = startTime!.hour;
    final minute = startTime!.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }

  Map<String, dynamic> toFirestore() => toJson();

  static Event fromFirestore(dynamic doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Event.fromJson({...d, 'id': doc.id});
  }

  Event copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    String? category,
    String? color,
    bool? isRecurring,
    String? recurrenceRule,
    String? reminder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      category: category ?? this.category,
      color: color ?? this.color,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminder: reminder ?? this.reminder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_all_day': isAllDay ? 1 : 0,
      'location': location,
      'category': category,
      'color': color,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_rule': recurrenceRule,
      'reminder': reminder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['event_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      eventDate: DateTime.parse(map['event_date'] as String),
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      isAllDay: map['is_all_day'] == 1,
      location: map['location'] as String?,
      category: map['category'] as String? ?? 'personal',
      color: map['color'] as String?,
      isRecurring: map['is_recurring'] == 1,
      recurrenceRule: map['recurrence_rule'] as String?,
      reminder: map['reminder'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isAllDay': isAllDay,
      'location': location,
      'category': category,
      'color': color,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'reminder': reminder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: DateTime.parse(json['eventDate'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isAllDay: json['isAllDay'] as bool? ?? false,
      location: json['location'] as String?,
      category: json['category'] as String? ?? 'personal',
      color: json['color'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrenceRule: json['recurrenceRule'] as String?,
      reminder: json['reminder'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        eventDate,
        startTime,
        endTime,
        isAllDay,
        location,
        category,
        color,
        isRecurring,
        recurrenceRule,
        reminder,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Event(id: $id, title: $title, date: $eventDate, category: $category)';
  }
}

// ─────────────────────────────────────────────────────────────
// Event Categories
// ─────────────────────────────────────────────────────────────

class EventCategory {
  final String name;
  final String emoji;
  final int colorValue;

  const EventCategory({
    required this.name,
    required this.emoji,
    required this.colorValue,
  });
}

class EventCategories {
  static const List<EventCategory> all = [
    EventCategory(name: 'personal', emoji: '🎪', colorValue: 0xFF4ECDC4),
    EventCategory(name: 'work', emoji: '💼', colorValue: 0xFF6BCB77),
    EventCategory(name: 'health', emoji: '🏥', colorValue: 0xFFFF6B6B),
    EventCategory(name: 'social', emoji: '👥', colorValue: 0xFFFFB347),
    EventCategory(name: 'reminder', emoji: '🔔', colorValue: 0xFF9B89B3),
    EventCategory(name: 'birthday', emoji: '🎂', colorValue: 0xFFFF69B4),
    EventCategory(name: 'travel', emoji: '✈️', colorValue: 0xFF87CEEB),
    EventCategory(name: 'finance', emoji: '💰', colorValue: 0xFF32CD32),
  ];

  static EventCategory? getByName(String name) {
    try {
      return all.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  static List<String> get names => all.map((c) => c.name).toList();
}