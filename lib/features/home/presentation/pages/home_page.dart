import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_navigation_bar.dart';

/// Home page shell with bottom navigation bar
class HomePage extends StatelessWidget {
  /// The child widget to display (current tab content)
  final Widget child;

  const HomePage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
      ),
    );
  }

  /// Calculate the current index based on the current location
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/home/map')) {
      return 1;
    }
    if (location.startsWith('/home/settings')) {
      return 2;
    }
    // Default to vehicles
    return 0;
  }

  /// Handle destination selection
  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home/vehicles');
        break;
      case 1:
        context.go('/home/map');
        break;
      case 2:
        context.go('/home/settings');
        break;
    }
  }
}
