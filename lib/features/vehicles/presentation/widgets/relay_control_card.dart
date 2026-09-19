import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/tracker_backend_datasource.dart';

/// Physical relay control. Completion is shown only after device ACK updates
/// the backend projection, never merely after command creation.
class RelayControlCard extends StatefulWidget {
  const RelayControlCard({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<RelayControlCard> createState() => _RelayControlCardState();
}

class _RelayControlCardState extends State<RelayControlCard> {
  final TrackerBackendDataSource _dataSource = sl<TrackerBackendDataSource>();
  Timer? _refreshTimer;
  Map<String, dynamic>? _relay;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await _dataSource.getRelayState(widget.vehicleId);
      if (mounted) {
        setState(() {
          _relay = (response['relay'] as Map?)?.cast<String, dynamic>();
          _error = null;
          _loading = false;
        });
      }
    } on ServerException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _requestState(String desiredState) async {
    final pin = await _showConfirmation(desiredState);
    if (pin == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _dataSource.requestRelayCommand(
        vehicleId: widget.vehicleId,
        desiredState: desiredState,
        pin: pin,
      );
      await _load();
    } on ServerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<String?> _showConfirmation(String desiredState) async {
    final pinController = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm relay command'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Requested relay state: $desiredState.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Security PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, pinController.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    pinController.dispose();
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final relay = _relay;
    final desiredState = relay?['desiredState']?.toString() ?? 'OFF';
    final reportedState = relay?['reportedState']?.toString();
    final commandStatus = relay?['commandStatus']?.toString();
    final isPending = commandStatus == 'PENDING';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.power_settings_new),
                SizedBox(width: 8),
                Text(
                  'Remote relay',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text('Requested: $desiredState'),
              Text('Applied: ${reportedState ?? 'Not confirmed'}'),
              Text('Command: ${commandStatus ?? 'No command'}'),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _submitting || isPending || desiredState == 'ON'
                          ? null
                          : () => _requestState('ON'),
                      child: const Text('Energize'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _submitting || isPending || desiredState == 'OFF'
                          ? null
                          : () => _requestState('OFF'),
                      child: const Text('De-energize'),
                    ),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 8),
                const Text('Waiting for tracker confirmation...'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
