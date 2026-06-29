import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/environment/firebase_config.dart';
import 'core/network/network_info.dart';
import 'core/permissions/permission_handler.dart';
import 'core/permissions/permission_handler_impl.dart';
import 'core/utils/image_compressor.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/user_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/auth_state_changes.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/send_password_reset.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up_with_email.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/vehicles/data/datasources/tracker_remote_datasource.dart';
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

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  //============================================================================
  // External Dependencies
  //============================================================================

  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseConfig.getFirestore());
  sl.registerLazySingleton<FirebaseDatabase>(() => FirebaseConfig.getRealtimeDatabase());
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseConfig.getStorage());

  // Connectivity
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  //============================================================================
  // Core
  //============================================================================

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );

  sl.registerLazySingleton<AppPermissionHandler>(
    () => AppPermissionHandlerImpl(),
  );

  sl.registerLazySingleton<ImageCompressor>(
    () => ImageCompressorImpl(),
  );

  //============================================================================
  // Features - Auth
  //============================================================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authRemoteDataSource: sl(),
      userRemoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));
  sl.registerLazySingleton(() => AuthStateChanges(sl()));

  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      signInWithEmail: sl(),
      signUpWithEmail: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
      sendPasswordReset: sl(),
      authStateChanges: sl(),
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

  sl.registerLazySingleton<VehicleImageDataSource>(
    () => VehicleImageDataSourceImpl(
      storage: sl(),
      imageCompressor: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(
      vehicleDataSource: sl(),
      imageDataSource: sl(),
      trackerDataSource: sl(),
      firebaseAuth: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<TrackerRepository>(
    () => TrackerRepositoryImpl(
      trackerDataSource: sl(),
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
    () => MapRepositoryImpl(
      mapDataSource: sl(),
      networkInfo: sl(),
    ),
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
}
