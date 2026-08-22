import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';

/// User model for data layer with JSON serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.secondLastName,
    super.gender,
    super.birthDate,
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
      firstName: entity.firstName,
      lastName: entity.lastName,
      secondLastName: entity.secondLastName,
      gender: entity.gender,
      birthDate: entity.birthDate,
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
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      secondLastName: json['secondLastName'] as String?,
      gender: _parseGender(json['gender']),
      birthDate: _parseNullableDateTime(json['birthDate']),
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
      'firstName': firstName,
      'lastName': lastName,
      'secondLastName': secondLastName,
      'gender': gender?.name,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': UserSettingsModel.fromEntity(settings).toJson(),
    };
  }

  /// Create a new user model for registration.
  ///
  /// firstName and lastName are optional here so this factory can
  /// also support legacy/recovery flows where only Firebase
  /// displayName is available.
  factory UserModel.newUser({
    required String id,
    required String email,
    String? firstName,
    String? lastName,
    String? secondLastName,
    UserGender? gender,
    DateTime? birthDate,
    String? legacyDisplayName,
  }) {
    final normalizedFirstName = _normalizeString(firstName);

    final normalizedLastName = _normalizeString(lastName);

    final normalizedSecondLastName = _normalizeString(secondLastName);

    final fullName = [
      normalizedFirstName,
      normalizedLastName,
      normalizedSecondLastName,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');

    return UserModel(
      id: id,
      email: email.trim(),
      firstName: normalizedFirstName,
      lastName: normalizedLastName,
      secondLastName: normalizedSecondLastName,
      gender: gender,
      birthDate: birthDate,
      displayName: fullName.isNotEmpty
          ? fullName
          : _normalizeString(legacyDisplayName),
      photoUrl: null,
      createdAt: DateTime.now(),
      settings: UserSettings.defaults(),
    );
  }

  static String? _normalizeString(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();

    return normalized.isEmpty ? null : normalized;
  }

  static UserGender? _parseGender(dynamic value) {
    if (value == null) {
      return null;
    }

    final rawValue = value.toString();

    for (final gender in UserGender.values) {
      if (gender.name == rawValue) {
        return gender;
      }
    }

    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

/// User settings model with JSON serialization
class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    super.speedAlertEnabled,
    super.speedLimitKmh,
    super.geofenceAlertEnabled,
    super.pushNotificationsEnabled,
    super.emailNotificationsEnabled,
  });

  /// Create from UserSettings entity
  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      speedAlertEnabled: entity.speedAlertEnabled,
      speedLimitKmh: entity.speedLimitKmh,
      geofenceAlertEnabled: entity.geofenceAlertEnabled,
      pushNotificationsEnabled: entity.pushNotificationsEnabled,
      emailNotificationsEnabled: entity.emailNotificationsEnabled,
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
      emailNotificationsEnabled:
          json['emailNotificationsEnabled'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'speedAlertEnabled': speedAlertEnabled,
      'speedLimitKmh': speedLimitKmh,
      'geofenceAlertEnabled': geofenceAlertEnabled,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
    };
  }
}
