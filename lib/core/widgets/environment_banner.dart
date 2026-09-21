import 'package:flutter/material.dart';
import '../../config/environment/environment.dart';

/// Shows the current non-production environment at the top-right corner.
class EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const EnvironmentBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Production does not display an environment banner.
    if (EnvironmentConfig.isProd) {
      return child;
    }

    final message = switch (EnvironmentConfig.current) {
      Environment.dev => 'DEV',
      Environment.staging => 'STAGING',
      Environment.prod => '',
    };

    return Banner(
      message: message,
      location: BannerLocation.topEnd,
      color: Colors.orange,
      child: child,
    );
  }
}
