import 'package:flutter/material.dart';
import 'dart:async';

import 'config/router/app_router.dart';
import 'core/constants/route_constants.dart';
import 'core/localization/locale_controller.dart';
import 'core/notifications/notification_payload.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/environment_banner.dart';
import 'injection_container.dart';
import 'l10n/app_localizations.dart';

/// Main application widget
class DTTrackerApp extends StatefulWidget {
  const DTTrackerApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  State<DTTrackerApp> createState() => _DTTrackerAppState();
}

class _DTTrackerAppState extends State<DTTrackerApp> {
  StreamSubscription<NotificationPayload>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final notifications = sl<NotificationService>();
    _notificationSubscription = notifications.notificationActions.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.router.go(RouteConstants.alerts);
      });
    });
    notifications.initialize();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.localeController,
      builder: (context, child) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        locale: widget.localeController.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return EnvironmentBanner(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
