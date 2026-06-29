part of 'vehicle_form_bloc.dart';

/// Events for the VehicleFormBloc
sealed class VehicleFormEvent extends Equatable {
  const VehicleFormEvent();

  @override
  List<Object?> get props => [];
}

/// Load a vehicle for editing
class LoadVehicleForEdit extends VehicleFormEvent {
  final String vehicleId;

  const LoadVehicleForEdit({required this.vehicleId});

  @override
  List<Object?> get props => [vehicleId];
}

/// Submit the vehicle form (create or update)
class SubmitVehicleForm extends VehicleFormEvent {
  final String name;
  final String plateNumber;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;

  const SubmitVehicleForm({
    required this.name,
    required this.plateNumber,
    this.brand,
    this.model,
    this.year,
    this.color,
  });

  @override
  List<Object?> get props => [name, plateNumber, brand, model, year, color];
}

/// Add an image to the vehicle
class AddVehicleImage extends VehicleFormEvent {
  final String filePath;

  const AddVehicleImage({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

/// Remove an image from the vehicle
class RemoveVehicleImage extends VehicleFormEvent {
  final String imageUrl;

  const RemoveVehicleImage({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

/// Reset the form to initial state
class ResetVehicleForm extends VehicleFormEvent {
  const ResetVehicleForm();
}

/// Clear form error
class ClearFormError extends VehicleFormEvent {
  const ClearFormError();
}
