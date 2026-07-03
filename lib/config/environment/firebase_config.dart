import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'environment.dart';

/// Factory class to create Firebase instances configured for the current environment
class FirebaseConfig {
  FirebaseConfig._();

  static FirebaseFirestore? _firestoreInstance;
  static FirebaseDatabase? _databaseInstance;
  static FirebaseStorage? _storageInstance;

  /// Get Firestore instance configured for current environment's database
  /// Uses named database: 'dttracker-dev' or 'dttracker-prod'
  static FirebaseFirestore getFirestore() {
    _firestoreInstance ??= FirebaseFirestore.instanceFor(
      app: FirebaseFirestore.instance.app,
      databaseId: EnvironmentConfig.firestoreDatabase,
    );
    return _firestoreInstance!;
  }

  /// Get Realtime Database instance configured for current environment
  /// Uses database URL: 'https://dttracker-dev-01.firebaseio.com' or prod equivalent
  static FirebaseDatabase getRealtimeDatabase() {
    _databaseInstance ??= FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: EnvironmentConfig.realtimeDatabaseUrl,
    );
    return _databaseInstance!;
  }

  /// Get Firebase Storage instance configured for current environment's bucket
  /// Uses separate bucket: 'gs://dttracker-dev-01' or 'gs://dttracker-prod-01'
  static FirebaseStorage getStorage() {
    _storageInstance ??= FirebaseStorage.instanceFor(
      app: FirebaseStorage.instance.app,
      bucket: EnvironmentConfig.storageUrl,
    );
    return _storageInstance!;
  }

  /// Log current configuration (useful for debugging)
  static void logConfiguration() {
    print('═══════════════════════════════════════════════════════');
    print('🔧 Firebase Environment Configuration');
    print('═══════════════════════════════════════════════════════');
    print('Environment:      ${EnvironmentConfig.name}');
    print('Firestore DB:     ${EnvironmentConfig.firestoreDatabase}');
    print('RTDB URL:         ${EnvironmentConfig.realtimeDatabaseUrl}');
    print('Storage Bucket:   ${EnvironmentConfig.storageUrl}');
    print('═══════════════════════════════════════════════════════');
  }
}