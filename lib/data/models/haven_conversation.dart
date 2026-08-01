import 'package:cloud_firestore/cloud_firestore.dart';

class HavenConversation {
  const HavenConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    this.lastMessage,
  });

  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int messageCount;
  final String? lastMessage;

  factory HavenConversation.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => HavenConversation.fromMap(document.id, document.data());

  factory HavenConversation.fromMap(String id, Map<String, dynamic> data) {
    return HavenConversation(
      id: id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'New conversation',
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
      lastMessage: data['lastMessage'] as String?,
    );
  }

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
