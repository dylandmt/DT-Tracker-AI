import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import 'package:geolocator/geolocator.dart';
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
          // Gate by required permissions: location + notifications
          final handler = sl<AppPermissionHandler>();
          final hasLocation = await handler.isGranted(AppPermission.location);
          final hasNotifications = await handler.isGranted(
            AppPermission.notification,
          );

          // Also ensure location services are enabled
          final servicesEnabled = await Geolocator.isLocationServiceEnabled();

          final target = resolvePostAuthRoute(
            hasLocation: hasLocation,
            hasNotifications: hasNotifications,
            servicesEnabled: servicesEnabled,
          );
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
                'Real-time GPS Tracking',
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
