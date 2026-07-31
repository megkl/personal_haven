class AssistantCommandText {
  const AssistantCommandText._();

  static String removeConversationalPrefix(String input) {
    var value = input.trim();
    value = value.replaceFirst(
      RegExp(
        r'^(?:hi|hello|hey)(?:\s+haven(?:\s+ai)?)?\s*[,!:.\-]*\s*',
        caseSensitive: false,
      ),
      '',
    );
    value = value.replaceFirst(
      RegExp(r'^haven(?:\s+ai)?\s*[,!:.\-]*\s*', caseSensitive: false),
      '',
    );
    value = value.replaceFirst(
      RegExp(r'^i\s+(?:would\s+like|want)\s+to\s+', caseSensitive: false),
      '',
    );
    return value.trim();
  }

  static bool hasNegatedPriority(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return RegExp(
      r"\b(?:not|is\s+not|isn't|isnt)\s+(?:so\s+|that\s+|very\s+)?(?:high|medium|normal|low)(?:\s+priority)?\b",
    ).hasMatch(normalized);
  }
}
