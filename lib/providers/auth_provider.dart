import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/user.dart';
import 'package:personal_haven/data/repositories/subscription_repository.dart';
import 'package:personal_haven/data/repositories/user_repository.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/services/social_auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'auth_provider.g.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userId;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.userId,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    Future.microtask(checkAuthStatus);
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    state = state.copyWith(
      isAuthenticated: fbUser != null,
      userId: fbUser?.uid,
      isLoading: false,
    );
  }

  Future<bool> socialLogin(SocialAuthResult result) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (result.credential == null) {
        if (!ref.mounted) return false;

        state = state.copyWith(
          isLoading: false,
          error: 'No auth credential received',
        );
        return false;
      }

      final userCredential = await fb.FirebaseAuth.instance
          .signInWithCredential(result.credential!);

      if (!ref.mounted) return false;

      final fbUser =
          userCredential.user ?? fb.FirebaseAuth.instance.currentUser;

      if (fbUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication failed',
        );
        return false;
      }

      await _completeSocialSession(fbUser, result);

      return true;
    } on fb.FirebaseAuthException catch (e) {
      final fbUser = fb.FirebaseAuth.instance.currentUser;

      if (_canContinueWithCurrentUser(e) && fbUser != null) {
        await _completeSocialSession(fbUser, result);
        return true;
      }

      if (!ref.mounted) return false;

      state = state.copyWith(
        isLoading: false,
        error: _friendlySocialAuthError(e),
      );

      return false;
    } catch (e) {
      final fbUser = fb.FirebaseAuth.instance.currentUser;

      if (fbUser != null) {
        await _completeSocialSession(fbUser, result);
        return true;
      }

      if (!ref.mounted) return false;

      state = state.copyWith(
        isLoading: false,
        error: 'Social login failed: $e',
      );

      return false;
    }
  }

  Future<void> _completeSocialSession(
    fb.User fbUser,
    SocialAuthResult result,
  ) async {
    final user = await _profileForAuthenticatedUser(fbUser, result);

    if (!ref.mounted) return;

    try {
      final prefs = await SharedPrefsHelper.getInstance();

      if (!ref.mounted) return;

      await prefs.saveUserSession(user);

      if (!ref.mounted) return;

      if (result.provider != null) {
        final rawPrefs = await SharedPreferences.getInstance();

        if (!ref.mounted) return;

        await rawPrefs.setString('authProvider', result.provider!);

        if (!ref.mounted) return;
      }
    } catch (_) {
      // Firebase Auth is the source of truth; local cache issues should not
      // block a successful first-time social sign-in.
    }

    await _ensureTrialIfNeeded(fbUser.uid);

    if (!ref.mounted) return;

    state = state.copyWith(
      isAuthenticated: true,
      userId: fbUser.uid,
      isLoading: false,
      error: null,
    );
  }

  Future<User> _profileForAuthenticatedUser(
    fb.User fbUser,
    SocialAuthResult result,
  ) async {
    try {
      return await UserRepository().createOrUpdateFromAuth(
        fbUser,
        displayName: result.displayName,
      );
    } catch (_) {
      return _fallbackUserFromAuth(fbUser, displayName: result.displayName);
    }
  }

  User _fallbackUserFromAuth(fb.User fbUser, {String? displayName}) {
    final name = displayName ?? fbUser.displayName;
    final nameParts = name?.trim().split(RegExp(r'\s+')) ?? const <String>[];

    return User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      firstName: nameParts.isNotEmpty ? nameParts.first : null,
      lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : null,
      avatarUrl: fbUser.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  Future<void> _ensureTrialIfNeeded(String uid) async {
    try {
      final subRepo = SubscriptionRepository();
      final hasUsed = await subRepo.hasUsedTrial(uid);

      if (!ref.mounted) return;

      if (!hasUsed) {
        await subRepo.createTrial(uid);
      }
    } catch (_) {}
  }

  bool _canContinueWithCurrentUser(fb.FirebaseAuthException error) {
    return error.code == 'account-exists-with-different-credential' ||
        error.code == 'credential-already-in-use' ||
        error.code == 'email-already-in-use';
  }

  String _friendlySocialAuthError(fb.FirebaseAuthException error) {
    if (error.code == 'account-exists-with-different-credential' ||
        error.code == 'email-already-in-use') {
      return 'This email already has an account. Please log in with the provider you used before.';
    }

    if (error.code == 'credential-already-in-use') {
      return 'This social account is already linked. Please log in instead.';
    }

    return 'Social login failed: ${error.message ?? error.code}';
  }

  Future<void> logout() async {
    try {
      await SocialAuthService.instance.signOutGoogle();

      if (!ref.mounted) return;

      await fb.FirebaseAuth.instance.signOut();

      if (!ref.mounted) return;
    } catch (_) {}

    final helper = await SharedPrefsHelper.getInstance();

    if (!ref.mounted) return;

    await helper.clearSession();

    if (!ref.mounted) return;

    final rawPrefs = await SharedPreferences.getInstance();

    if (!ref.mounted) return;

    await rawPrefs.remove('authProvider');

    if (!ref.mounted) return;

    state = AuthState(isAuthenticated: false, isLoading: false);
  }

  void clearError() => state = state.copyWith(error: null);
}

final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(authProvider).userId ??
      fb.FirebaseAuth.instance.currentUser?.uid ??
      '';
});

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenOnboarding') ?? false;
});

final markOnboardingSeenProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  };
});
