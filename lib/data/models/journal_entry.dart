import 'package:equatable/equatable.dart';

/// Represents a journal entry in the Personal Haven app
class JournalEntry extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime entryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category;
  final String? emoji;
  final List<String> tags;
  final bool isPrivate;
  final String? locationData;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.emoji,
    this.tags = const [],
    this.isPrivate = true,
    this.locationData,
  });

  /// Create a copy of this entry with updated fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? entryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    String? emoji,
    List<String>? tags,
    bool? isPrivate,
    String? locationData,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      tags: tags ?? this.tags,
      isPrivate: isPrivate ?? this.isPrivate,
      locationData: locationData ?? this.locationData,
    );
  }

  /// Convert to Map for database storage
  /// Matches database schema: entry_id, user_id, title, content, entry_date, 
  /// is_private, location_data, created_at, updated_at, category, emoji, tags
  Map<String, dynamic> toMap() {
    return {
      'entry_id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'entry_date': entryDate.toIso8601String(),
      'is_private': isPrivate ? 1 : 0,
      'location_data': locationData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category,
      'emoji': emoji,
      'tags': tags.join(','),
    };
  }

  /// Create from database Map
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['entry_id'] as String,
      userId: map['user_id'] as String,
      title: (map['title'] as String?) ?? '',
      content: map['content'] as String,
      entryDate: DateTime.parse(map['entry_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      category: (map['category'] as String?) ?? 'Notes',
      emoji: map['emoji'] as String?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      isPrivate: map['is_private'] == 1,
      locationData: map['location_data'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => toJson();

  /// Create from Firestore document snapshot
  factory JournalEntry.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntry.fromJson({...data, 'id': doc.id});
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'entryDate': entryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
      'emoji': emoji,
      'tags': tags,
      'isPrivate': isPrivate,
      'locationData': locationData,
    };
  }

  /// Create from JSON (from API)
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      entryDate: DateTime.parse(json['entryDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      category: json['category'] as String,
      emoji: json['emoji'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isPrivate: json['isPrivate'] as bool? ?? true,
      locationData: json['locationData'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        content,
        entryDate,
        createdAt,
        updatedAt,
        category,
        emoji,
        tags,
        isPrivate,
        locationData,
      ];

  @override
  String toString() {
    return 'JournalEntry(id: $id, title: $title, category: $category, emoji: $emoji)';
  }
}

// ─────────────────────────────────────────────────────────────
// Journal Categories
// ─────────────────────────────────────────────────────────────

class JournalCategory {
  final String name;
  final String emoji;
  final int colorValue;

  const JournalCategory({
    required this.name,
    required this.emoji,
    required this.colorValue,
  });
}

class JournalCategories {
  static const List<JournalCategory> all = [
    JournalCategory(name: 'Notes', emoji: '📝', colorValue: 0xFF4ECDC4),
    JournalCategory(name: 'Goals', emoji: '🎯', colorValue: 0xFF667eea),
    JournalCategory(name: 'Gratitude', emoji: '🙏', colorValue: 0xFFFFB347),
    JournalCategory(name: 'Health', emoji: '💪', colorValue: 0xFFFF6B6B),
    JournalCategory(name: 'Work', emoji: '💼', colorValue: 0xFF6BCB77),
    JournalCategory(name: 'Personal', emoji: '🌟', colorValue: 0xFF9B89B3),
    JournalCategory(name: 'Ideas', emoji: '💡', colorValue: 0xFFFFD93D),
    JournalCategory(name: 'Dreams', emoji: '🌙', colorValue: 0xFF748DA6),
  ];

  static JournalCategory? getByName(String name) {
    try {
      return all.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  static List<String> get names => all.map((c) => c.name).toList();
}

// ─────────────────────────────────────────────────────────────
// Entry Mood/Emoji Options
// ─────────────────────────────────────────────────────────────

class JournalMoods {
  static const List<String> all = [
    '😊', '😌', '🥰', '😎', '🤔',
    '😴', '😢', '😤', '🎉', '💪',
    '🙏', '✨', '🌟', '💡', '📚',
  ];
}