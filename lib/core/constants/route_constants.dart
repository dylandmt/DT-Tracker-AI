/// Route path constants for navigation
class RouteConstants {
  RouteConstants._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Routes (with bottom nav)
  static const String home = '/home';
  static const String homeVehicles = '/home/vehicles';
  static const String homeMap = '/home/map';
  static const String homeSettings = '/home/settings';

  // Vehicle Routes (nested under home)
  static const String vehicleAdd = '/home/vehicles/add';
  static const String vehicleDetail = '/home/vehicles/:id';
  static const String vehicleEdit = '/home/vehicles/:id/edit';
  static const String vehicleLinkTracker = '/home/vehicles/:id/link-tracker';

  // Legacy route aliases (for backwards compatibility)
  static const String vehicles = '/home/vehicles';
  static const String map = '/home/map';

  // Geofence Routes
  static const String geofences = '/geofences';
  static const String geofenceAdd = '/geofences/add';
  static const String geofenceEdit = '/geofences/:id/edit';

  // Alert Routes
  static const String alerts = '/alerts';
  static const String alertDetail = '/alerts/:id';

  // Settings Routes
  static const String settings = '/settings';
  static const String profile = '/settings/profile';

  // Route Names
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgotPassword';
  static const String homeName = 'home';
  static const String homeVehiclesName = 'homeVehicles';
  static const String homeMapName = 'homeMap';
  static const String homeSettingsName = 'homeSettings';
  static const String vehiclesName = 'vehicles';
  static const String vehicleDetailName = 'vehicleDetail';
  static const String vehicleAddName = 'vehicleAdd';
  static const String vehicleEditName = 'vehicleEdit';
  static const String vehicleLinkTrackerName = 'vehicleLinkTracker';
  static const String mapName = 'map';
  static const String geofencesName = 'geofences';
  static const String geofenceAddName = 'geofenceAdd';
  static const String geofenceEditName = 'geofenceEdit';
  static const String alertsName = 'alerts';
  static const String alertDetailName = 'alertDetail';
  static const String settingsName = 'settings';
  static const String profileName = 'profile';
}
