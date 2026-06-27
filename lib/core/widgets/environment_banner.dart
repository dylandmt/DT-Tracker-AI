import 'package:flutter/material.dart';
import '../../config/environment/environment.dart';

/// shows a "DEV" banner at the top-right corner when in development environment
class EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const EnvironmentBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only show banner in dev environment
    if (EnvironmentConfig.isProd) {
      return child;
    }

    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: Colors.orange,
      child: child,
    );
  }
}