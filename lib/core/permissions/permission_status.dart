/// Permission status enum for the app
enum AppPermissionStatus {
  /// Permission has been granted
  granted,

  /// Permission has been denied (can be requested again)
  denied,

  /// Permission has been permanently denied (must open settings)
  permanentlyDenied,

  /// Permission is restricted (iOS only - parental controls, etc.)
  restricted,

  /// Limited access granted (iOS photo library - limited selection)
  limited,

  /// Permission status is unknown
  unknown,
}

/// App permission types
enum AppPermission {
  /// Camera access for taking photos
  camera,

  /// Photo library access for selecting images
  photos,

  /// Location access (when in use)
  location,

  /// Location access (always, including background)
  locationAlways,

  /// Push notification permission
  notification,

  /// Storage access (Android only)
  storage,
}

/// Extension methods for AppPermissionStatus
extension AppPermissionStatusX on AppPermissionStatus {
  /// Whether the permission is granted or limited
  bool get isGranted =>
      this == AppPermissionStatus.granted ||
      this == AppPermissionStatus.limited;

  /// Whether the permission can be requested again
  bool get canRequest =>
      this == AppPermissionStatus.denied ||
      this == AppPermissionStatus.unknown;

  /// Whether the user must go to settings to grant permission
  bool get requiresSettings =>
      this == AppPermissionStatus.permanentlyDenied ||
      this == AppPermissionStatus.restricted;
}
