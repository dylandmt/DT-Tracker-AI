/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'DT Tracker';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Location Settings
  static const int locationUpdateIntervalSeconds = 10;
  static const int locationDistanceFilterMeters = 10;
  static const double defaultMapZoom = 15.0;

  // Speed Settings (km/h)
  static const double defaultSpeedLimitKmh = 120.0;

  // Geofence Settings
  static const double defaultGeofenceRadiusMeters = 500.0;
  static const double minGeofenceRadiusMeters = 100.0;
  static const double maxGeofenceRadiusMeters = 10000.0;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheValidDuration = Duration(hours: 1);
}
