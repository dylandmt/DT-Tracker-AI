import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/social_backend_datasource.dart';

class ShareLocationPage extends StatefulWidget {
  const ShareLocationPage({super.key});

  @override
  State<ShareLocationPage> createState() => _ShareLocationPageState();
}

class _ShareLocationPageState extends State<ShareLocationPage> {
  final _social = sl<SocialBackendDataSource>();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _vehicles = [];
  final _vehicleIds = <String>{};
  Map<String, dynamic>? _friend;
  String _duration = '15m';
  int _step = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final values = await Future.wait([_social.friends(), _social.vehicles()]);
      if (!mounted) return;
      setState(() {
        _friends = values[0];
        _vehicles = values[1].where((vehicle) {
          final trackerId = vehicle['trackerId'];
          return trackerId is String && trackerId.isNotEmpty;
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(context.l10n.socialAuthenticationRequired);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continue() async {
    if (_step == 0 && _friend == null) {
      context.showErrorSnackBar(context.l10n.shareNoFriends);
      return;
    }
    if (_step == 1 && _vehicleIds.isEmpty) {
      context.showErrorSnackBar(context.l10n.shareNoLinkedVehicles);
      return;
    }
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }

    setState(() => _saving = true);
    try {
      final recipient = _friend?['user'] is Map
          ? Map<String, dynamic>.from(_friend!['user'] as Map)
          : _friend!;
      await _social.upsertLocationShare(
        friendUid: recipient['uid'].toString(),
        vehicleIds: _vehicleIds.toList(),
        duration: _duration,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) context.showErrorSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareLocation)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _step,
              onStepContinue: _saving ? null : _continue,
              onStepCancel: _step == 0
                  ? () => Navigator.pop(context)
                  : () => setState(() => _step -= 1),
              controlsBuilder: (context, details) => Row(
                children: [
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(_step == 2 ? l10n.shareLocation : l10n.next),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
              steps: [
                Step(
                  title: Text(l10n.shareSelectFriendTitle),
                  isActive: _step >= 0,
                  content: _friends.isEmpty
                      ? Text(l10n.shareNoFriends)
                      : RadioGroup<Map<String, dynamic>>(
                          groupValue: _friend,
                          onChanged: (value) => setState(() => _friend = value),
                          child: Column(
                            children: _friends.map((friend) {
                              final user = friend['user'] is Map
                                  ? Map<String, dynamic>.from(
                                      friend['user'] as Map,
                                    )
                                  : friend;
                              final name =
                                  user['username']?.toString() ??
                                  user['uid'].toString();
                              return RadioListTile<Map<String, dynamic>>(
                                value: friend,
                                title: Text(name),
                              );
                            }).toList(),
                          ),
                        ),
                ),
                Step(
                  title: Text(l10n.shareSelectVehiclesTitle),
                  isActive: _step >= 1,
                  content: _vehicles.isEmpty
                      ? Text(l10n.shareNoLinkedVehicles)
                      : Column(
                          children: _vehicles.map((vehicle) {
                            final vehicleId = vehicle['id'].toString();
                            return CheckboxListTile(
                              value: _vehicleIds.contains(vehicleId),
                              title: Text(
                                vehicle['name']?.toString() ?? vehicleId,
                              ),
                              subtitle: Text(
                                vehicle['plateNumber']?.toString() ?? '',
                              ),
                              onChanged: (selected) => setState(() {
                                selected == true
                                    ? _vehicleIds.add(vehicleId)
                                    : _vehicleIds.remove(vehicleId);
                              }),
                            );
                          }).toList(),
                        ),
                ),
                Step(
                  title: Text(l10n.shareSelectDurationTitle),
                  isActive: _step >= 2,
                  content: DropdownButtonFormField<String>(
                    initialValue: _duration,
                    decoration: InputDecoration(labelText: l10n.duration),
                    items:
                        const ['15m', '30m', '1h', '4h', '8h', 'until_revoked']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_durationLabel(value)),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _duration = value!),
                  ),
                ),
              ],
            ),
    );
  }

  String _durationLabel(String duration) => switch (duration) {
    '15m' => context.l10n.shareDuration15Minutes,
    '30m' => context.l10n.shareDuration30Minutes,
    '1h' => context.l10n.shareDuration1Hour,
    '4h' => context.l10n.shareDuration4Hours,
    '8h' => context.l10n.shareDuration8Hours,
    _ => context.l10n.shareDurationUntilRevoked,
  };
}
