import 'package:flutter/material.dart';

import '../permissions/permission_status.dart';
import '../utils/extensions.dart';

/// A reusable widget to display when a permission is denied
///
/// Shows an icon, title, description, and appropriate action buttons
/// based on the permission status.
class PermissionDeniedWidget extends StatelessWidget {
  /// The permission that was denied
  final AppPermission permission;

  /// Custom title (defaults based on permission type)
  final String? title;

  /// Custom description (defaults based on permission type)
  final String? description;

  /// Callback when retry/request button is pressed
  final VoidCallback? onRetry;

  /// Callback when open settings button is pressed
  final VoidCallback? onOpenSettings;

  /// Whether to show the open settings button
  final bool showSettingsButton;

  /// Whether the permission is permanently denied
  final bool isPermanentlyDenied;

  /// Custom icon (defaults based on permission type)
  final IconData? icon;

  const PermissionDeniedWidget({
    super.key,
    required this.permission,
    this.title,
    this.description,
    this.onRetry,
    this.onOpenSettings,
    this.showSettingsButton = true,
    this.isPermanentlyDenied = false,
    this.icon,
  });

  String _defaultTitle(BuildContext context) {
    switch (permission) {
      case AppPermission.camera:
        return context.l10n.cameraAccessRequired;
      case AppPermission.photos:
        return context.l10n.photoLibraryAccessRequired;
      case AppPermission.location:
        return context.l10n.locationPermissionRequired;
      case AppPermission.locationAlways:
        return context.l10n.backgroundLocationRequired;
      case AppPermission.notification:
        return context.l10n.notificationsDisabled;
      case AppPermission.storage:
        return context.l10n.storageAccessRequired;
    }
  }

  String _defaultDescription(BuildContext context) {
    switch (permission) {
      case AppPermission.camera:
        return context.l10n.cameraAccessDescription;
      case AppPermission.photos:
        return context.l10n.photoLibraryAccessDescription;
      case AppPermission.location:
        return context.l10n.locationAccessDescription;
      case AppPermission.locationAlways:
        return context.l10n.backgroundLocationDescription;
      case AppPermission.notification:
        return context.l10n.notificationsDescription;
      case AppPermission.storage:
        return context.l10n.storageAccessDescription;
    }
  }

  IconData get _defaultIcon {
    switch (permission) {
      case AppPermission.camera:
        return Icons.camera_alt_outlined;
      case AppPermission.photos:
        return Icons.photo_library_outlined;
      case AppPermission.location:
      case AppPermission.locationAlways:
        return Icons.location_off_outlined;
      case AppPermission.notification:
        return Icons.notifications_off_outlined;
      case AppPermission.storage:
        return Icons.folder_off_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? _defaultIcon,
              size: 48,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title ?? _defaultTitle(context),
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description ?? _defaultDescription(context),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (isPermanentlyDenied && showSettingsButton)
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: Text(context.l10n.openSettings),
            )
          else if (onRetry != null)
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.grantPermission),
            ),
          if (isPermanentlyDenied && showSettingsButton && onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text(context.l10n.tryAgain)),
          ],
        ],
      ),
    );
  }
}

/// A compact version of the permission denied widget for inline use
class PermissionDeniedBanner extends StatelessWidget {
  /// The permission that was denied
  final AppPermission permission;

  /// Custom message (defaults based on permission type)
  final String? message;

  /// Callback when action button is pressed
  final VoidCallback? onAction;

  /// Action button text
  final String? actionText;

  const PermissionDeniedBanner({
    super.key,
    required this.permission,
    this.message,
    this.onAction,
    this.actionText,
  });

  String _defaultMessage(BuildContext context) {
    switch (permission) {
      case AppPermission.camera:
        return context.l10n.cameraAccessShort;
      case AppPermission.photos:
        return context.l10n.photoLibraryAccessShort;
      case AppPermission.location:
      case AppPermission.locationAlways:
        return context.l10n.locationAccessShort;
      case AppPermission.notification:
        return context.l10n.notificationsDisabledShort;
      case AppPermission.storage:
        return context.l10n.storageAccessShort;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? _defaultMessage(context),
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onErrorContainer,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(actionText ?? context.l10n.grantPermission),
            ),
          ],
        ],
      ),
    );
  }
}
