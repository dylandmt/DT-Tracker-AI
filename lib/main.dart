import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/environment/firebase_config.dart';
import 'app.dart';
import 'core/localization/locale_controller.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (kDebugMode) {
    FirebaseConfig.logConfiguration();
  }
  await initializeDependencies();
  runApp(DTTrackerApp(localeController: sl<LocaleController>()));
}
