import '../../../core/constants/route_constants.dart';

/// Decide the post-auth route based on permissions and services state.
/// Returns RouteConstants.home when all conditions are satisfied, otherwise RouteConstants.setup.
String resolvePostAuthRoute({
  required bool hasLocation,
  required bool hasNotifications,
  required bool servicesEnabled,
}) {
  if (hasLocation && hasNotifications && servicesEnabled) {
    return RouteConstants.home;
  }
  return RouteConstants.setup;
}
