import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/repositories/subscription_repository.dart';
import 'package:personal_haven/data/repositories/user_repository.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/services/social_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
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
      // Sign into Firebase with the credential built in SocialAuthService
      if (result.credential == null) {
        state = state.copyWith(
            isLoading: false, error: 'No auth credential received');
        return false;
      }

      final userCredential = await fb.FirebaseAuth.instance
          .signInWithCredential(result.credential!);
      final fbUser = userCredential.user;

      if (fbUser == null) {
        state = state.copyWith(
            isLoading: false, error: 'Authentication failed');
        return false;
      }

      // Persist / update Firestore profile
          final user = await UserRepository().createOrUpdateFromAuth(fbUser,
              displayName: result.displayName);

          // Save profile to local preferences for offline display.
          final prefs = await SharedPrefsHelper.getInstance();
          await prefs.saveUserSession(user);

          if (result.provider != null) {
            final rawPrefs = await SharedPreferences.getInstance();
            await rawPrefs.setString('authProvider', result.provider!);
          }

      // Activate free trial on first sign-up (no-op if already used)
      try {
        final subRepo = SubscriptionRepository();
        final hasUsed = await subRepo.hasUsedTrial(fbUser.uid);
        if (!hasUsed) await subRepo.createTrial(fbUser.uid);
      } catch (_) {}

      // Cache minimal info for offline display

      state = state.copyWith(
        isAuthenticated: true,
        userId: fbUser.uid,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Social login failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await SocialAuthService.instance.signOutGoogle();
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    // Clear saved session from our helper (preserves other app prefs)
    final helper = await SharedPrefsHelper.getInstance();
    await helper.clearSession();

    // Also remove any raw authProvider key stored directly in SharedPreferences
    final rawPrefs = await SharedPreferences.getInstance();
    await rawPrefs.remove('authProvider');
    state = AuthState(isAuthenticated: false, isLoading: false);
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

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