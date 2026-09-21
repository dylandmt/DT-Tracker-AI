import 'package:flutter/material.dart';

import '../../domain/entities/vehicle.dart';
import '../../../../core/utils/extensions.dart';

/// Dialog for confirming vehicle deletion
class DeleteVehicleDialog extends StatelessWidget {
  final VehicleEntity vehicle;

  const DeleteVehicleDialog({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Text(context.l10n.deleteVehicle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle.hasTracker
                ? context.l10n.unlinkTrackerBeforeDelete
                : context.l10n.deleteVehicleConfirmation(vehicle.name),
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (vehicle.hasTracker) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.unlinkTrackerOnDelete(vehicle.trackerId!),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              context.l10n.cannotUndo,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            vehicle.hasTracker ? context.l10n.ok : context.l10n.cancel,
          ),
        ),
        if (!vehicle.hasTracker)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(context.l10n.delete),
          ),
      ],
    );
  }
}

/// Show delete vehicle confirmation dialog
Future<bool?> showDeleteVehicleDialog(
  BuildContext context,
  VehicleEntity vehicle,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteVehicleDialog(vehicle: vehicle),
  );
}
