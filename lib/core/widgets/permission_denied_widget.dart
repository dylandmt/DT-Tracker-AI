import 'package:flutter/material.dart';

import '../permissions/permission_status.dart';

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

  String get _defaultTitle {
    switch (permission) {
      case AppPermission.camera:
        return 'Camera Access Required';
      case AppPermission.photos:
        return 'Photo Library Access Required';
      case AppPermission.location:
        return 'Location Access Required';
      case AppPermission.locationAlways:
        return 'Background Location Required';
      case AppPermission.notification:
        return 'Notifications Disabled';
      case AppPermission.storage:
        return 'Storage Access Required';
    }
  }

  String get _defaultDescription {
    switch (permission) {
      case AppPermission.camera:
        return 'Please allow camera access to take photos of your vehicle.';
      case AppPermission.photos:
        return 'Please allow photo library access to select images for your vehicle.';
      case AppPermission.location:
        return 'Please allow location access to track your vehicle.';
      case AppPermission.locationAlways:
        return 'Please allow background location access for continuous tracking.';
      case AppPermission.notification:
        return 'Please enable notifications to receive alerts about your vehicles.';
      case AppPermission.storage:
        return 'Please allow storage access to save vehicle images.';
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
            title ?? _defaultTitle,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description ?? _defaultDescription,
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
              label: const Text('Open Settings'),
            )
          else if (onRetry != null)
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Grant Permission'),
            ),
          if (isPermanentlyDenied && showSettingsButton && onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
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
  final String actionText;

  const PermissionDeniedBanner({
    super.key,
    required this.permission,
    this.message,
    this.onAction,
    this.actionText = 'Grant',
  });

  String get _defaultMessage {
    switch (permission) {
      case AppPermission.camera:
        return 'Camera access is required';
      case AppPermission.photos:
        return 'Photo library access is required';
      case AppPermission.location:
      case AppPermission.locationAlways:
        return 'Location access is required';
      case AppPermission.notification:
        return 'Notifications are disabled';
      case AppPermission.storage:
        return 'Storage access is required';
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
              message ?? _defaultMessage,
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
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }
}
