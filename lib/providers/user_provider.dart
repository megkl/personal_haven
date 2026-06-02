import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/user.dart';
import 'package:personal_haven/data/repositories/user_repository.dart';

class UserState {
  final User? user;
  final bool isLoading;
  final String? error;

  UserState({this.user, this.isLoading = false, this.error});

  UserState copyWith({User? user, bool? isLoading, String? error}) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _repo = UserRepository();

  UserNotifier() : super(UserState()) {
    loadUser();
  }

  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final user = await _repo.getUserById(fbUser.uid);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load user: $e');
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
  }) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _repo.updateProfile(
        uid,
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(user: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to update profile: $e');
    }
  }

  void clearError() => state = state.copyWith(error: null);

  Future<void> refresh() => loadUser();
}

final userProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) => UserNotifier());

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userProvider).user;
});

final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.displayName ?? 'User';
});
