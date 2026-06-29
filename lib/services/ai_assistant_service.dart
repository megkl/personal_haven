import 'package:cloud_functions/cloud_functions.dart';

class AiAssistantService {
  AiAssistantService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

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
