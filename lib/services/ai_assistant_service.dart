import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiAssistantService {
  AiAssistantService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<List<AiChatHistoryMessage>> loadRecentMessages({
    int limit = 12,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return const [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final messages = snapshot.docs
          .map(AiChatHistoryMessage.fromFirestore)
          .whereType<AiChatHistoryMessage>()
          .toList()
          .reversed
          .toList(growable: false);
      return AiChatHistoryMessage.completeTurns(messages);
    } catch (_) {
      return const [];
    }
  }

  Future<AiAssistantResult?> parseAction(String message) async {
    try {
      final callable = _functions.httpsCallable(
        'parseAssistantAction',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final result = await callable.call<Map<Object?, Object?>>({
        'message': message,
      });

      return AiAssistantResult.fromMap(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw AiAssistantLimitException(
          e.message ?? 'AI action limit reached.',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> generatePrompts({
    required String intent,
    required String field,
    required String question,
    required String userInput,
    required Map<String, dynamic> fields,
    required List<String> fallbackPrompts,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateAssistantPrompts',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 12)),
      );
      final result = await callable.call<Map<Object?, Object?>>({
        'intent': intent,
        'field': field,
        'question': question,
        'userInput': userInput,
        'fields': fields,
        'fallbackPrompts': fallbackPrompts,
      });

      final data = Map<String, dynamic>.from(result.data);
      if (data['suggestedPrompts'] is! List) return null;
      return List<String>.from(data['suggestedPrompts'] as List);
    } catch (_) {
      return null;
    }
  }

  Future<String?> chat(String message) async {
    try {
      final callable = _functions.httpsCallable(
        'chatWithHavenAI',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call<Map<Object?, Object?>>({
        'message': message,
      });

      final data = Map<String, dynamic>.from(result.data);
      return data['reply'] as String?;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return 'Please sign in first so I can keep your Haven conversation safe.';
      }
      return e.message ?? 'Haven AI could not reply just now.';
    } catch (_) {
      return null;
    }
  }
}

class AiChatHistoryMessage {
  const AiChatHistoryMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String text;
  final bool isUser;
  final DateTime? createdAt;

  static AiChatHistoryMessage? fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => fromMap(document.data());

  static AiChatHistoryMessage? fromMap(Map<String, dynamic> data) {
    final role = data['role'];
    final content = data['content'];
    if ((role != 'user' && role != 'assistant') || content is! String) {
      return null;
    }

    final text = content.trim();
    if (text.isEmpty) return null;
    final timestamp = data['createdAt'];
    return AiChatHistoryMessage(
      text: text,
      isUser: role == 'user',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  static List<AiChatHistoryMessage> completeTurns(
    List<AiChatHistoryMessage> messages,
  ) {
    final complete = <AiChatHistoryMessage>[];
    for (var index = 0; index < messages.length - 1; index++) {
      final userMessage = messages[index];
      final assistantMessage = messages[index + 1];
      if (userMessage.isUser && !assistantMessage.isUser) {
        complete.addAll([userMessage, assistantMessage]);
        index++;
      }
    }
    return List.unmodifiable(complete);
  }
}

class AiAssistantLimitException implements Exception {
  const AiAssistantLimitException(this.message);

  final String message;
}

class AiAssistantResult {
  final String intent;
  final double confidence;
  final String action;
  final String? reply;
  final Map<String, dynamic> fields;
  final List<String> missingFields;
  final List<String> suggestedPrompts;

  const AiAssistantResult({
    required this.intent,
    required this.confidence,
    this.action = 'unknown',
    this.reply,
    this.fields = const {},
    this.missingFields = const [],
    this.suggestedPrompts = const [],
  });

  factory AiAssistantResult.fromMap(Map<String, dynamic> map) {
    return AiAssistantResult(
      intent: map['intent'] as String? ?? 'unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      action: map['action'] as String? ?? 'unknown',
      reply: map['reply'] as String?,
      fields: map['fields'] is Map
          ? Map<String, dynamic>.from(map['fields'] as Map)
          : const {},
      missingFields: map['missingFields'] is List
          ? List<String>.from(map['missingFields'] as List)
          : const [],
      suggestedPrompts: map['suggestedPrompts'] is List
          ? List<String>.from(map['suggestedPrompts'] as List)
          : const [],
    );
  }

  bool get isConfident => confidence >= 0.65 && intent != 'unknown';
}
