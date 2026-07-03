import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../bloc/vehicle_form_bloc.dart';
import '../widgets/vehicle_form_fields.dart';
import '../widgets/vehicle_image_picker.dart';

/// Page for creating or editing a vehicle
class VehicleFormPage extends StatefulWidget {
  final String? vehicleId;

  const VehicleFormPage({
    super.key,
    this.vehicleId,
  });

  bool get isEditing => vehicleId != null;

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _plateNumberController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _plateNumberController = TextEditingController();
    _brandController = TextEditingController();
    _modelController = TextEditingController();
    _yearController = TextEditingController();

    // Load vehicle if editing
    if (widget.isEditing) {
      context.read<VehicleFormBloc>().add(
            LoadVehicleForEdit(vehicleId: widget.vehicleId!),
          );
    } else {
      // Default color is White
      _selectedColor = 'White';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _populateFields(VehicleFormState state) {
    final vehicle = state.vehicle;
    if (vehicle != null && _nameController.text.isEmpty) {
      _nameController.text = vehicle.name;
      _plateNumberController.text = vehicle.plateNumber;
      _brandController.text = vehicle.brand ?? '';
      _modelController.text = vehicle.model ?? '';
      _yearController.text = vehicle.year?.toString() ?? '';
      _selectedColor = vehicle.color ?? 'White';
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<VehicleFormBloc>().add(
            SubmitVehicleForm(
              name: _nameController.text.trim(),
              plateNumber: _plateNumberController.text.trim(),
              brand: _brandController.text.trim().isNotEmpty
                  ? _brandController.text.trim()
                  : null,
              model: _modelController.text.trim().isNotEmpty
                  ? _modelController.text.trim()
                  : null,
              year: _yearController.text.isNotEmpty
                  ? int.tryParse(_yearController.text)
                  : null,
              color: _selectedColor,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
      ),
      body: BlocConsumer<VehicleFormBloc, VehicleFormState>(
        listener: (context, state) {
          // Populate fields when vehicle is loaded
          if (state.isLoaded || state.isEditing) {
            _populateFields(state);
          }

          // Handle errors
          if (state.hasError && state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
            context.read<VehicleFormBloc>().add(const ClearFormError());
          }

          // Handle success
          if (state.isSuccess) {
            context.showSuccessSnackBar(
              widget.isEditing
                  ? 'Vehicle updated successfully'
                  : 'Vehicle created successfully',
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state.isLoading && widget.isEditing) {
            return const Center(child: CircularProgressIndicator());
          }

          final isProcessing = state.isSubmitting ||
              state.isUploadingImage ||
              state.isDeletingImage;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Form fields
                VehicleFormFields(
                  nameController: _nameController,
                  plateNumberController: _plateNumberController,
                  brandController: _brandController,
                  modelController: _modelController,
                  yearController: _yearController,
                  selectedColor: _selectedColor,
                  onColorChanged: (color) {
                    setState(() => _selectedColor = color);
                  },
                  enabled: !isProcessing,
                ),

                const SizedBox(height: 32),

                // Image picker (only for editing)
                if (widget.isEditing && state.vehicle != null) ...[
                  VehicleImagePicker(
                    vehicle: state.vehicle,
                    imageUrls: state.vehicle!.imageUrls,
                    isUploading: state.isUploadingImage,
                    uploadingIndex: state.uploadingImageIndex,
                    enabled: !isProcessing,
                    onImageAdded: (path) {
                      context.read<VehicleFormBloc>().add(
                            AddVehicleImage(filePath: path),
                          );
                    },
                    onImageRemoved: (url) {
                      context.read<VehicleFormBloc>().add(
                            RemoveVehicleImage(imageUrl: url),
                          );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You can add images after creating the vehicle.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ] else if (!widget.isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can add photos after creating the vehicle.',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Submit button
                FilledButton(
                  onPressed: isProcessing ? null : _submitForm,
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.isEditing ? 'Save Changes' : 'Create Vehicle'),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
