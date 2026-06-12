import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthResult {
  final bool success;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? idToken;
  final String? accessToken;
  final String? provider;
  final String? error;
  final fb.AuthCredential? credential;

  SocialAuthResult({
    required this.success,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.idToken,
    this.accessToken,
    this.provider,
    this.error,
    this.credential,
  });
}

class SocialAuthService {
  static final SocialAuthService instance = SocialAuthService._();
  SocialAuthService._();

  final _appAuth = const FlutterAppAuth();
  bool _googleInitialized = false;

  // ── Google ──────────────────────────────────────────────────────────────────

  /// Initialize Google Sign-In. This must be called once before any other Google methods.
  /// Client ID and server Client ID should be configured via platform-specific setup.
  Future<void> initializeGoogle() async {
    if (_googleInitialized) return;

    try {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Google Sign-In: $e');
      _googleInitialized = false;
    }
  }

  /// Sign in with Google using authentication.
  /// On platforms that support it (Android, iOS, macOS), this shows the native sign-in UI.
  /// On web, fall back to platform-specific approach using renderButton.
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      // Ensure Google Sign-In is initialized
      if (!_googleInitialized) {
        await initializeGoogle();
      }

      GoogleSignInAccount? account;

      // Use authenticate on platforms that support it
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        // authenticate() handles both authentication and can include scope authorization
        try {
          account = await GoogleSignIn.instance.authenticate();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            return SocialAuthResult(success: false, error: 'Sign-in cancelled');
          }
          return SocialAuthResult(success: false, error: e.description ?? 'Sign-in failed');
        }
      } else {
        // For web and other platforms that don't support authenticate(),
        // use the lightweight authentication method
        try {
          account = await GoogleSignIn.instance.attemptLightweightAuthentication();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            return SocialAuthResult(success: false, error: 'Sign-in cancelled');
          }
          return SocialAuthResult(success: false, error: e.description ?? 'Sign-in failed');
        }
      }

      if (account == null) {
        return SocialAuthResult(success: false, error: 'Sign-in cancelled');
      }

      // Get authentication details (idToken)
      final auth = await account.authentication;
      if (auth.idToken == null) {
        return SocialAuthResult(
            success: false,
            error: 'Google idToken was null — try again');
      }

      // In google_sign_in 7.x, accessToken is obtained via authorization if needed
      // For Firebase authentication, idToken is sufficient
      // Create Firebase credential with idToken only (Firebase handles it)
      final credential = fb.GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      return SocialAuthResult(
        success: true,
        email: account.email,
        displayName: account.displayName,
        avatarUrl: account.photoUrl,
        idToken: auth.idToken,
        accessToken: null, // Not available from basic authentication in 7.x
        provider: 'google',
        credential: credential,
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: 'Google Sign-In error: $e');
    }
  }

  /// Disconnect from Google Sign-In.
  /// This clears the cached current user.
  Future<void> signOutGoogle() async {
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.disconnect();
      }
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  // ── Apple ───────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      final credential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
      );

      return SocialAuthResult(
        success: true,
        email: appleCredential.email,
        displayName: fullName.isNotEmpty ? fullName : null,
        idToken: appleCredential.identityToken,
        provider: 'apple',
        credential: credential,
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }

  // ── Microsoft ────────────────────────────────────────────────────────────────
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

      final credential = fb.OAuthProvider('microsoft.com').credential(
        idToken: result.idToken,
        accessToken: result.accessToken,
      );

      final claims = _decodeJwtPayload(result.idToken ?? '');
      return SocialAuthResult(
        success: true,
        email: claims['email'] as String?,
        displayName: claims['name'] as String?,
        idToken: result.idToken,
        accessToken: result.accessToken,
        provider: 'microsoft',
        credential: credential,
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final payload = parts[1];
      final padded = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      final decoded = String.fromCharCodes(base64Decode(padded));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}