import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AlertsSettingsPage extends StatelessWidget {
  const AlertsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.manageAlerts)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fence_outlined),
                title: Text(context.l10n.geofenceAlerts),
                subtitle: Text(context.l10n.geofenceAlertsDescription),
                value: user?.settings.geofenceAlertEnabled ?? true,
                onChanged: state.isLoading || user == null
                    ? null
                    : (enabled) => context.read<AuthBloc>().add(
                        GeofenceAlertPreferenceChanged(enabled),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
