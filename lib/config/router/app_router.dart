import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/vehicles/presentation/bloc/tracker_link_bloc.dart';
import '../../features/vehicles/presentation/bloc/vehicle_form_bloc.dart';
import '../../features/vehicles/presentation/bloc/vehicles_bloc.dart';
import '../../features/vehicles/presentation/pages/link_tracker_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_form_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';
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

      // Redirect /home to /home/vehicles
      GoRoute(
        path: RouteConstants.home,
        name: RouteConstants.homeName,
        redirect: (_, __) => RouteConstants.homeVehicles,
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
              child: BlocProvider(
                create: (_) => sl<MapBloc>(),
                child: const MapPage(),
              ),
            ),
          ),

          // Settings tab
          GoRoute(
            path: RouteConstants.homeSettings,
            name: RouteConstants.homeSettingsName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
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
              'Page not found',
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
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
