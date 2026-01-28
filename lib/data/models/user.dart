import 'package:equatable/equatable.dart';

/// User model representing a user in the Personal Haven app
class User extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isPremium;
  final Map<String, dynamic>? preferences;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.lastLoginAt,
    this.isPremium = false,
    this.preferences,
  });

  /// Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? username ?? email.split('@').first;
  }

  /// Get display name (first name or username)
  String get displayName {
    return firstName ?? username ?? email.split('@').first;
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isPremium,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isPremium: isPremium ?? this.isPremium,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_premium': isPremium ? 1 : 0,
      'preferences_json': preferences?.toString(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['user_id'] as String,
      email: map['email'] as String,
      username: map['username'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
      isPremium: map['is_premium'] == 1,
      preferences: null, // Parse JSON if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isPremium': isPremium,
      'preferences': preferences,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        firstName,
        lastName,
        avatarUrl,
        bio,
        createdAt,
        lastLoginAt,
        isPremium,
        preferences,
      ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $fullName)';
  }
}

class UserCredentials {
  final String userId;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserCredentials({
    required this.userId,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserCredentials.fromMap(Map<String, dynamic> map) {
    return UserCredentials(
      userId: map['user_id'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }
}
