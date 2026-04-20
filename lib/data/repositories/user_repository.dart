import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:personal_haven/data/models/user.dart';
import 'package:personal_haven/services/firestore_service.dart';

class UserRepository {
  final _fs = FirestoreService.instance;
  static const _col = 'users'; // top-level collection

  /// Save or update user profile in Firestore
  Future<void> saveUser(User user) async {
    await _fs.userProfile(user.id).set(user.toJson(), SetOptions(merge: true));
  }

  /// Get user by Firebase UID
  Future<User?> getUserById(String uid) async {
    final doc = await _fs.userProfile(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return User.fromJson(doc.data()!);
  }

  /// Create user profile from Firebase Auth user (called after social sign-in)
  Future<User> createOrUpdateFromAuth(fb.User firebaseUser,
      {String? displayName}) async {
    final existing = await getUserById(firebaseUser.uid);

    final user = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: displayName?.split(' ').first ??
          firebaseUser.displayName?.split(' ').first ??
          existing?.firstName,
      lastName: displayName?.split(' ').skip(1).join(' ').isNotEmpty == true
          ? displayName!.split(' ').skip(1).join(' ')
          : firebaseUser.displayName?.split(' ').skip(1).join(' ') ??
              existing?.lastName,
      avatarUrl: firebaseUser.photoURL ?? existing?.avatarUrl,
      bio: existing?.bio,
      createdAt: existing?.createdAt ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
      isPremium: existing?.isPremium ?? false,
    );

    await saveUser(user);
    return user;
  }

  /// Update profile fields
  Future<User> updateProfile(
    String uid, {
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
  }) async {
    final existing = await getUserById(uid);
    if (existing == null) throw Exception('User not found');

    final updated = existing.copyWith(
      firstName: firstName ?? existing.firstName,
      lastName: lastName ?? existing.lastName,
      bio: bio ?? existing.bio,
      avatarUrl: avatarUrl ?? existing.avatarUrl,
    );

    await saveUser(updated);
    return updated;
  }

  /// Delete user profile document
  Future<void> deleteUser(String uid) async {
    await _fs.userProfile(uid).delete();
  }
}
