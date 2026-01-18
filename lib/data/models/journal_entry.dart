import 'package:equatable/equatable.dart';

/// Represents a journal entry in the Personal Haven app
class JournalEntry extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category;
  final String? emoji;
  final List<String> tags;
  final bool isPrivate;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.emoji,
    this.tags = const [],
    this.isPrivate = true,
  });

  /// Create a copy of this entry with updated fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    String? emoji,
    List<String>? tags,
    bool? isPrivate,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      tags: tags ?? this.tags,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category,
      'emoji': emoji,
      'tags': tags.join(','),
      'is_private': isPrivate ? 1 : 0,
    };
  }

  /// Create from database Map
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      category: map['category'] as String,
      emoji: map['emoji'] as String?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      isPrivate: map['is_private'] == 1,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
      'emoji': emoji,
      'tags': tags,
      'isPrivate': isPrivate,
    };
  }

  /// Create from JSON (from API)
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      category: json['category'] as String,
      emoji: json['emoji'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isPrivate: json['isPrivate'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        content,
        createdAt,
        updatedAt,
        category,
        emoji,
        tags,
        isPrivate,
      ];

  @override
  String toString() {
    return 'JournalEntry(id: $id, title: $title, category: $category, emoji: $emoji)';
  }
}