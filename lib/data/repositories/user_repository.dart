import 'package:personal_haven/core/utils/biometrics_helper.dart';
import 'package:personal_haven/core/utils/password_helper.dart';
import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:personal_haven/data/models/user.dart';
import 'package:sqflite/sql.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Create a new user account
  Future<User?> createUser({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
    bool enableBiometric = false,
  }) async {
    final db = await _dbHelper.database;

    try {
      // Check if email already exists
      final existingUser = await getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Email already exists');
      }

      // Generate user ID
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Create user
      final user = User(
        id: userId,
        email: email.toLowerCase().trim(),
        username: username?.trim(),
        firstName: firstName?.trim(),
        lastName: lastName?.trim(),
        createdAt: DateTime.now(),
        isPremium: false,
      );

      // Insert user
      await db.insert('users', user.toMap());

      // Hash password and store credentials
      final salt = PasswordHelper.generateSalt();
      final passwordHash = PasswordHelper.hashPassword(password, salt);
      
      final credentials = UserCredentials(
        userId: userId,
        passwordHash: passwordHash,
        salt: salt,
        createdAt: DateTime.now(),
      );

      await db.insert('user_credentials', credentials.toMap());

      // Set up biometric if enabled
      if (enableBiometric) {
        await setBiometricEnabled(userId, true);
      }

      return user;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Verify user login credentials
  Future<User?> verifyLogin(String email, String password) async {
    final db = await _dbHelper.database;

    // Get user
    final user = await getUserByEmail(email);
    if (user == null) return null;

    // Get credentials
    final credMaps = await db.query(
      'user_credentials',
      where: 'user_id = ?',
      whereArgs: [user.id],
    );

    if (credMaps.isEmpty) return null;

    final credentials = UserCredentials.fromMap(credMaps.first);

    // Verify password
    if (PasswordHelper.verifyPassword(password, credentials.passwordHash, credentials.salt)) {
      // Update last login
      await updateLastLogin(user.id);
      return user;
    }

    return null;
  }

  /// Update last login time
  Future<void> updateLastLogin(String userId) async {
    final db = await _dbHelper.database;

    await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Update user profile
  Future<bool> updateUser(User user) async {
    final db = await _dbHelper.database;

    try {
      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    final db = await _dbHelper.database;

    try {
      // Get current credentials
      final credMaps = await db.query(
        'user_credentials',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (credMaps.isEmpty) return false;

      final credentials = UserCredentials.fromMap(credMaps.first);

      // Verify old password
      if (!PasswordHelper.verifyPassword(oldPassword, credentials.passwordHash, credentials.salt)) {
        return false;
      }

      // Generate new hash
      final newSalt = PasswordHelper.generateSalt();
      final newHash = PasswordHelper.hashPassword(newPassword, newSalt);

      // Update credentials
      await db.update(
        'user_credentials',
        {
          'password_hash': newHash,
          'salt': newSalt,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  /// Check if biometric is enabled for user
  Future<bool> isBiometricEnabled(String userId) async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      'biometric_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first['is_enabled'] == 1;
    }
    return false;
  }

  /// Set biometric enabled/disabled
  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    final db = await _dbHelper.database;

    final biometricTypes = await BiometricHelper.getAvailableBiometrics();
    final biometricType = BiometricHelper.getBiometricTypeName(biometricTypes);

    await db.insert(
      'biometric_settings',
      {
        'user_id': userId,
        'is_enabled': enabled ? 1 : 0,
        'biometric_type': biometricType,
        'last_used': enabled ? DateTime.now().toIso8601String() : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update last biometric use
  Future<void> updateBiometricLastUsed(String userId) async {
    final db = await _dbHelper.database;

    await db.update(
      'biometric_settings',
      {'last_used': DateTime.now().toIso8601String()},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete user account
  Future<bool> deleteUser(String userId) async {
    final db = await _dbHelper.database;

    try {
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
