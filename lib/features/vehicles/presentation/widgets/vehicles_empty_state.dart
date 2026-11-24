import 'package:flutter/material.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';

class VehiclesEmptyState extends StatelessWidget {
  const VehiclesEmptyState({super.key, this.onAddVehicle});

  final VoidCallback? onAddVehicle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DTSpacing.xxl),
      child: DTGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: DTSpacing.lg),
            Text(
              context.l10n.noVehiclesYet,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DTSpacing.xs),
            Text(
              context.l10n.addFirstVehicle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.dtColors.textSecondary,
              ),
            ),
            const SizedBox(height: DTSpacing.lg),
            FilledButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addVehicle),
            ),
          ],
        ),
      ),
    ),
  );
}
