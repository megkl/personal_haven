import 'dart:convert';
import 'dart:nativewrappers/_internal/vm/bin/common_patch.dart';

import 'package:personal_haven/core/constants/api_config.dart';
import 'package:personal_haven/data/data_sources/remote/api_client.dart';
import 'package:personal_haven/data/data_sources/remote/models/api_response.dart';
import 'package:personal_haven/data/data_sources/remote/models/token_pair.dart';
import 'package:personal_haven/data/data_sources/remote/models/token_storage.dart';
import 'package:personal_haven/data/models/user.dart';
import 'package:personal_haven/data/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteAuthService {
  static final RemoteAuthService instance = RemoteAuthService._init();
  RemoteAuthService._init();

  final ApiClient _apiClient = ApiClient.instance;

  /// Sign up with remote API
  Future<ApiResponse<User>> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/signup',
        {
          'email': email,
          'password': password,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
        },
        requiresAuth: false,
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Save tokens
        if (jsonData['data']['tokens'] != null) {
          final tokens = TokenPair.fromJson(jsonData['data']['tokens']);
          await TokenStorage.saveTokens(tokens);
        }

        // Parse user
        final user = User.fromMap(jsonData['data']['user']);
        
        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Sign up failed',
          statusCode: response.statusCode,
          errors: jsonData['errors'],
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Login with remote API
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/login',
        {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        if (jsonData['data']['tokens'] != null) {
          final tokens = TokenPair.fromJson(jsonData['data']['tokens']);
          await TokenStorage.saveTokens(tokens);
        }

        // Parse user
        final user = User.fromMap(jsonData['data']['user']);
        
        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Logout from remote API
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/logout',
        {},
        requiresAuth: true,
      );

      await TokenStorage.clearTokens();

      return ApiResponse(
        success: response.statusCode == 200,
        statusCode: response.statusCode,
      );
    } catch (e) {
      await TokenStorage.clearTokens();
      return ApiResponse(success: true);
    }
  }

  /// Get current user from API
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.authEndpoint}/me',
        requiresAuth: true,
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromMap(jsonData['data']);
        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to get user',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.usersEndpoint}/profile',
        {
          if (username != null) 'username': username,
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (bio != null) 'bio': bio,
          if (preferences != null) 'preferences': preferences,
        },
        requiresAuth: true,
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromMap(jsonData['data']);
        return ApiResponse(
          success: true,
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonData['message'] ?? 'Update failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/change-password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        requiresAuth: true,
      );

      final jsonData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200,
        message: jsonData['message'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Request password reset
  Future<ApiResponse<void>> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/forgot-password',
        {'email': email},
        requiresAuth: false,
      );

      final jsonData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200,
        message: jsonData['message'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Reset password with token
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/reset-password',
        {
          'token': token,
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );

      final jsonData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200,
        message: jsonData['message'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Verify email
  Future<ApiResponse<void>> verifyEmail(String token) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/verify-email',
        {'token': token},
        requiresAuth: false,
      );

      final jsonData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200,
        message: jsonData['message'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Delete account
  Future<ApiResponse<void>> deleteAccount(String password) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.usersEndpoint}/delete-account',
        {'password': password},
        requiresAuth: true,
      );

      await TokenStorage.clearTokens();

      return ApiResponse(
        success: response.statusCode == 200,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
}

// ============================================================================
// HYBRID AUTH SERVICE (Local + Remote with Auto-Sync)
// ============================================================================

enum AuthMode { local, remote, hybrid }

class HybridAuthService {
  static final HybridAuthService instance = HybridAuthService._init();
  HybridAuthService._init();

  final RemoteAuthService _remoteAuth = RemoteAuthService.instance;
  final UserRepository _localRepo = UserRepository();
  
  AuthMode _currentMode = AuthMode.hybrid;

  /// Set authentication mode
  void setAuthMode(AuthMode mode) {
    _currentMode = mode;
  }

