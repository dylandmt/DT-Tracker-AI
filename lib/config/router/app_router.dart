import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../injection_container.dart';

/// Application router configuration using GoRouter
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    routes: [
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
      GoRoute(
        path: RouteConstants.home,
        name: RouteConstants.homeName,
        builder: (context, state) => const _PlaceholderHomePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.toString(), style: Theme.of(context).textTheme.bodyMedium),
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

class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DT Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go(RouteConstants.login),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Welcome to DT Tracker!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Authentication successful.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Vehicle tracking features coming in Phase 4+', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
