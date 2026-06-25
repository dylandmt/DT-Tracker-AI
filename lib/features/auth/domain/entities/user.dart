import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final UserSettings settings;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.settings,
  });

  /// Create a copy with modified fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    UserSettings? settings,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        createdAt,
        settings,
      ];
}

/// User settings/preferences
class UserSettings extends Equatable {
  final bool speedAlertEnabled;
  final double speedLimitKmh;
  final bool geofenceAlertEnabled;
  final bool pushNotificationsEnabled;

  const UserSettings({
    this.speedAlertEnabled = true,
    this.speedLimitKmh = 120.0,
    this.geofenceAlertEnabled = true,
    this.pushNotificationsEnabled = true,
  });

  /// Default settings
  factory UserSettings.defaults() {
    return const UserSettings();
  }

  /// Create a copy with modified fields
  UserSettings copyWith({
    bool? speedAlertEnabled,
    double? speedLimitKmh,
    bool? geofenceAlertEnabled,
    bool? pushNotificationsEnabled,
  }) {
    return UserSettings(
      speedAlertEnabled: speedAlertEnabled ?? this.speedAlertEnabled,
      speedLimitKmh: speedLimitKmh ?? this.speedLimitKmh,
      geofenceAlertEnabled: geofenceAlertEnabled ?? this.geofenceAlertEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        speedAlertEnabled,
        speedLimitKmh,
        geofenceAlertEnabled,
        pushNotificationsEnabled,
      ];
}