  /// Check internet connectivity
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
      //return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Sign up (hybrid mode)
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
    bool enableBiometric = false,
  }) async {
    try {
      User? user;
      bool syncedToRemote = false;

      // Try remote first if in hybrid/remote mode and has internet
      if (_currentMode != AuthMode.local && await _hasInternet()) {
        final remoteResult = await _remoteAuth.signUp(
          email: email,
          password: password,
          username: username,
          firstName: firstName,
          lastName: lastName,
        );

        if (remoteResult.success && remoteResult.data != null) {
          user = remoteResult.data!;
          syncedToRemote = true;

          // Save to local database for offline access
          await _localRepo.createUser(
            email: email,
            password: password,
            username: username,
            firstName: firstName,
            lastName: lastName,
            enableBiometric: enableBiometric,
          );
        }
      }

      // Fallback to local if remote failed or local-only mode
      if (user == null) {
        user = await _localRepo.createUser(
          email: email,
          password: password,
          username: username,
          firstName: firstName,
          lastName: lastName,
          enableBiometric: enableBiometric,
        );

        if (user == null) {
          return AuthResult(
            success: false,
            error: 'Failed to create account',
          );
        }

        // Mark for sync if in hybrid mode
        if (_currentMode == AuthMode.hybrid) {
          await _markForSync(user.id, 'create');
        }
      }

      // Save session
      await _saveSession(user.id, syncedToRemote);

      return AuthResult(
        success: true,
        user: user,
        metadata: {'syncedToRemote': syncedToRemote},
      );
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Login (hybrid mode)
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      User? user;
      bool syncedToRemote = false;

      // Try remote first if in hybrid/remote mode and has internet
      if (_currentMode != AuthMode.local && await _hasInternet()) {
        final remoteResult = await _remoteAuth.login(
          email: email,
          password: password,
        );

        if (remoteResult.success && remoteResult.data != null) {
          user = remoteResult.data!;
          syncedToRemote = true;

          // Update or create local copy
          final localUser = await _localRepo.getUserByEmail(email);
          if (localUser == null) {
            await _localRepo.createUser(
              email: email,
              password: password,
              firstName: user.firstName,
              lastName: user.lastName,
              username: user.username,
            );
          } else {
            await _localRepo.updateLastLogin(localUser.id);
          }
        }
      }

      // Fallback to local if remote failed or local-only mode
      if (user == null) {
        user = await _localRepo.verifyLogin(email, password);

        if (user == null) {
          return AuthResult(
            success: false,
            error: 'Invalid email or password',
          );
        }

        // Try to sync in background if hybrid mode
        if (_currentMode == AuthMode.hybrid) {
          _syncInBackground(email, password);
        }
      }

      // Save session
      await _saveSession(user.id, syncedToRemote);

      return AuthResult(
        success: true,
        user: user,
        metadata: {'syncedToRemote': syncedToRemote},
      );
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Logout (hybrid mode)
  Future<void> logout() async {
    try {
      // Logout from remote if connected
      if (await _hasInternet()) {
        await _remoteAuth.logout();
      }
    } catch (e) {
      print('Remote logout failed: $e');
    }

    // Clear local session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.setBool('is_logged_in', false);
    await TokenStorage.clearTokens();
  }

  /// Sync pending changes to remote
  Future<bool> syncPendingChanges() async {
    if (!await _hasInternet()) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      //final pendingSync = prefs.getStringList('pending_sync') ?? [];

      // for (final syncItem in pendingSync) {
      //   // Process each pending sync item
      //   // This would involve syncing journal entries, user updates, etc.
      //   // Implementation depends on your specific data models
      // }

      await prefs.remove('pending_sync');
      return true;
    } catch (e) {
      print('Sync failed: $e');
      return false;
    }
  }

  /// Save session
  Future<void> _saveSession(String userId, bool syncedToRemote) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('synced_to_remote', syncedToRemote);
  }

  /// Mark item for sync
  Future<void> _markForSync(String itemId, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSync = prefs.getStringList('pending_sync') ?? [];
    pendingSync.add('$action:$itemId:${DateTime.now().toIso8601String()}');
    await prefs.setStringList('pending_sync', pendingSync);
  }

  /// Sync in background
  void _syncInBackground(String email, String password) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (await _hasInternet()) {
        await _remoteAuth.login(email: email, password: password);
      }
    } catch (e) {
      print('Background sync failed: $e');
    }
  }
}

// ============================================================================
// ENHANCED AUTH RESULT
// ============================================================================

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final Map<String, dynamic>? metadata;

  AuthResult({
    required this.success,
    this.user,
    this.error,
    this.metadata,
  });
}