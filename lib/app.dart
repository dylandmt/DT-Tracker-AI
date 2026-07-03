import 'package:flutter/material.dart';

import 'config/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/environment_banner.dart';

/// Main application widget
class DTTrackerApp extends StatelessWidget {
  const DTTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return EnvironmentBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
