import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Result from a social sign-in attempt
class SocialAuthResult {
  final bool success;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? uid; // Firebase UID
  final String? provider;
  final String? error;

  SocialAuthResult({
    required this.success,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.uid,
    this.provider,
    this.error,
  });
}

class SocialAuthService {
  static final SocialAuthService instance = SocialAuthService._();
  SocialAuthService._();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _appAuth = const FlutterAppAuth();

  // ── Google ──────────────────────────────────────────────────────────────────
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return SocialAuthResult(success: false, error: 'Sign-in cancelled');
      }
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user!;
      return SocialAuthResult(
        success: true,
        email: user.email,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
        uid: user.uid,
        provider: 'google',
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
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
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCred = await _auth.signInWithCredential(oauthCredential);
      final user = userCred.user!;

      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      // Apple only sends name on first sign-in; update profile if available
      if (fullName.isNotEmpty && (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(fullName);
      }

      return SocialAuthResult(
        success: true,
        email: user.email,
        displayName: user.displayName ?? (fullName.isNotEmpty ? fullName : null),
        uid: user.uid,
        provider: 'apple',
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }

  // ── Microsoft ────────────────────────────────────────────────────────────────
  // Replace with your Azure AD app client ID and bundle ID.
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

      if (result == null) {
        return SocialAuthResult(success: false, error: 'Sign-in cancelled');
      }

      // Sign into Firebase with the Microsoft access token
      final oauthCredential = OAuthProvider('microsoft.com').credential(
        idToken: result.idToken,
        accessToken: result.accessToken,
      );
      final userCred = await _auth.signInWithCredential(oauthCredential);
      final user = userCred.user!;

      return SocialAuthResult(
        success: true,
        email: user.email,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
        uid: user.uid,
        provider: 'microsoft',
      );
    } catch (e) {
      return SocialAuthResult(success: false, error: e.toString());
    }
  }
}
