import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/get_vehicles.dart';
import '../widgets/app_navigation_bar.dart';

/// Home page shell with bottom navigation bar
class HomePage extends StatefulWidget {
  /// The child widget to display (current tab content)
  final Widget child;

  const HomePage({super.key, required this.child});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadEntitlements();
  }

  Future<void> _loadEntitlements() async {
    final result = await sl<GetVehicles>()(const NoParams());
    if (!mounted) return;
    result.fold((_) {}, (vehicles) {
      final showFriends = vehicles.any(
        (vehicle) =>
            vehicle.plan == VehiclePlan.protect ||
            vehicle.plan == VehiclePlan.total,
      );
      if (!showFriends &&
          GoRouterState.of(context).uri.path.startsWith('/home/friends')) {
        context.go('/home/vehicles');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
      ),
    );
  }

  /// Calculate the current index based on the current location
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/home/dashboard')) {
      return 0;
    }
    if (location.startsWith('/home/map')) {
      return 1;
    }
    if (location.startsWith('/home/vehicles')) {
      return 2;
    }
    if (location.startsWith('/home/settings')) {
      return 3;
    }
    // Default to vehicles
    return 0;
  }

  /// Handle destination selection
  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteConstants.homeDashboard);
        break;
      case 1:
        context.go('/home/map');
        break;
      case 2:
        context.go('/home/vehicles');
        break;
      case 3:
        context.go('/home/settings');
        break;
    }
  }
}
