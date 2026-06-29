import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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


@riverpod
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

    final fbUser = userCredential.user;

    if (fbUser == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Authentication failed',
      );
      return false;
    }

    final user = await UserRepository().createOrUpdateFromAuth(
      fbUser,
      displayName: result.displayName,
    );

    if (!ref.mounted) return false;

    final prefs = await SharedPrefsHelper.getInstance();

    if (!ref.mounted) return false;

    await prefs.saveUserSession(user);

    if (!ref.mounted) return false;

    if (result.provider != null) {
      final rawPrefs = await SharedPreferences.getInstance();

      if (!ref.mounted) return false;

      await rawPrefs.setString('authProvider', result.provider!);

      if (!ref.mounted) return false;
    }

    try {
      final subRepo = SubscriptionRepository();

      final hasUsed = await subRepo.hasUsedTrial(fbUser.uid);

      if (!ref.mounted) return false;

      if (!hasUsed) {
        await subRepo.createTrial(fbUser.uid);

        if (!ref.mounted) return false;
      }
    } catch (_) {}

    state = state.copyWith(
      isAuthenticated: true,
      userId: fbUser.uid,
      isLoading: false,
    );

    return true;
  } catch (e) {
    if (!ref.mounted) return false;

    state = state.copyWith(
      isLoading: false,
      error: 'Social login failed: $e',
    );

    return false;
  }
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

  state = AuthState(
    isAuthenticated: false,
    isLoading: false,
  );
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