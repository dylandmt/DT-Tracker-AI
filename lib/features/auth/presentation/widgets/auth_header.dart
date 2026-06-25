import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Header widget for auth pages with logo and title
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Logo/Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.location_on,
            size: 48,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        // App name
        Text(
          AppConstants.appName,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        // Page title
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}
