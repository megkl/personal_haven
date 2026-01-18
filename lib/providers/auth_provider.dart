import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication state
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

/// Authentication Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userId = prefs.getString('userId');

    state = state.copyWith(
      isAuthenticated: isLoggedIn,
      userId: userId,
      isLoading: false,
    );
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    bool enableBiometric = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // In production, this would call an API
      // For now, simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate a simple user ID (in production, this comes from backend)
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);
      await prefs.setBool('biometricEnabled', enableBiometric);

      state = state.copyWith(
        isAuthenticated: true,
        userId: userId,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign up failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Log in an existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // In production, verify credentials with backend
      // For now, accept any credentials
      final userId = 'user_demo';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userEmail', email);

      state = state.copyWith(
        isAuthenticated: true,
        userId: userId,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    state = AuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  return authState.userId ?? 'user_demo';
});

/// Provider for checking if user has seen onboarding
final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenOnboarding') ?? false;
});

/// Provider to mark onboarding as seen
final markOnboardingSeenProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  };
});