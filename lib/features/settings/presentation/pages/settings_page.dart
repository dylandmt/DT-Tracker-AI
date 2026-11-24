import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/onboarding/onboarding_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/profile_photo_preview.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => DTAppScaffold(
    body: SafeArea(
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.isUnauthenticated) context.go(RouteConstants.login);
          if (state.hasError && state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
          }
        },
        builder: (context, state) {
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              DTSpacing.md,
              DTSpacing.sm,
              DTSpacing.md,
              DTSpacing.xxl,
            ),
            children: [
              _header(context),
              const SizedBox(height: DTSpacing.lg),
              _profileCard(context, user),
              const SizedBox(height: DTSpacing.xl),
              _SettingsSectionHeader(
                icon: Icons.person_outline,
                title: context.l10n.account,
                subtitle: context.l10n.accountSettingsSubtitle,
              ),
              const SizedBox(height: DTSpacing.xs),
              _SettingsGroupedCard(
                children: [
                  _SettingsOptionTile(
                    icon: Icons.person_outline,
                    iconColor: Theme.of(context).colorScheme.primary,
                    title: context.l10n.profile,
                    subtitle: context.l10n.editProfileInformation,
                    onTap: () => context.push(RouteConstants.profile),
                  ),
                  _SettingsOptionTile(
                    icon: Icons.delete_outline,
                    iconColor: context.dtColors.alert,
                    title: context.l10n.deleteAccount,
                    subtitle: context.l10n.deleteAccountDescription,
                    onTap: state.isLoading
                        ? null
                        : () => context.push(RouteConstants.deleteAccount),
                  ),
                ],
              ),
              const SizedBox(height: DTSpacing.lg),
              _SettingsSectionHeader(
                icon: Icons.group_outlined,
                title: context.l10n.social,
                subtitle: context.l10n.socialSettingsSubtitle,
              ),
              const SizedBox(height: DTSpacing.xs),
              _SettingsGroupedCard(
                children: [
                  _SettingsOptionTile(
                    icon: Icons.people_outline,
                    title: context.l10n.friends,
                    subtitle: context.l10n.manageFriends,
                    onTap: () => context.go(RouteConstants.homeFriends),
                  ),
                ],
              ),
              const SizedBox(height: DTSpacing.lg),
              _SettingsSectionHeader(
                icon: Icons.shield_outlined,
                title: context.l10n.security,
                subtitle: context.l10n.securitySettingsSubtitle,
              ),
              const SizedBox(height: DTSpacing.xs),
              _SettingsGroupedCard(
                children: [
                  _SettingsOptionTile(
                    icon: Icons.lock_outline,
                    title: context.l10n.securityPin,
                    subtitle: context.l10n.securityPinSettingsDescription,
                    onTap: () => context.push(RouteConstants.securityPin),
                  ),
                  _SettingsOptionTile(
                    icon: Icons.notifications_outlined,
                    title: context.l10n.manageAlerts,
                    subtitle: context.l10n.manageAlertsDescription,
                    onTap: () => context.push(RouteConstants.alertsSettings),
                  ),
                  _SettingsOptionTile(
                    icon: Icons.fence_outlined,
                    title: context.l10n.geofences,
                    subtitle: context.l10n.manageGeofenceZones,
                    onTap: () => context.push(RouteConstants.geofences),
                  ),
                ],
              ),
              const SizedBox(height: DTSpacing.lg),
              _SettingsSectionHeader(
                icon: Icons.tune_outlined,
                title: context.l10n.app,
                subtitle: context.l10n.appSettingsSubtitle,
              ),
              const SizedBox(height: DTSpacing.xs),
              _SettingsGroupedCard(
                children: [
                  _SettingsOptionTile(
                    icon: Icons.language_outlined,
                    title: context.l10n.language,
                    subtitle: _languageName(
                      context,
                      sl<LocaleController>().locale,
                    ),
                    onTap: () => _showLanguagePicker(context),
                  ),
                  _SettingsOptionTile(
                    icon: sl<ThemeController>().themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: context.l10n.theme,
                    subtitle: _themeName(
                      context,
                      sl<ThemeController>().themeMode,
                    ),
                    onTap: () => _showThemePicker(context),
                  ),
                  _SettingsOptionTile(
                    icon: Icons.tips_and_updates_outlined,
                    title: context.l10n.restartGuide,
                    subtitle: context.l10n.restartGuideSubtitle,
                    onTap: () => _restartGuide(context),
                  ),
                  _SettingsOptionTile(
                    icon: Icons.info_outline,
                    title: context.l10n.about,
                    subtitle:
                        '${context.l10n.versionLabel} ${AppConstants.appVersion}',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: DTSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => _showSignOutDialog(context),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: Text(context.l10n.signOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.dtColors.alert,
                    side: BorderSide(
                      color: context.dtColors.alert.withValues(alpha: .55),
                    ),
                    backgroundColor: context.dtColors.alert.withValues(
                      alpha: .08,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _header(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.settings,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: DTSpacing.xxs),
      Text(
        context.l10n.settingsSubtitle,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.dtColors.textSecondary),
      ),
    ],
  );

  Widget _profileCard(BuildContext context, UserEntity? user) => DTGlassCard(
    onTap: () => context.push(RouteConstants.profile),
    child: Row(
      children: [
        _profileAvatar(context, user),
        const SizedBox(width: DTSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (user?.fullName ?? '').isNotEmpty
                    ? user!.fullName
                    : user?.displayName ?? context.l10n.user,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DTSpacing.xxs),
              Text(
                user?.email ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: context.dtColors.muted),
      ],
    ),
  );

  Widget _avatarInitial(BuildContext context, String value) => Text(
    value.isEmpty ? '?' : value[0].toUpperCase(),
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Theme.of(context).colorScheme.onPrimary,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _profileAvatar(BuildContext context, UserEntity? user) {
    final photoUrl = user?.photoUrl;
    final currentUser = user;
    final avatar = CircleAvatar(
      radius: 30,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundImage: photoUrl == null
          ? null
          : CachedNetworkImageProvider(photoUrl),
      child: photoUrl == null
          ? _avatarInitial(context, user?.displayName ?? user?.email ?? '?')
          : null,
    );
    if (photoUrl == null || currentUser == null) return avatar;
    return GestureDetector(
      onTap: () => showProfilePhotoPreview(
        context,
        imageProvider: CachedNetworkImageProvider(photoUrl),
        heroTag: 'profile-photo-${currentUser.id}',
      ),
      child: Hero(tag: 'profile-photo-${currentUser.id}', child: avatar),
    );
  }

  void _restartGuide(BuildContext context) async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    await sl<OnboardingController>().reset(user.id);
    if (context.mounted) {
      context.go('${RouteConstants.onboarding}?userId=${user.id}');
    }
  }

  void _showSignOutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
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
      applicationName: l10n.appTitle,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Icon(
        Icons.gps_fixed,
        color: Theme.of(context).colorScheme.primary,
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

  String _themeName(BuildContext context, ThemeMode themeMode) =>
      themeMode == ThemeMode.dark
      ? context.l10n.darkTheme
      : context.l10n.lightTheme;

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

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: DTSpacing.xs),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DTSpacing.xxs),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class _SettingsGroupedCard extends StatelessWidget {
  const _SettingsGroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DTGlassCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var index = 0; index < children.length; index += 1) ...[
          children[index],
          if (index < children.length - 1)
            Divider(height: 1, color: context.dtColors.border),
        ],
      ],
    ),
  );
}

class _SettingsOptionTile extends StatelessWidget {
  const _SettingsOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        enabled: onTap != null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DTSpacing.sm,
          vertical: DTSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right, color: context.dtColors.muted),
        onTap: onTap,
      ),
    );
  }
}
