class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get needsRefresh => DateTime.now().isAfter(
    expiresAt.subtract(const Duration(minutes: 5)),
  );
}