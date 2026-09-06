import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/onboarding/onboarding_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/profile_photo_preview.dart';

/// Settings page with user info and sign out
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
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
                      child: user != null && user.photoUrl != null
                          ? GestureDetector(
                              onTap: () => showProfilePhotoPreview(
                                context,
                                imageProvider: CachedNetworkImageProvider(
                                  user.photoUrl!,
                                ),
                                heroTag: 'profile-photo-${user.id}',
                              ),
                              child: Hero(
                                tag: 'profile-photo-${user.id}',
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.photoUrl!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _buildAvatarText(
                                          user.displayName ?? user.email,
                                          colorScheme,
                                        ),
                                  ),
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
                            user?.displayName ?? l10n.user,
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
              _buildSectionHeader(context, l10n.account),
              _buildListTile(
                context,
                icon: Icons.person_outline,
                title: l10n.profile,
                subtitle: l10n.editProfileInformation,
                onTap: () {
                  context.push(RouteConstants.profile);
                },
              ),
              // _buildListTile(
              //   context,
              //   icon: Icons.notifications_outlined,
              //   title: l10n.trackerEvents,
              //   subtitle: l10n.viewTrackerActivity,
              //   onTap: () {
              //     context.push(RouteConstants.alerts);
              //   },
              // ),

              const SizedBox(height: 16),

              _buildSectionHeader(context, l10n.tracking),
              // _buildListTile(
              //   context,
              //   icon: Icons.speed_outlined,
              //   title: l10n.speedAlerts,
              //   subtitle: l10n.configureSpeedAlerts,
              //   onTap: () {
              //     // TODO: Navigate to speed alert settings
              //     context.showSnackBar(l10n.speedAlertsComingSoon);
              //   },
              // ),
              SwitchListTile(
                secondary: const Icon(Icons.fence_outlined),
                title: Text(l10n.geofenceAlerts),
                subtitle: Text(l10n.geofenceAlertsDescription),
                value: user?.settings.geofenceAlertEnabled ?? true,
                onChanged: state.isLoading || user == null
                    ? null
                    : (enabled) => context.read<AuthBloc>().add(
                        GeofenceAlertPreferenceChanged(enabled),
                      ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.email_outlined),
                title: Text(l10n.emailAlerts),
                subtitle: Text(l10n.emailAlertsDescription),
                value: user?.settings.emailNotificationsEnabled ?? false,
                onChanged: state.isLoading || user == null
                    ? null
                    : (enabled) => context.read<AuthBloc>().add(
                        EmailNotificationPreferenceChanged(enabled),
                      ),
              ),
              _buildListTile(
                context,
                icon: Icons.fence_outlined,
                title: l10n.geofences,
                subtitle: l10n.manageGeofenceZones,
                onTap: () {
                  context.push(RouteConstants.geofences);
                },
              ),

              const SizedBox(height: 16),

              _buildSectionHeader(context, l10n.app),
              _buildListTile(
                context,
                icon: Icons.language_outlined,
                title: l10n.language,
                subtitle: _languageName(context, sl<LocaleController>().locale),
                onTap: () => _showLanguagePicker(context),
              ),
              _buildListTile(
                context,
                icon: Icons.brightness_6_outlined,
                title: l10n.theme,
                subtitle: _themeName(context, sl<ThemeController>().themeMode),
                onTap: () => _showThemePicker(context),
              ),
              _buildListTile(
                context,
                icon: Icons.tips_and_updates_outlined,
                title: l10n.restartGuide,
                subtitle: l10n.restartGuideSubtitle,
                onTap: () async {
                  await sl<OnboardingController>().reset();
                  if (context.mounted) context.go(RouteConstants.onboarding);
                },
              ),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: l10n.about,
                subtitle: 'Version 1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),

              // _buildListTile(
              //   context,
              //   icon: Icons.help_outline,
              //   title: l10n.helpAndSupport,
              //   subtitle: l10n.getHelpWithApp,
              //   onTap: () {
              //     context.showSnackBar(l10n.helpComingSoon);
              //   },
              // ),
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
                  label: Text(l10n.signOut),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      children: [Text(l10n.aboutDescription)],
    );
  }

  String _languageName(BuildContext context, Locale? locale) {
    final l10n = AppLocalizations.of(context)!;
    return switch (locale?.languageCode) {
      'en' => l10n.english,
      'es' => l10n.spanish,
      _ => l10n.systemDefault,
    };
  }

  void _showLanguagePicker(BuildContext context) {
    final controller = sl<LocaleController>();
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.language),
        content: RadioGroup<Locale?>(
          groupValue: controller.locale,
          onChanged: (locale) async {
            await controller.setLocale(locale);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption(null, l10n.systemDefault),
              _languageOption(const Locale('en'), l10n.english),
              _languageOption(const Locale('es'), l10n.spanish),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageOption(Locale? locale, String label) =>
      RadioListTile<Locale?>(value: locale, title: Text(label));

  String _themeName(BuildContext context, ThemeMode themeMode) {
    final l10n = AppLocalizations.of(context)!;
    return themeMode == ThemeMode.dark ? l10n.darkTheme : l10n.lightTheme;
  }

  void _showThemePicker(BuildContext context) {
    final controller = sl<ThemeController>();
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.theme),
        content: RadioGroup<ThemeMode>(
          groupValue: controller.themeMode,
          onChanged: (themeMode) async {
            if (themeMode == null) return;
            await controller.setThemeMode(themeMode);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: Text(l10n.lightTheme),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text(l10n.darkTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
