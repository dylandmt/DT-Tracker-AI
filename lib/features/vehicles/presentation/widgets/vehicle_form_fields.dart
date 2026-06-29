import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/validators.dart';

/// Reusable form fields for vehicle creation/editing
class VehicleFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController plateNumberController;
  final TextEditingController? brandController;
  final TextEditingController? modelController;
  final TextEditingController? yearController;
  final String? selectedColor;
  final ValueChanged<String?>? onColorChanged;
  final bool enabled;

  const VehicleFormFields({
    super.key,
    required this.nameController,
    required this.plateNumberController,
    this.brandController,
    this.modelController,
    this.yearController,
    this.selectedColor,
    this.onColorChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Required fields section
        _buildSectionHeader(context, 'Required Information'),
        const SizedBox(height: 12),
        _buildNameField(context),
        const SizedBox(height: 16),
        _buildPlateNumberField(context),

        const SizedBox(height: 24),

        // Optional fields section
        _buildSectionHeader(context, 'Vehicle Details (Optional)'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildBrandField(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildModelField(context)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildYearField(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildColorDropdown(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    return TextFormField(
      controller: nameController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Vehicle Name *',
        hintText: 'e.g., My Car',
        prefixIcon: Icon(Icons.directions_car_outlined),
      ),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      validator: Validators.validateVehicleName,
    );
  }

  Widget _buildPlateNumberField(BuildContext context) {
    return TextFormField(
      controller: plateNumberController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Plate Number *',
        hintText: 'e.g., ABC-123',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      validator: Validators.validatePlateNumber,
    );
  }

  Widget _buildBrandField(BuildContext context) {
    return TextFormField(
      controller: brandController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Brand',
        hintText: 'e.g., Toyota',
      ),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildModelField(BuildContext context) {
    return TextFormField(
      controller: modelController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Model',
        hintText: 'e.g., Corolla',
      ),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildYearField(BuildContext context) {
    return TextFormField(
      controller: yearController,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Year',
        hintText: 'e.g., 2020',
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final year = int.tryParse(value);
        if (year == null) return 'Invalid year';
        if (year < 1900 || year > DateTime.now().year + 1) {
          return 'Invalid year';
        }
        return null;
      },
    );
  }

  Widget _buildColorDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: selectedColor,
      decoration: const InputDecoration(
        labelText: 'Color',
      ),
      items: _vehicleColors.map((color) {
        return DropdownMenuItem(
          value: color.name,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  border: color.color == Colors.white
                      ? Border.all(color: colorScheme.outline)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(color.name),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onColorChanged : null,
    );
  }
}

/// Vehicle color options
class VehicleColor {
  final String name;
  final Color color;

  const VehicleColor(this.name, this.color);
}

const _vehicleColors = [
  VehicleColor('White', Colors.white),
  VehicleColor('Black', Colors.black),
  VehicleColor('Silver', Color(0xFFC0C0C0)),
  VehicleColor('Gray', Colors.grey),
  VehicleColor('Red', Colors.red),
  VehicleColor('Blue', Colors.blue),
  VehicleColor('Green', Colors.green),
  VehicleColor('Yellow', Colors.yellow),
  VehicleColor('Orange', Colors.orange),
  VehicleColor('Brown', Colors.brown),
  VehicleColor('Beige', Color(0xFFF5F5DC)),
  VehicleColor('Gold', Color(0xFFFFD700)),
];
