import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/security/tracker_security_service.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';

class SecurityPinPage extends StatefulWidget {
  const SecurityPinPage({required this.isSetup, super.key});

  final bool isSetup;

  @override
  State<SecurityPinPage> createState() => _SecurityPinPageState();
}

class _SecurityPinPageState extends State<SecurityPinPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _hasPin = false;
  bool _biometricsAvailable = false;
  bool _enableBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityState() async {
    final security = sl<TrackerSecurityService>();
    final hasPin = await security.hasPin();
    final biometricsAvailable = await security.canUseBiometrics();
    final biometricsEnabled = await security.isBiometricsEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricsAvailable = biometricsAvailable;
      _enableBiometrics = biometricsAvailable && biometricsEnabled;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await sl<TrackerSecurityService>().savePin(
      _pinController.text,
      biometricsEnabled: _enableBiometrics,
    );
    if (!mounted) return;
    _finish();
  }

  Future<void> _revoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.revokeSecurityPin),
        content: Text(context.l10n.revokeSecurityPinConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.revoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await sl<TrackerSecurityService>().revokePin();
    if (mounted) context.pop();
  }

  void _finish() {
    if (widget.isSetup) {
      context.go(RouteConstants.home);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.securityPin)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _hasPin
                          ? context.l10n.changeSecurityPin
                          : context.l10n.setupSecurityPin,
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.securityPinDescription,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _pinController,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: context.l10n.securityPin,
                      ),
                      validator: (value) => value?.length == 6
                          ? null
                          : context.l10n.securityPinLength,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: context.l10n.confirmSecurityPin,
                      ),
                      validator: (value) => value == _pinController.text
                          ? null
                          : context.l10n.securityPinDoesNotMatch,
                    ),
                    if (_biometricsAvailable) ...[
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _enableBiometrics,
                        onChanged: (value) =>
                            setState(() => _enableBiometrics = value ?? false),
                        title: Text(context.l10n.enableBiometrics),
                        subtitle: Text(
                          context.l10n.enableBiometricsDescription,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.saveChanges),
                    ),
                    if (widget.isSetup) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _saving ? null : _finish,
                        child: Text(context.l10n.skip),
                      ),
                    ],
                    if (_hasPin && !widget.isSetup) ...[
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _saving ? null : _revoke,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                        child: Text(context.l10n.revokeSecurityPin),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
