import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../core/utils/extensions.dart';
import '../bloc/vehicle_form_bloc.dart';
import '../widgets/vehicle_form_fields.dart';
import '../widgets/vehicle_image_picker.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key, this.vehicleId});

  final String? vehicleId;

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
    if (widget.isEditing) {
      context.read<VehicleFormBloc>().add(
        LoadVehicleForEdit(vehicleId: widget.vehicleId!),
      );
    } else {
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
    if (vehicle == null || _nameController.text.isNotEmpty) return;
    _nameController.text = vehicle.name;
    _plateNumberController.text = vehicle.plateNumber;
    _brandController.text = vehicle.brand ?? '';
    _modelController.text = vehicle.model ?? '';
    _yearController.text = vehicle.year?.toString() ?? '';
    _selectedColor = vehicle.color ?? 'White';
  }

  void _submitForm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<VehicleFormBloc>().add(
      SubmitVehicleForm(
        name: _nameController.text.trim(),
        plateNumber: _plateNumberController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        year: _yearController.text.isEmpty
            ? null
            : int.tryParse(_yearController.text),
        color: _selectedColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DTAppScaffold(
    useAmbientBackground: false,
    body: SafeArea(
      child: BlocConsumer<VehicleFormBloc, VehicleFormState>(
        listener: (context, state) {
          if (state.isLoaded || state.isEditing) _populateFields(state);
          if (state.hasError && state.errorMessage != null) {
            context.showErrorSnackBar(state.errorMessage!);
            context.read<VehicleFormBloc>().add(const ClearFormError());
          }
          if (state.isSuccess) {
            context.showSuccessSnackBar(
              widget.isEditing
                  ? context.l10n.vehicleUpdatedSuccessfully
                  : context.l10n.vehicleCreatedSuccessfully,
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state.isLoading && widget.isEditing) {
            return const Center(child: CircularProgressIndicator());
          }
          final isProcessing =
              state.isSubmitting ||
              state.isUploadingImage ||
              state.isDeletingImage;
          return Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                DTSpacing.md,
                DTSpacing.sm,
                DTSpacing.md,
                MediaQuery.viewInsetsOf(context).bottom + DTSpacing.xxl,
              ),
              children: [
                _header(context),
                const SizedBox(height: DTSpacing.lg),
                DTGlassCard(
                  child: VehicleFormFields(
                    nameController: _nameController,
                    plateNumberController: _plateNumberController,
                    brandController: _brandController,
                    modelController: _modelController,
                    yearController: _yearController,
                    selectedColor: _selectedColor,
                    onColorChanged: (color) =>
                        setState(() => _selectedColor = color),
                    enabled: !isProcessing,
                  ),
                ),
                const SizedBox(height: DTSpacing.lg),
                if (widget.isEditing && state.vehicle != null)
                  DTGlassCard(
                    child: VehicleImagePicker(
                      vehicle: state.vehicle,
                      imageUrls: state.vehicle!.imageUrls,
                      isUploading: state.isUploadingImage,
                      uploadingIndex: state.uploadingImageIndex,
                      enabled: !isProcessing,
                      onImageAdded: (path) => context
                          .read<VehicleFormBloc>()
                          .add(AddVehicleImage(filePath: path)),
                      onImageRemoved: (url) => context
                          .read<VehicleFormBloc>()
                          .add(RemoveVehicleImage(imageUrl: url)),
                    ),
                  )
                else
                  _addPhotoNotice(context),
                const SizedBox(height: DTSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isProcessing ? null : _submitForm,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isEditing
                                ? context.l10n.saveChanges
                                : context.l10n.createVehicle,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      const SizedBox(width: DTSpacing.xs),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing
                  ? context.l10n.editVehicle
                  : context.l10n.addVehicle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DTSpacing.xxs),
            Text(
              widget.isEditing
                  ? context.l10n.editVehicleSubtitle
                  : context.l10n.addVehicleSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.dtColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _addPhotoNotice(BuildContext context) => DTGlassCard(
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: DTSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.addPhotosAfterVehicle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
