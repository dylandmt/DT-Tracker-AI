import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/environment/firebase_config.dart';
import 'config/environment/environment.dart';
import 'app.dart';
import 'core/localization/locale_controller.dart';
import 'core/notifications/firebase_messaging_background_handler.dart';
import 'core/theme/theme_controller.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();

  final configuredTenantId = EnvironmentConfig.firebaseAuthTenantId;

  FirebaseAuth.instance.tenantId = configuredTenantId;

  final currentUser = FirebaseAuth.instance.currentUser;

  if (configuredTenantId != null &&
      currentUser != null &&
      currentUser.tenantId != configuredTenantId) {
    await FirebaseAuth.instance.signOut();
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    FirebaseConfig.logConfiguration();
  }

  await initializeDependencies();

  runApp(
    DTTrackerApp(
      localeController: sl<LocaleController>(),
      themeController: sl<ThemeController>(),
    ),
  );
}
