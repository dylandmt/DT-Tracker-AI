import 'package:flutter/material.dart';

/// Header widget for auth pages with logo and title
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Logo (theme-aware): light logo on dark theme, dark logo on light theme
        Image.asset(
          isDark
              ? 'assets/images/dt_tracker_logo_dark.png'
              : 'assets/images/dt_tracker_logo_light.png',
          width: 96,
          height: 96,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        // App name
        Text(
          'Tracker',
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
