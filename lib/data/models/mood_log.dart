import 'package:equatable/equatable.dart';

class MoodLog extends Equatable {
  final String id;
  final String userId;
  final int moodLevel; // 1-5 scale
  final String moodEmoji;
  final String? notes;
  final DateTime timestamp;

  const MoodLog({
    required this.id,
    required this.userId,
    required this.moodLevel,
    required this.moodEmoji,
    this.notes,
    required this.timestamp,
  });

  MoodLog copyWith({
    String? id,
    String? userId,
    int? moodLevel,
    String? moodEmoji,
    String? notes,
    DateTime? timestamp,
  }) {
    return MoodLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodLevel: moodLevel ?? this.moodLevel,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mood_log_id': id,
      'user_id': userId,
      'mood_level': moodLevel,
      'mood_emoji': moodEmoji,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      id: map['mood_log_id'] as String,
      userId: map['user_id'] as String,
      moodLevel: map['mood_level'] as int,
      moodEmoji: map['mood_emoji'] as String,
      notes: map['notes'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, moodLevel, moodEmoji, notes, timestamp];
}
