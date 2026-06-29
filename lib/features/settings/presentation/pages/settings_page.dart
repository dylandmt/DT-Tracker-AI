import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Settings page with user info and sign out
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.isUnauthenticated) {
            context.go(RouteConstants.login);
          }
          if (state.hasError && state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
          }
        },
        builder: (context, state) {
          final user = state.user;

          return ListView(
            children: [
              // User info header
              Container(
                padding: const EdgeInsets.all(24),
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.primary,
                      child: user?.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarText(
                                  user.displayName ?? user.email,
                                  colorScheme,
                                ),
                              ),
                            )
                          : _buildAvatarText(
                              user?.displayName ?? user?.email ?? '?',
                              colorScheme,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Settings sections
              _buildSectionHeader(context, 'Account'),
              _buildListTile(
                context,
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Edit your profile information',
                onTap: () {
                  // TODO: Navigate to profile page
                  context.showSnackBar('Profile editing coming soon');
                },
              ),
              _buildListTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {
                  // TODO: Navigate to notification settings
                  context.showSnackBar('Notification settings coming soon');
                },
              ),

              const SizedBox(height: 16),

              _buildSectionHeader(context, 'Tracking'),
              _buildListTile(
                context,
                icon: Icons.speed_outlined,
                title: 'Speed Alerts',
                subtitle: 'Configure speed limit alerts',
                onTap: () {
                  // TODO: Navigate to speed alert settings
                  context.showSnackBar('Speed alerts coming soon');
                },
              ),
              _buildListTile(
                context,
                icon: Icons.fence_outlined,
                title: 'Geofences',
                subtitle: 'Manage geofence zones',
                onTap: () {
                  // TODO: Navigate to geofence management
                  context.showSnackBar('Geofences coming soon');
                },
              ),

              const SizedBox(height: 16),

              _buildSectionHeader(context, 'App'),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              _buildListTile(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with the app',
                onTap: () {
                  context.showSnackBar('Help & Support coming soon');
                },
              ),

              const SizedBox(height: 32),

              // Sign out button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => _showSignOutDialog(context),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarText(String text, ColorScheme colorScheme) {
    final initial = text.isNotEmpty ? text[0].toUpperCase() : '?';
    return Text(
      initial,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'DT Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.gps_fixed,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      children: [
        const Text(
          'Real-time GPS vehicle tracking app with geofencing and alerts.',
        ),
      ],
    );
  }
}
