import 'package:personal_haven/data/data_sources/remote/models/token_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  /// Save tokens
  static Future<void> saveTokens(TokenPair tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    await prefs.setString(_refreshTokenKey, tokens.refreshToken);
    await prefs.setString(_tokenExpiryKey, tokens.expiresAt.toIso8601String());
  }

  /// Get tokens
  static Future<TokenPair?> getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);
    final expiryStr = prefs.getString(_tokenExpiryKey);

    if (accessToken == null || refreshToken == null || expiryStr == null) {
      return null;
    }

    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiryStr),
    );
  }

  /// Clear tokens
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  /// Check if user has valid tokens
  static Future<bool> hasValidTokens() async {
    final tokens = await getTokens();
    return tokens != null && !tokens.isExpired;
  }
}