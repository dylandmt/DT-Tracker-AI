/// Route path constants for navigation
class RouteConstants {
  RouteConstants._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Routes
  static const String home = '/home';
  static const String map = '/map';

  // Vehicle Routes
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static const String vehicleAdd = '/vehicles/add';
  static const String vehicleEdit = '/vehicles/:id/edit';

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
  static const String mapName = 'map';
  static const String vehiclesName = 'vehicles';
  static const String vehicleDetailName = 'vehicleDetail';
  static const String vehicleAddName = 'vehicleAdd';
  static const String vehicleEditName = 'vehicleEdit';
  static const String geofencesName = 'geofences';
  static const String geofenceAddName = 'geofenceAdd';
  static const String geofenceEditName = 'geofenceEdit';
  static const String alertsName = 'alerts';
  static const String alertDetailName = 'alertDetail';
  static const String settingsName = 'settings';
  static const String profileName = 'profile';
}
