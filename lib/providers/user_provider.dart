import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_haven/data/models/user.dart';

/// User state
class UserState {
  final User? user;
  final bool isLoading;
  final String? error;

  UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User Notifier
class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState()) {
    loadUser();
  }

  /// Load user from SharedPreferences
  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'user_demo';
      final email = prefs.getString('userEmail') ?? 'user@example.com';
      final firstName = prefs.getString('userName') ?? 'Meg';
      final bio = prefs.getString('userBio');
      final avatarUrl = prefs.getString('avatarUrl');

      final user = User(
        id: userId,
        email: email,
        firstName: firstName,
        bio: bio,
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user: ${e.toString()}',
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? bio,
    String? avatarUrl,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final updatedUser = state.user!.copyWith(
        firstName: firstName ?? state.user!.firstName,
        lastName: lastName ?? state.user!.lastName,
        email: email ?? state.user!.email,
        bio: bio ?? state.user!.bio,
        avatarUrl: avatarUrl ?? state.user!.avatarUrl,
      );

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (firstName != null) await prefs.setString('userName', firstName);
      if (email != null) await prefs.setString('userEmail', email);
      if (bio != null) await prefs.setString('userBio', bio);
      if (avatarUrl != null) await prefs.setString('avatarUrl', avatarUrl);

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh user data
  Future<void> refresh() async {
    await loadUser();
  }
}

/// User provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

/// Provider for current user (convenience)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userProvider).user;
});

/// Provider for user display name
final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.displayName ?? 'User';
});