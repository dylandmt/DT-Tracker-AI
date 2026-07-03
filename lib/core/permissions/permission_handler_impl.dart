import 'package:permission_handler/permission_handler.dart' as ph;

import 'permission_handler.dart';
import 'permission_status.dart';

/// Implementation of [AppPermissionHandler] using the permission_handler package
class AppPermissionHandlerImpl implements AppPermissionHandler {
  /// Convert [AppPermission] to [ph.Permission]
  ph.Permission _toPackagePermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return ph.Permission.camera;
      case AppPermission.photos:
        return ph.Permission.photos;
      case AppPermission.location:
        return ph.Permission.locationWhenInUse;
      case AppPermission.locationAlways:
        return ph.Permission.locationAlways;
      case AppPermission.notification:
        return ph.Permission.notification;
      case AppPermission.storage:
        return ph.Permission.storage;
    }
  }

  /// Convert [ph.PermissionStatus] to [AppPermissionStatus]
  AppPermissionStatus _toAppStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return AppPermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      case ph.PermissionStatus.limited:
        return AppPermissionStatus.limited;
      case ph.PermissionStatus.provisional:
        return AppPermissionStatus.granted; // Treat provisional as granted
    }
  }

  @override
  Future<AppPermissionStatus> checkPermission(AppPermission permission) async {
    final packagePermission = _toPackagePermission(permission);
    final status = await packagePermission.status;
    return _toAppStatus(status);
  }

  @override
  Future<AppPermissionStatus> requestPermission(
    AppPermission permission,
  ) async {
    final packagePermission = _toPackagePermission(permission);
    final status = await packagePermission.request();
    return _toAppStatus(status);
  }

  @override
  Future<Map<AppPermission, AppPermissionStatus>> requestPermissions(
    List<AppPermission> permissions,
  ) async {
    final packagePermissions =
        permissions.map(_toPackagePermission).toList();

    final statuses = await packagePermissions.request();

    final result = <AppPermission, AppPermissionStatus>{};
    for (var i = 0; i < permissions.length; i++) {
      final permission = permissions[i];
      final packagePermission = packagePermissions[i];
      final status = statuses[packagePermission];
      if (status != null) {
        result[permission] = _toAppStatus(status);
      } else {
        result[permission] = AppPermissionStatus.unknown;
      }
    }

    return result;
  }

  @override
  Future<bool> isGranted(AppPermission permission) async {
    final status = await checkPermission(permission);
    return status.isGranted;
  }

  @override
  Future<bool> openSettings() async {
    return await ph.openAppSettings();
  }

  @override
  Future<bool> ensurePermission(AppPermission permission) async {
    var status = await checkPermission(permission);

    if (status.isGranted) {
      return true;
    }

    if (status.canRequest) {
      status = await requestPermission(permission);
    }

    return status.isGranted;
  }

  @override
  Future<bool> requiresSettings(AppPermission permission) async {
    final status = await checkPermission(permission);
    return status.requiresSettings;
  }
}
