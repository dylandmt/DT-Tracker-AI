import '../../../core/constants/route_constants.dart';

/// Decides the post-auth route based on the required permissions.
/// Returns RouteConstants.home when all permissions are granted.
String resolvePostAuthRoute({
  required bool hasLocation,
  required bool hasNotifications,
}) {
  if (hasLocation && hasNotifications) {
    return RouteConstants.home;
  }
  return RouteConstants.setup;
}
