import 'package:flutter/material.dart';

class MoodLog {
  final String id;
  final String userId;
  final int moodLevel;
  final String? moodLabel;
  final String moodEmoji;
  final DateTime timestamp;
  final String? notes;

  MoodLog({
    required this.id,
    required this.userId,
    required this.moodLevel,
    this.moodLabel,
    required this.moodEmoji,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'mood_log_id': id,
      'user_id': userId,
      'mood_level': moodLevel,
      'mood_label_id': moodLabel,
      'mood_emoji': moodEmoji,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      id: map['mood_log_id'] as String,
      userId: map['user_id'] as String,
      moodLevel: map['mood_level'] as int,
      moodLabel: map['mood_label_id'] as String?,
      moodEmoji: map['mood_emoji'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      notes: map['notes'] as String?,
    );
  }

  MoodLog copyWith({
    String? id,
    String? userId,
    int? moodLevel,
    String? moodLabel,
    String? moodEmoji,
    DateTime? timestamp,
    String? notes,
  }) {
    return MoodLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodLevel: moodLevel ?? this.moodLevel,
      moodLabel: moodLabel ?? this.moodLabel,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'MoodLog(id: $id, emoji: $moodEmoji, label: $moodLabel, level: $moodLevel)';
  }
}

class MoodOption {
  final String emoji;
  final String label;
  final int level;
  final Color color;

  const MoodOption({
    required this.emoji,
    required this.label,
    required this.level,
    required this.color,
  });
}

class MoodOptions {
  static const List<MoodOption> all = [
    MoodOption(emoji: '😊', label: 'Happy', level: 5, color: Color(0xFFFFD93D)),
    MoodOption(emoji: '😌', label: 'Calm', level: 4, color: Color(0xFF6BCB77)),
    MoodOption(emoji: '🙏', label: 'Grateful', level: 5, color: Color(0xFFFF9A9E)),
    MoodOption(emoji: '⚡', label: 'Energetic', level: 4, color: Color(0xFFFFB347)),
    MoodOption(emoji: '😐', label: 'Neutral', level: 3, color: Color(0xFFB8E6E3)),
    MoodOption(emoji: '😔', label: 'Sad', level: 2, color: Color(0xFF748DA6)),
    MoodOption(emoji: '😰', label: 'Anxious', level: 2, color: Color(0xFFFFB347)),
    MoodOption(emoji: '😫', label: 'Stressed', level: 1, color: Color(0xFFFF6B6B)),
    MoodOption(emoji: '😴', label: 'Tired', level: 2, color: Color(0xFF9B89B3)),
    MoodOption(emoji: '😢', label: 'Tearful', level: 1, color: Color(0xFF748DA6)),
  ];

  /// Get mood option by emoji
  static MoodOption? getByEmoji(String emoji) {
    try {
      return all.firstWhere((m) => m.emoji == emoji);
    } catch (_) {
      return null;
    }
  }

  /// Get mood option by label
  static MoodOption? getByLabel(String label) {
    try {
      return all.firstWhere((m) => m.label.toLowerCase() == label.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  static Color getColorForLevel(int level) {
    switch (level) {
      case 5:
        return const Color(0xFFFFD93D); 
      case 4:
        return const Color(0xFF6BCB77); 
      case 3:
        return const Color(0xFFB8E6E3); 
      case 2:
        return const Color(0xFF748DA6); 
      case 1:
        return const Color(0xFFFF6B6B); 
      default:
        return const Color(0xFFB8E6E3);
    }
  }
}