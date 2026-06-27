import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'config/environment/firebase_config.dart';
import 'app.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (kDebugMode) {
    FirebaseConfig.logConfiguration();
  }
  await initializeDependencies();
  runApp(const DTTrackerApp());
}
