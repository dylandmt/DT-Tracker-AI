import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'config/environment/firebase_config.dart';
import 'config/environment/environment.dart';
import 'core/network/network_info.dart';
import 'core/onboarding/onboarding_controller.dart';
import 'core/localization/locale_controller.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/push_device_backend_datasource.dart';
import 'core/permissions/permission_handler.dart';
import 'core/permissions/permission_handler_impl.dart';
import 'core/security/tracker_security_service.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/image_compressor.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/profile_image_data_source.dart';
import 'features/auth/data/datasources/user_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/auth_state_changes.dart';
import 'features/auth/domain/usecases/delete_profile_image.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/send_password_reset.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up_with_email.dart';
import 'features/auth/domain/usecases/update_user_profile.dart';
import 'features/auth/domain/usecases/update_user_settings.dart';
import 'features/auth/domain/usecases/upload_profile_image.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/vehicles/data/datasources/tracker_remote_datasource.dart';
import 'features/vehicles/data/datasources/tracker_backend_datasource.dart';
import 'features/vehicles/data/datasources/vehicle_image_datasource.dart';
import 'features/vehicles/data/datasources/vehicle_remote_datasource.dart';
import 'features/vehicles/data/repositories/tracker_repository_impl.dart';
import 'features/vehicles/data/repositories/vehicle_repository_impl.dart';
import 'features/vehicles/domain/repositories/tracker_repository.dart';
import 'features/vehicles/domain/repositories/vehicle_repository.dart';
import 'features/vehicles/domain/usecases/create_vehicle.dart';
import 'features/vehicles/domain/usecases/delete_vehicle.dart';
import 'features/vehicles/domain/usecases/delete_vehicle_image.dart';
import 'features/vehicles/domain/usecases/get_tracker_info.dart';
import 'features/vehicles/domain/usecases/get_vehicle_by_id.dart';
import 'features/vehicles/domain/usecases/get_vehicles.dart';
import 'features/vehicles/domain/usecases/link_tracker.dart';
import 'features/vehicles/domain/usecases/unlink_tracker.dart';
import 'features/vehicles/domain/usecases/update_vehicle.dart';
import 'features/vehicles/domain/usecases/upload_vehicle_image.dart';
import 'features/vehicles/domain/usecases/watch_vehicles.dart';
import 'features/vehicles/presentation/bloc/tracker_link_bloc.dart';
import 'features/vehicles/presentation/bloc/vehicle_form_bloc.dart';
import 'features/vehicles/presentation/bloc/vehicles_bloc.dart';
import 'features/map/data/datasources/map_remote_datasource.dart';
import 'features/map/data/repositories/map_repository_impl.dart';
import 'features/map/domain/repositories/map_repository.dart';
import 'features/map/domain/usecases/get_vehicle_locations.dart';
import 'features/map/domain/usecases/get_vehicle_location.dart';
import 'features/map/domain/usecases/get_trip_history.dart';
import 'features/map/presentation/bloc/map_bloc.dart';
import 'features/geofences/data/datasources/geofence_remote_datasource.dart';
import 'features/geofences/data/repositories/geofence_repository_impl.dart';
import 'features/geofences/domain/repositories/geofence_repository.dart';
import 'features/geofences/domain/usecases/geofence_usecases.dart';
import 'features/geofences/presentation/bloc/geofence_bloc.dart';
import 'features/events/data/datasources/event_remote_datasource.dart';
import 'features/events/data/repositories/event_repository_impl.dart';
import 'features/events/domain/repositories/event_repository.dart';
import 'features/events/domain/usecases/event_usecases.dart';
import 'features/events/presentation/bloc/events_bloc.dart';
import 'features/trips/data/datasources/trip_remote_datasource.dart';
import 'features/trips/data/repositories/trip_repository_impl.dart';
import 'features/trips/domain/repositories/trip_repository.dart';
import 'features/trips/domain/usecases/trip_usecases.dart';
import 'features/trips/presentation/bloc/trip_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  //============================================================================
  // External Dependencies
  //============================================================================

  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseConfig.getFirestore(),
  );
  sl.registerLazySingleton<FirebaseDatabase>(
    () => FirebaseConfig.getRealtimeDatabase(),
  );
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseConfig.getStorage());
  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
  sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    FlutterLocalNotificationsPlugin.new,
  );
  sl.registerLazySingleton<Uuid>(Uuid.new);
  sl.registerLazySingleton<FlutterSecureStorage>(FlutterSecureStorage.new);
  sl.registerLazySingleton<LocalAuthentication>(LocalAuthentication.new);

  // Connectivity
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<LocaleController>(() => LocaleController(sl()));
  sl.registerLazySingleton<ThemeController>(() => ThemeController(sl()));
  sl.registerLazySingleton<OnboardingController>(
    () => OnboardingController(sl()),
  );

  //============================================================================
  // Core
  //============================================================================

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );

  sl.registerLazySingleton<AppPermissionHandler>(
    () => AppPermissionHandlerImpl(),
  );

  sl.registerLazySingleton<ImageCompressor>(() => ImageCompressorImpl());
  sl.registerLazySingleton<TrackerSecurityService>(
    () => TrackerSecurityService(
      firebaseAuth: sl(),
      storage: sl(),
      localAuthentication: sl(),
    ),
  );

  sl.registerLazySingleton<PushDeviceBackendDataSource>(
    () => PushDeviceBackendDataSource(firebaseAuth: sl()),
  );
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(
      messaging: sl(),
      localNotifications: sl(),
      preferences: sl(),
      uuid: sl(),
      backendDataSource: sl(),
    ),
  );

  //============================================================================
  // Features - Auth
  //============================================================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<ProfileImageDataSource>(
    () => ProfileImageDataSourceImpl(storage: sl(), imageCompressor: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authRemoteDataSource: sl(),
      userRemoteDataSource: sl(),
      profileImageDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));
  sl.registerLazySingleton(() => AuthStateChanges(sl()));
  sl.registerLazySingleton(() => UpdateUserProfile(sl()));
  sl.registerLazySingleton(() => UploadProfileImage(sl()));
  sl.registerLazySingleton(() => DeleteProfileImage(sl()));
  sl.registerLazySingleton(() => UpdateUserSettings(sl()));

  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      signInWithEmail: sl(),
      signInWithGoogle: sl(),
      signUpWithEmail: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
      sendPasswordReset: sl(),
      authStateChanges: sl(),
      updateUserProfile: sl(),
      uploadProfileImage: sl(),
      deleteProfileImage: sl(),
      updateUserSettings: sl(),
    ),
  );

  //============================================================================
  // Features - Trips
  //============================================================================
  sl.registerLazySingleton<TripRemoteDataSource>(
    () => TripRemoteDataSourceImpl(firebaseAuth: sl()),
  );
  sl.registerLazySingleton<TripRepository>(
    () => TripRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => StartTrip(sl()));
  sl.registerLazySingleton(() => GetActiveTrip(sl()));
  sl.registerLazySingleton(() => GetTrips(sl()));
  sl.registerLazySingleton(() => GetTrip(sl()));
  sl.registerLazySingleton(() => EndTrip(sl()));
  sl.registerFactory(
    () => TripBloc(
      getActiveTrip: sl(),
      getTrips: sl(),
      getTrip: sl(),
      startTrip: sl(),
      endTrip: sl(),
      getVehicles: sl(),
    ),
  );

  //============================================================================
  // Features - Vehicles
  //============================================================================

  // Data Sources
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<TrackerRemoteDataSource>(
    () => TrackerRemoteDataSourceImpl(database: sl()),
  );

  // Backend Data Source (secure endpoints)
  sl.registerLazySingleton<TrackerBackendDataSource>(
    () => TrackerBackendDataSource(
      firebaseAuth: sl(),
      baseUrl: EnvironmentConfig.apiBaseUrl,
    ),
  );

  sl.registerLazySingleton<VehicleImageDataSource>(
    () => VehicleImageDataSourceImpl(storage: sl(), imageCompressor: sl()),
  );

  // Repositories
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(
      vehicleDataSource: sl(),
      imageDataSource: sl(),
      backendDataSource: sl(),
      firebaseAuth: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<TrackerRepository>(
    () => TrackerRepositoryImpl(
      trackerDataSource: sl(),
      backendDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetVehicles(sl()));
  sl.registerLazySingleton(() => GetVehicleById(sl()));
  sl.registerLazySingleton(() => WatchVehicles(sl()));
  sl.registerLazySingleton(() => CreateVehicle(sl()));
  sl.registerLazySingleton(() => UpdateVehicle(sl()));
  sl.registerLazySingleton(() => DeleteVehicle(sl()));
  sl.registerLazySingleton(() => UploadVehicleImage(sl()));
  sl.registerLazySingleton(() => DeleteVehicleImage(sl()));
  sl.registerLazySingleton(() => LinkTracker(sl()));
  sl.registerLazySingleton(() => UnlinkTracker(sl()));
  sl.registerLazySingleton(() => GetTrackerInfo(sl()));
  sl.registerLazySingleton(() => IsTrackerAvailable(sl()));
  sl.registerLazySingleton(() => GetTrackerLive(sl()));
  sl.registerLazySingleton(() => WatchTrackerLive(sl()));
  sl.registerLazySingleton(() => GetTrackerStatus(sl()));
  sl.registerLazySingleton(() => WatchTrackerStatus(sl()));

  // BLoCs
  sl.registerFactory(
    () => VehiclesBloc(
      getVehicles: sl(),
      watchVehicles: sl(),
      deleteVehicle: sl(),
    ),
  );

  sl.registerFactory(
    () => VehicleFormBloc(
      createVehicle: sl(),
      updateVehicle: sl(),
      getVehicleById: sl(),
      uploadVehicleImage: sl(),
      deleteVehicleImage: sl(),
    ),
  );

  sl.registerFactory(
    () => TrackerLinkBloc(
      getTrackerInfo: sl(),
      isTrackerAvailable: sl(),
      linkTracker: sl(),
      unlinkTracker: sl(),
    ),
  );

  //============================================================================
  // Features - Map (Phase 5)
  //============================================================================

  // Data Sources
  sl.registerLazySingleton<MapRemoteDataSource>(
    () => MapRemoteDataSourceImpl(
      firestore: sl(),
      database: sl(),
      firebaseAuth: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(mapDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetVehicleLocations(sl()));
  sl.registerLazySingleton(() => WatchVehicleLocations(sl()));
  sl.registerLazySingleton(() => GetVehicleLocation(sl()));
  sl.registerLazySingleton(() => WatchVehicleLocation(sl()));
  sl.registerLazySingleton(() => GetTripHistory(sl()));
  sl.registerLazySingleton(() => GetDayTripPoints(sl()));

  // BLoCs
  sl.registerFactory(
    () => MapBloc(
      getVehicleLocations: sl(),
      watchVehicleLocations: sl(),
      getTripHistory: sl(),
      getDayTripPoints: sl(),
    ),
  );

  //============================================================================
  // Features - Geofences
  //============================================================================

  sl.registerLazySingleton<GeofenceRemoteDataSource>(
    () => GeofenceRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<GeofenceRepository>(
    () => GeofenceRepositoryImpl(
      dataSource: sl(),
      firebaseAuth: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetGeofences(sl()));
  sl.registerLazySingleton(() => GetGeofenceById(sl()));
  sl.registerLazySingleton(() => WatchGeofences(sl()));
  sl.registerLazySingleton(() => CreateGeofence(sl()));
  sl.registerLazySingleton(() => UpdateGeofence(sl()));
  sl.registerLazySingleton(() => DeleteGeofence(sl()));
  sl.registerFactory(
    () => GeofenceBloc(
      getGeofences: sl(),
      getGeofenceById: sl(),
      watchGeofences: sl(),
      createGeofence: sl(),
      updateGeofence: sl(),
      deleteGeofence: sl(),
    ),
  );

  //============================================================================
  // Features - Events
  //============================================================================

  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(
      dataSource: sl(),
      firebaseAuth: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => WatchEvents(sl()));
  sl.registerLazySingleton(() => MarkEventAsRead(sl()));
  sl.registerLazySingleton(() => ArchiveEvent(sl()));
  sl.registerFactory(
    () => EventsBloc(
      watchEvents: sl(),
      markEventAsRead: sl(),
      archiveEvent: sl(),
    ),
  );
}
