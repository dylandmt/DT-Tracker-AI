import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/environment/firebase_config.dart';
import 'app.dart';
import 'core/localization/locale_controller.dart';
import 'core/notifications/firebase_messaging_background_handler.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  if (kDebugMode) {
    FirebaseConfig.logConfiguration();
  }
  await initializeDependencies();
  runApp(DTTrackerApp(localeController: sl<LocaleController>()));
}
