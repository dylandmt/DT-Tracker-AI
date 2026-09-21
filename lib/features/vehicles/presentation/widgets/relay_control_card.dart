import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/extensions.dart';
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
  bool _loading = true;
  bool _submitting = false;
  String? _pendingDesiredState;

  @override
  void initState() {
    super.initState();
    _load(showError: true);
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showError = false}) async {
    try {
      final response = await _dataSource.getRelayState(widget.vehicleId);
      if (mounted) {
        setState(() {
          _relay = (response['relay'] as Map?)?.cast<String, dynamic>();
          _loading = false;
        });
      }
    } on ServerException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        if (showError) await _showErrorDialog(error.message);
      }
    }
  }

  Future<void> _requestState(String desiredState) async {
    final pin = await _showConfirmation(desiredState);
    if (pin == null || !mounted) return;
    if (pin.length != 6) {
      await _showErrorDialog(context.l10n.incorrectSecurityPin);
      return;
    }

    setState(() {
      _submitting = true;
      _pendingDesiredState = desiredState;
    });
    try {
      await _dataSource.requestRelayCommand(
        vehicleId: widget.vehicleId,
        desiredState: desiredState,
        pin: pin,
      );
      await _load(showError: true);
    } on ServerException catch (error) {
      if (mounted) {
        await _showErrorDialog(
          error.errorCode == 'security_pin_invalid'
              ? context.l10n.incorrectSecurityPin
              : error.message,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _pendingDesiredState = null;
        });
      }
    }
  }

  Future<String?> _showConfirmation(String desiredState) async {
    final pinController = TextEditingController();
    final isImmobilizing = desiredState == 'OFF';
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isImmobilizing
                    ? context.l10n.immobilizeVehicle
                    : context.l10n.activateVehicle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isImmobilizing
                    ? context.l10n.enterPinToImmobilizeVehicle
                    : context.l10n.enterPinToActivateVehicle,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => Navigator.pop(context, pinController.text),
                decoration: InputDecoration(
                  labelText: context.l10n.securityPin,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, pinController.text),
                child: Text(context.l10n.continueLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
    pinController.dispose();
    return pin;
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.unableToChangeVehicleState),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final relay = _relay;
    final desiredState = relay?['desiredState']?.toString() ?? 'OFF';
    final reportedState = relay?['reportedState']?.toString();
    final commandStatus = relay?['commandStatus']?.toString();
    final isPending = _submitting || commandStatus == 'PENDING';
    // While awaiting the tracker ACK, reflect the state requested by the user.
    final effectiveState = isPending
        ? _pendingDesiredState ?? desiredState
        : reportedState ?? desiredState;
    final isImmobilized = effectiveState == 'OFF';
    final stateColor = isImmobilized ? Colors.red : Colors.green;
    final actionLabel = isImmobilized
        ? context.l10n.activateVehicle
        : context.l10n.immobilizeVehicle;
    final requestedState = isImmobilized ? 'ON' : 'OFF';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.power_settings_new, color: stateColor),
                const SizedBox(width: 8),
                Text(
                  isImmobilized
                      ? context.l10n.vehicleImmobilized
                      : context.l10n.vehicleActive,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                isPending
                    ? context.l10n.confirmingVehicleState
                    : context.l10n.vehicleStateConfirmed,
              ),
              if (isPending) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: stateColor,
                    backgroundColor: stateColor.withValues(alpha: 0.2),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: stateColor),
                  onPressed: isPending
                      ? null
                      : () => _requestState(requestedState),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
