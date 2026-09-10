import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../injection_container.dart';
import '../utils/extensions.dart';
import 'tracker_security_service.dart';

Future<bool> authorizeTrackerUnlink(BuildContext context) async {
  final security = sl<TrackerSecurityService>();
  if (!await security.hasPin()) return true;

  if (!context.mounted) return false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TrackerPinAuthorizationDialog(
          instructions: context.l10n.enterSecurityPinToUnlink,
          useBiometrics: true,
        ),
      ) ??
      false;
}

Future<bool> authorizeSecurityPinSettings(BuildContext context) async {
  final security = sl<TrackerSecurityService>();
  if (!await security.hasPin()) return true;

  if (!context.mounted) return false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TrackerPinAuthorizationDialog(
          instructions: context.l10n.enterCurrentSecurityPin,
          useBiometrics: false,
        ),
      ) ??
      false;
}

class _TrackerPinAuthorizationDialog extends StatefulWidget {
  const _TrackerPinAuthorizationDialog({
    required this.instructions,
    required this.useBiometrics,
  });

  final String instructions;
  final bool useBiometrics;

  @override
  State<_TrackerPinAuthorizationDialog> createState() =>
      _TrackerPinAuthorizationDialogState();
}

class _TrackerPinAuthorizationDialogState
    extends State<_TrackerPinAuthorizationDialog> {
  final _pinController = TextEditingController();
  bool _authenticatingBiometrics = false;
  bool _verifyingPin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.useBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _authenticateBiometrics(),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _authenticateBiometrics() async {
    final biometricsEnabled = await sl<TrackerSecurityService>()
        .isBiometricsEnabled();
    if (!mounted || !biometricsEnabled) return;
    setState(() {
      _authenticatingBiometrics = true;
      _error = null;
    });
    final authenticated = await sl<TrackerSecurityService>()
        .authenticateWithBiometrics(
          localizedReason: context.l10n.biometricsAuthenticationReason,
        );
    if (!mounted) return;
    if (authenticated) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _authenticatingBiometrics = false;
      _error = context.l10n.biometricsFailedUsePin;
    });
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
      Navigator.pop(context, true);
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
          if (_authenticatingBiometrics)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
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
