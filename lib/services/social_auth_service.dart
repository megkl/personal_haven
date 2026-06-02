import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Result from a social sign-in attempt
class SocialAuthResult {
  final bool success;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? idToken;
  final String? provider;
  final String? error;

  SocialAuthResult({
    required this.success,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.idToken,
    this.provider,
    this.error,
  });
}

class SocialAuthService {
  static final SocialAuthService instance = SocialAuthService._();
  SocialAuthService._();

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _appAuth = const FlutterAppAuth();

  // ── Google ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return SocialAuthResult(success: false, error: 'Sign-in cancelled');
      }
      final auth = await account.authentication;
      return SocialAuthResult(
        success: true,
        email: account.email,
        displayName: account.displayName,
        avatarUrl: account.photoUrl,
        idToken: auth.idToken,
        provider: 'google',
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // ── Apple ───────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      return SocialAuthResult(
        success: true,
        email: credential.email,
        displayName: fullName.isNotEmpty ? fullName : null,
        idToken: credential.identityToken,
        provider: 'apple',
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }

  // ── Microsoft ────────────────────────────────────────────────────────────────
  // Replace the clientId and redirectUrl with your Azure AD app values.
  static const _msClientId = 'YOUR_MICROSOFT_CLIENT_ID';
  static const _msRedirectUrl = 'msauth.YOUR_BUNDLE_ID://auth';
  static const _msDiscoveryUrl =
      'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration';

  Future<SocialAuthResult> signInWithMicrosoft() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _msClientId,
          _msRedirectUrl,
          discoveryUrl: _msDiscoveryUrl,
          scopes: ['openid', 'profile', 'email'],
          promptValues: ['select_account'],
        ),
      );

      // Decode the id_token to extract basic claims (email / name)
      final claims = _decodeJwtPayload(result.idToken ?? '');
      return SocialAuthResult(
        success: true,
        email: claims['email'] as String?,
        displayName: claims['name'] as String?,
        idToken: result.idToken,
        provider: 'microsoft',
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }

  /// Minimal JWT payload decoder (no signature verification needed here).
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final payload = parts[1];
      // Pad to a multiple of 4
      final padded = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      final decoded = String.fromCharCodes(base64Decode(padded));
      // Simple key extraction without dart:convert import issues
      final emailMatch = RegExp(r'"email"\s*:\s*"([^"]+)"').firstMatch(decoded);
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(decoded);
      return {
        if (emailMatch != null) 'email': emailMatch.group(1),
        if (nameMatch != null) 'name': nameMatch.group(1),
      };
    } catch (_) {
      return {};
    }
  }
}
