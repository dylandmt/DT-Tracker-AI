import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../injection_container.dart';
import '../utils/extensions.dart';
import 'tracker_security_service.dart';

class TrackerUnlinkAuthorization {
  const TrackerUnlinkAuthorization({this.pin});

  final String? pin;
}

Future<TrackerUnlinkAuthorization?> authorizeTrackerUnlink(
  BuildContext context,
) async {
  final security = sl<TrackerSecurityService>();
  if (!await security.hasPin()) return const TrackerUnlinkAuthorization();

  if (!context.mounted) return null;
  final pin = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TrackerPinAuthorizationDialog(
      instructions: context.l10n.enterSecurityPinToUnlink,
    ),
  );
  return pin == null ? null : TrackerUnlinkAuthorization(pin: pin);
}

class _TrackerPinAuthorizationDialog extends StatefulWidget {
  const _TrackerPinAuthorizationDialog({required this.instructions});

  final String instructions;

  @override
  State<_TrackerPinAuthorizationDialog> createState() =>
      _TrackerPinAuthorizationDialogState();
}

class _TrackerPinAuthorizationDialogState
    extends State<_TrackerPinAuthorizationDialog> {
  final _pinController = TextEditingController();
  bool _verifyingPin = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    setState(() {
      _verifyingPin = true;
      _error = null;
    });
    final valid = await sl<TrackerSecurityService>().verifyPin(
      _pinController.text,
    );
    if (!mounted) return;
    if (valid) {
      Navigator.pop(context, _pinController.text);
      return;
    }
    setState(() {
      _verifyingPin = false;
      _error = context.l10n.incorrectSecurityPin;
      _pinController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.confirmSecurityPin),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.instructions),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _verifyingPin ? null : _verifyPin(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.securityPin,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _verifyingPin ? null : _verifyPin,
          child: _verifyingPin
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.continueLabel),
        ),
      ],
    );
  }
}
