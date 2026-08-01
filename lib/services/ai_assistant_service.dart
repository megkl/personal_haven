import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_haven/data/models/haven_chat_message.dart';
import 'package:personal_haven/data/models/haven_conversation.dart';

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

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to use Ask Haven.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('users').doc(_uid).collection('conversations');

  Stream<List<HavenConversation>> watchConversations({int limit = 50}) {
    if (_auth.currentUser == null) return Stream.value(const []);
    return _conversations
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(HavenConversation.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<HavenChatMessage>> watchMessages(
    String conversationId, {
    int limit = 100,
  }) {
    if (_auth.currentUser == null) return Stream.value(const []);
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .limitToLast(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(HavenChatMessage.fromFirestore)
              .where((message) => message.content.isNotEmpty)
              .toList(growable: false),
        );
  }

  Future<String> createConversation({bool importLegacy = false}) async {
    final callable = _functions.httpsCallable(
      'createHavenConversation',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call<Map<Object?, Object?>>({
      'importLegacy': importLegacy,
    });
    final data = Map<String, dynamic>.from(result.data);
    final id = data['conversationId'] as String?;
    if (id == null || id.isEmpty) {
      throw StateError('Haven could not create a conversation.');
    }
    return id;
  }

  Future<void> renameConversation(String conversationId, String title) async {
    final callable = _functions.httpsCallable('renameHavenConversation');
    await callable.call<void>({
      'conversationId': conversationId,
      'title': title.trim(),
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    final callable = _functions.httpsCallable(
      'deleteHavenConversation',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    await callable.call<void>({'conversationId': conversationId});
  }

  Future<void> saveLocalExchange({
    required String conversationId,
    required String userMessage,
    required String assistantMessage,
  }) async {
    final callable = _functions.httpsCallable('appendHavenExchange');
    await callable.call<void>({
      'conversationId': conversationId,
      'userMessage': userMessage,
      'assistantMessage': assistantMessage,
    });
  }

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

  Future<AiChatResult> chat(String message, {String? conversationId}) async {
    try {
      final callable = _functions.httpsCallable(
        'chatWithHavenAI',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final payload = <String, Object?>{'message': message};
      if (conversationId case final id?) payload['conversationId'] = id;
      final result = await callable.call<Map<Object?, Object?>>(payload);

      final data = Map<String, dynamic>.from(result.data);
      return AiChatResult(
        text: data['reply'] as String?,
        persisted: conversationId != null,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return const AiChatResult(
          text:
              'Please sign in first so I can keep your Haven conversation safe.',
          persisted: false,
        );
      }
      return AiChatResult(
        text: e.message ?? 'Haven AI could not reply just now.',
        persisted: false,
      );
    } catch (_) {
      return const AiChatResult(text: null, persisted: false);
    }
  }
}

class AiChatResult {
  const AiChatResult({required this.text, required this.persisted});

  final String? text;
  final bool persisted;
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
