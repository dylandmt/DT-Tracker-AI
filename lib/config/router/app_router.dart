import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/utils/extensions.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/setup/presentation/pages/setup_permissions_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/geofences/presentation/bloc/geofence_bloc.dart';
import '../../features/geofences/presentation/pages/geofence_form_page.dart';
import '../../features/geofences/presentation/pages/geofences_page.dart';
import '../../features/events/presentation/bloc/events_bloc.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/alerts_settings_page.dart';
import '../../features/settings/presentation/pages/security_pin_page.dart';
import '../../features/vehicles/presentation/bloc/tracker_link_bloc.dart';
import '../../features/vehicles/presentation/bloc/vehicle_form_bloc.dart';
import '../../features/vehicles/presentation/bloc/vehicles_bloc.dart';
import '../../features/vehicles/presentation/pages/link_tracker_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_form_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';
import '../../features/trips/presentation/bloc/trip_bloc.dart';
import '../../features/trips/presentation/pages/trips_page.dart';
import '../../injection_container.dart';

/// Application router configuration using GoRouter
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: RouteConstants.splash,
        name: RouteConstants.splashName,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthBloc>()..add(CheckAuthStatus()),
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        name: RouteConstants.onboardingName,
        builder: (_, state) =>
            OnboardingPage(userId: state.uri.queryParameters['userId']!),
      ),
      GoRoute(
        path: RouteConstants.login,
        name: RouteConstants.loginName,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: RouteConstants.register,
        name: RouteConstants.registerName,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: RouteConstants.forgotPassword,
        name: RouteConstants.forgotPasswordName,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const ForgotPasswordPage(),
        ),
      ),
      // Setup permissions
      GoRoute(
        path: RouteConstants.setup,
        name: RouteConstants.setupName,
        builder: (context, state) => const SetupPermissionsPage(),
      ),
      GoRoute(
        path: RouteConstants.setupSecurityPin,
        name: RouteConstants.setupSecurityPinName,
        builder: (context, state) => const SecurityPinPage(isSetup: true),
      ),

      // Redirect /home to /home/vehicles
      GoRoute(
        path: RouteConstants.home,
        name: RouteConstants.homeName,
        redirect: (_, __) => RouteConstants.homeVehicles,
      ),

      // Full-screen routes outside the home navigation shell.
      GoRoute(
        path: RouteConstants.geofences,
        name: RouteConstants.geofencesName,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<GeofenceBloc>(),
          child: const GeofencesPage(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            name: RouteConstants.geofenceAddName,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<GeofenceBloc>(),
              child: const GeofenceFormPage(),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            name: RouteConstants.geofenceEditName,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<GeofenceBloc>(),
              child: GeofenceFormPage(geofenceId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.alerts,
        name: RouteConstants.alertsName,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<EventsBloc>(),
          child: const EventsPage(),
        ),
      ),

      // Shell route with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // Provide AuthBloc at shell level for settings page
          return BlocProvider(
            create: (_) => sl<AuthBloc>()..add(CheckAuthStatus()),
            child: HomePage(child: child),
          );
        },
        routes: [
          // Vehicles tab
          GoRoute(
            path: RouteConstants.homeVehicles,
            name: RouteConstants.homeVehiclesName,
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => sl<VehiclesBloc>(),
                child: const VehiclesPage(),
              ),
            ),
            routes: [
              // Add vehicle
              GoRoute(
                path: 'add',
                name: RouteConstants.vehicleAddName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<VehicleFormBloc>(),
                  child: const VehicleFormPage(),
                ),
              ),
              // Vehicle detail
              GoRoute(
                path: ':id',
                name: RouteConstants.vehicleDetailName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final vehicleId = state.pathParameters['id']!;
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(create: (_) => sl<VehiclesBloc>()),
                      BlocProvider(create: (_) => sl<VehicleFormBloc>()),
                      BlocProvider(create: (_) => sl<TrackerLinkBloc>()),
                    ],
                    child: VehicleDetailPage(vehicleId: vehicleId),
                  );
                },
                routes: [
                  // Edit vehicle
                  GoRoute(
                    path: 'edit',
                    name: RouteConstants.vehicleEditName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final vehicleId = state.pathParameters['id']!;
                      return BlocProvider(
                        create: (_) => sl<VehicleFormBloc>(),
                        child: VehicleFormPage(vehicleId: vehicleId),
                      );
                    },
                  ),
                  // Link tracker
                  GoRoute(
                    path: 'link-tracker',
                    name: RouteConstants.vehicleLinkTrackerName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final vehicleId = state.pathParameters['id']!;
                      return BlocProvider(
                        create: (_) => sl<TrackerLinkBloc>(),
                        child: LinkTrackerPage(vehicleId: vehicleId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Map tab
          GoRoute(
            path: RouteConstants.homeMap,
            name: RouteConstants.homeMapName,
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<MapBloc>()),
                  BlocProvider(
                    create: (_) =>
                        sl<GeofenceBloc>()
                          ..add(const WatchGeofencesRequested()),
                  ),
                ],
                child: const MapPage(),
              ),
            ),
          ),

          GoRoute(
            path: RouteConstants.homeTrips,
            name: RouteConstants.homeTripsName,
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => sl<TripBloc>(),
                child: const TripsPage(),
              ),
            ),
          ),

          // Settings tab
          GoRoute(
            path: RouteConstants.homeSettings,
            name: RouteConstants.homeSettingsName,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
            routes: [
              GoRoute(
                path: 'profile',
                name: RouteConstants.profileName,
                builder: (context, state) => const ProfilePage(),
              ),
              GoRoute(
                path: 'security-pin',
                name: RouteConstants.securityPinName,
                builder: (context, state) =>
                    const SecurityPinPage(isSetup: false),
              ),
              GoRoute(
                path: 'alerts',
                name: RouteConstants.alertsSettingsName,
                builder: (context, state) => const AlertsSettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.pageNotFound,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(RouteConstants.splash),
              child: Text(context.l10n.goHome),
            ),
          ],
        ),
      ),
    ),
  );
}
