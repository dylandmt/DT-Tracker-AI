/// Firebase collection names and paths
class FirebaseConstants {
  FirebaseConstants._();

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String vehiclesCollection = 'vehicles';
  static const String geofencesCollection = 'geofences';
  static const String alertsCollection = 'alerts';
  static const String tripsCollection = 'trips';

  // Realtime Database Paths
  static const String liveLocationsPath = 'live_locations';

  // Storage Paths
  static const String vehicleImagesPath = 'vehicle_images';
  static const String userAvatarsPath = 'user_avatars';

  // Field Names - Common
  static const String fieldId = 'id';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';

  // Field Names - User
  static const String fieldEmail = 'email';
  static const String fieldDisplayName = 'displayName';
  static const String fieldPhotoUrl = 'photoUrl';
  static const String fieldSettings = 'settings';

  // Field Names - Vehicle
  static const String fieldName = 'name';
  static const String fieldPlateNumber = 'plateNumber';
  static const String fieldVehicleType = 'vehicleType';
  static const String fieldDeviceId = 'deviceId';
  static const String fieldOwnerId = 'ownerId';
  static const String fieldImageUrl = 'imageUrl';
  static const String fieldStatus = 'status';

  // Field Names - Location
  static const String fieldLatitude = 'latitude';
  static const String fieldLongitude = 'longitude';
  static const String fieldSpeed = 'speed';
  static const String fieldHeading = 'heading';
  static const String fieldAltitude = 'altitude';
  static const String fieldAccuracy = 'accuracy';
  static const String fieldTimestamp = 'timestamp';

  // Field Names - Geofence
  static const String fieldRadius = 'radius';
  static const String fieldIsActive = 'isActive';
  static const String fieldUserId = 'userId';

  // Field Names - Alert
  static const String fieldType = 'type';
  static const String fieldVehicleId = 'vehicleId';
  static const String fieldVehicleName = 'vehicleName';
  static const String fieldMessage = 'message';
  static const String fieldIsRead = 'isRead';
  static const String fieldData = 'data';
}
