import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';

/// User model for data layer with JSON serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    required super.createdAt,
    required super.settings,
  });

  /// Create UserModel from UserEntity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      settings: entity.settings,
    );
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data, doc.id);
  }

  /// Create UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      settings: json['settings'] != null
          ? UserSettingsModel.fromJson(json['settings'] as Map<String, dynamic>)
          : UserSettings.defaults(),
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': UserSettingsModel.fromEntity(settings).toJson(),
    };
  }

  /// Create a new user model for registration
  factory UserModel.newUser({
    required String id,
    required String email,
    String? displayName,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: null,
      createdAt: DateTime.now(),
      settings: UserSettings.defaults(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }
}

/// User settings model with JSON serialization
class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    super.speedAlertEnabled,
    super.speedLimitKmh,
    super.geofenceAlertEnabled,
    super.pushNotificationsEnabled,
  });

  /// Create from UserSettings entity
  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      speedAlertEnabled: entity.speedAlertEnabled,
      speedLimitKmh: entity.speedLimitKmh,
      geofenceAlertEnabled: entity.geofenceAlertEnabled,
      pushNotificationsEnabled: entity.pushNotificationsEnabled,
    );
  }

  /// Create from JSON map
  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      speedAlertEnabled: json['speedAlertEnabled'] as bool? ?? true,
      speedLimitKmh: (json['speedLimitKmh'] as num?)?.toDouble() ?? 120.0,
      geofenceAlertEnabled: json['geofenceAlertEnabled'] as bool? ?? true,
      pushNotificationsEnabled:
          json['pushNotificationsEnabled'] as bool? ?? true,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'speedAlertEnabled': speedAlertEnabled,
      'speedLimitKmh': speedLimitKmh,
      'geofenceAlertEnabled': geofenceAlertEnabled,
      'pushNotificationsEnabled': pushNotificationsEnabled,
    };
  }
}
