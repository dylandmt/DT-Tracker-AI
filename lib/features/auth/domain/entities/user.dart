import 'package:equatable/equatable.dart';

/// Supported user gender values.
enum UserGender { male, female, other, preferNotToSay }

/// User entity representing an authenticated user.
class UserEntity extends Equatable {
  final String id;
  final String email;

  final String? firstName;
  final String? lastName;
  final String? secondLastName;

  final UserGender? gender;
  final DateTime? birthDate;

  /// Kept for Firebase Auth and backwards compatibility.
  final String? displayName;

  final String? photoUrl;
  final DateTime createdAt;
  final UserSettings settings;

  const UserEntity({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.secondLastName,
    this.gender,
    this.birthDate,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.settings,
  });

  /// Full name generated from the structured name fields.
  ///
  /// Falls back to displayName for legacy users.
  String get fullName {
    final name = [firstName, lastName, secondLastName]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');

    if (name.isNotEmpty) {
      return name;
    }

    return displayName?.trim() ?? '';
  }

  /// Create a copy with modified fields.
  UserEntity copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? secondLastName,
    UserGender? gender,
    DateTime? birthDate,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    UserSettings? settings,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      secondLastName: secondLastName ?? this.secondLastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
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
    firstName,
    lastName,
    secondLastName,
    gender,
    birthDate,
    displayName,
    photoUrl,
    createdAt,
    settings,
  ];
}

/// User settings/preferences.
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

  /// Default settings.
  factory UserSettings.defaults() {
    return const UserSettings();
  }

  /// Create a copy with modified fields.
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
