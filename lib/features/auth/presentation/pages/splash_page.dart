import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/onboarding/onboarding_controller.dart';
import '../../../../core/utils/extensions.dart';
import '../../utils/permission_gate.dart';
import '../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';

/// Splash screen that checks authentication status
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.isAuthenticated) {
          final user = state.user!;
          if (!sl<OnboardingController>().hasCompletedGeneral(user.id)) {
            context.go('${RouteConstants.onboarding}?userId=${user.id}');
            return;
          }
          // Gate by required permissions: location + notifications
          final handler = sl<AppPermissionHandler>();
          final hasLocation = await handler.isGranted(AppPermission.location);
          final hasNotifications = await sl<NotificationService>()
              .notificationPermissionStatus()
              .then((status) => status.isGranted);

          final target = resolvePostAuthRoute(
            hasLocation: hasLocation,
            hasNotifications: hasNotifications,
          );
          if (!context.mounted) return;
          context.go(target);
        } else if (state.isUnauthenticated) {
          context.go(RouteConstants.login);
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 72,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.realTimeGpsTracking,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
