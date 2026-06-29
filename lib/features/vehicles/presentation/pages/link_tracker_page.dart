import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../bloc/tracker_link_bloc.dart';

/// Page for linking a GPS tracker to a vehicle
class LinkTrackerPage extends StatefulWidget {
  final String vehicleId;

  const LinkTrackerPage({
    super.key,
    required this.vehicleId,
  });

  @override
  State<LinkTrackerPage> createState() => _LinkTrackerPageState();
}

class _LinkTrackerPageState extends State<LinkTrackerPage> {
  final _formKey = GlobalKey<FormState>();
  final _imeiController = TextEditingController();
  final _imeiFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Reset state when page opens
    context.read<TrackerLinkBloc>().add(const ResetTrackerLink());
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _imeiFocusNode.dispose();
    super.dispose();
  }

  void _validateImei() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<TrackerLinkBloc>().add(
            ValidateImei(imei: _imeiController.text.trim()),
          );
    }
  }

  void _linkTracker() {
    context.read<TrackerLinkBloc>().add(
          LinkTrackerToVehicle(
            vehicleId: widget.vehicleId,
            imei: _imeiController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link GPS Tracker'),
      ),
      body: BlocConsumer<TrackerLinkBloc, TrackerLinkState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
            context.read<TrackerLinkBloc>().add(const ClearTrackerError());
          }

          if (state.isLinked) {
            context.showSuccessSnackBar('Tracker linked successfully');
            context.pop();
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How to link a tracker',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Find the IMEI number on your GPS tracker device\n'
                      '2. Enter the 15-digit IMEI number below\n'
                      '3. Verify the tracker information\n'
                      '4. Confirm to link the tracker',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // IMEI Input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _imeiController,
                  focusNode: _imeiFocusNode,
                  decoration: InputDecoration(
                    labelText: 'IMEI Number',
                    hintText: 'Enter 15-digit IMEI',
                    prefixIcon: const Icon(Icons.qr_code),
                    suffixIcon: state.isValid
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
                        : state.isInvalid
                            ? Icon(Icons.error, color: colorScheme.error)
                            : null,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  enabled: !state.isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the IMEI number';
                    }
                    if (value.length != 15) {
                      return 'IMEI must be 15 digits';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _validateImei(),
                ),
              ),

              const SizedBox(height: 16),

              // Validate button (only if not yet validated)
              if (!state.isValid)
                FilledButton(
                  onPressed: state.isValidating ? null : _validateImei,
                  child: state.isValidating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify Tracker'),
                ),

              // Invalid tracker message
              if (state.isInvalid) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage ?? 'Tracker not found or already in use',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tracker info (when valid)
              if (state.isValid && state.trackerInfo != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tracker Found',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        'IMEI',
                        state.trackerInfo!.imei,
                      ),
                      if (state.trackerInfo!.model != null)
                        _buildInfoRow(
                          context,
                          'Model',
                          state.trackerInfo!.model!,
                        ),
                      if (state.trackerInfo!.provider != null)
                        _buildInfoRow(
                          context,
                          'Provider',
                          state.trackerInfo!.provider!,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Link button
                FilledButton.icon(
                  onPressed: state.isLinking ? null : _linkTracker,
                  icon: state.isLinking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: const Text('Link Tracker to Vehicle'),
                ),
              ],

              const SizedBox(height: 32),

              // Help text
              Text(
                'The IMEI number can usually be found on a sticker on the device '
                'or in the device documentation. QR code scanning will be available soon.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: label == 'IMEI' ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
