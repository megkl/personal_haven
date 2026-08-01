import 'package:cloud_firestore/cloud_firestore.dart';

enum HavenMessageStatus { sending, sent, failed }

class HavenChatMessage {
  const HavenChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String content;
  final String role;
  final HavenMessageStatus status;
  final DateTime? createdAt;

  bool get isUser => role == 'user';

  factory HavenChatMessage.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => HavenChatMessage.fromMap(document.id, document.data());

  factory HavenChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return HavenChatMessage(
      id: id,
      content: (data['content'] as String? ?? '').trim(),
      role: data['role'] == 'assistant' ? 'assistant' : 'user',
      status: switch (data['status']) {
        'failed' => HavenMessageStatus.failed,
        'sending' => HavenMessageStatus.sending,
        _ => HavenMessageStatus.sent,
      },
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
