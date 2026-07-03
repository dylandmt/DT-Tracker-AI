import 'permission_status.dart';

/// Abstract interface for handling app permissions
///
/// This provides a unified API for requesting and checking permissions
/// across the application, abstracting away platform-specific details.
abstract class AppPermissionHandler {
  /// Check the current status of a permission
  ///
  /// Returns the current [AppPermissionStatus] for the given [permission]
  Future<AppPermissionStatus> checkPermission(AppPermission permission);

  /// Request a single permission from the user
  ///
  /// Shows the system permission dialog if the permission can be requested.
  /// Returns the resulting [AppPermissionStatus] after the request.
  Future<AppPermissionStatus> requestPermission(AppPermission permission);

  /// Request multiple permissions at once
  ///
  /// Returns a map of [AppPermission] to [AppPermissionStatus] for all
  /// requested permissions.
  Future<Map<AppPermission, AppPermissionStatus>> requestPermissions(
    List<AppPermission> permissions,
  );

  /// Check if a permission is currently granted
  ///
  /// Returns true if the permission is granted or has limited access.
  Future<bool> isGranted(AppPermission permission);

  /// Open the app settings page
  ///
  /// Use this when a permission is permanently denied and the user
  /// needs to manually enable it in system settings.
  /// Returns true if the settings page was opened successfully.
  Future<bool> openSettings();

  /// Check permission and request if not granted
  ///
  /// This is a convenience method that checks the permission status
  /// and requests it if not already granted.
  /// Returns true if the permission is granted after the check/request.
  Future<bool> ensurePermission(AppPermission permission);

  /// Check if permission requires settings to be changed
  ///
  /// Returns true if the permission is permanently denied or restricted
  /// and requires the user to manually change settings.
  Future<bool> requiresSettings(AppPermission permission);
}
