import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';

/// Setup page to ensure required permissions (location + notifications)
class SetupPermissionsPage extends StatefulWidget {
  const SetupPermissionsPage({super.key});

  @override
  State<SetupPermissionsPage> createState() => _SetupPermissionsPageState();
}

class _SetupPermissionsPageState extends State<SetupPermissionsPage>
    with WidgetsBindingObserver {
  final _handler = sl<AppPermissionHandler>();

  AppPermissionStatus _location = AppPermissionStatus.unknown;
  AppPermissionStatus _notification = AppPermissionStatus.unknown;
  bool _locationServicesEnabled = true;

  bool get _allGranted => _location.isGranted && _notification.isGranted;

  bool get _readyToContinue => _allGranted && _locationServicesEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    final loc = await _handler.checkPermission(AppPermission.location);
    final noti = await _handler.checkPermission(AppPermission.notification);
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    setState(() {
      _location = loc;
      _notification = noti;
      _locationServicesEnabled = servicesEnabled;
    });
  }

  Future<void> _request(AppPermission permission) async {
    await _handler.ensurePermission(permission);
    await _refreshStatuses();
  }

  Future<void> _openSettings(AppPermission permission) async {
    await _handler.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.setupPermissions),
        actions: [
          IconButton(
            tooltip: context.l10n.whyWeAsk,
            icon: const Icon(Icons.info_outline),
            onPressed: _showExplainer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.l10n.permissionsIntro,
              style: textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          // Location services status
          _ServicesTile(
            enabled: _locationServicesEnabled,
            onOpenSettings: () async {
              await Geolocator.openLocationSettings();
            },
          ),
          const SizedBox(height: 8),
          _PermissionTile(
            icon: Icons.location_on,
            title: context.l10n.locationWhileUsingApp,
            subtitle: context.l10n.locationTrackingRequired,
            status: _location,
            onRequest: () => _request(AppPermission.location),
            onOpenSettings: () => _openSettings(AppPermission.location),
          ),
          const SizedBox(height: 8),
          _PermissionTile(
            icon: Icons.notifications_active,
            title: context.l10n.notifications,
            subtitle: context.l10n.notificationsRequired,
            status: _notification,
            onRequest: () => _request(AppPermission.notification),
            onOpenSettings: () => _openSettings(AppPermission.notification),
          ),
          const SizedBox(height: 24),
          // Request all
          OutlinedButton.icon(
            onPressed: () async {
              await _handler.requestPermissions([
                AppPermission.location,
                AppPermission.notification,
              ]);
              await _refreshStatuses();
            },
            icon: const Icon(Icons.fact_check),
            label: Text(context.l10n.requestAll),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _readyToContinue
                ? () => context.go(RouteConstants.home)
                : null,
            child: Text(context.l10n.continueLabel),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _refreshStatuses,
            child: Text(context.l10n.refresh),
          ),
        ],
      ),
    );
  }

  void _showExplainer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.whyWeNeedThese),
        content: Text(context.l10n.permissionsExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppPermissionStatus status;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final granted = status.isGranted;
    final needsSettings = status.requiresSettings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: granted ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: granted
                            ? colorScheme.primary
                            : colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        granted
                            ? context.l10n.granted
                            : (needsSettings
                                  ? context.l10n.requiresSettings
                                  : context.l10n.denied),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!granted && !needsSettings)
                      OutlinedButton(
                        onPressed: onRequest,
                        child: Text(context.l10n.allow),
                      ),
                    if (needsSettings)
                      OutlinedButton(
                        onPressed: onOpenSettings,
                        child: Text(context.l10n.openSettings),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesTile extends StatelessWidget {
  final bool enabled;
  final VoidCallback onOpenSettings;

  const _ServicesTile({required this.enabled, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            enabled ? Icons.gps_fixed : Icons.gps_off,
            color: enabled ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.locationServices,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.locationServicesRequired,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: enabled
                            ? colorScheme.primary
                            : colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        enabled ? context.l10n.on : context.l10n.off,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!enabled)
                      OutlinedButton(
                        onPressed: onOpenSettings,
                        child: Text(context.l10n.openSettings),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
