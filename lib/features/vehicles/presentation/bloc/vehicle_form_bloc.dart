import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/create_vehicle.dart';
import '../../domain/usecases/delete_vehicle_image.dart';
import '../../domain/usecases/get_vehicle_by_id.dart';
import '../../domain/usecases/update_vehicle.dart';
import '../../domain/usecases/upload_vehicle_image.dart';

part 'vehicle_form_event.dart';
part 'vehicle_form_state.dart';

/// BLoC for managing vehicle creation and editing
class VehicleFormBloc extends Bloc<VehicleFormEvent, VehicleFormState> {
  final CreateVehicle createVehicle;
  final UpdateVehicle updateVehicle;
  final GetVehicleById getVehicleById;
  final UploadVehicleImage uploadVehicleImage;
  final DeleteVehicleImage deleteVehicleImage;

  VehicleFormBloc({
    required this.createVehicle,
    required this.updateVehicle,
    required this.getVehicleById,
    required this.uploadVehicleImage,
    required this.deleteVehicleImage,
  }) : super(VehicleFormState.initial()) {
    on<LoadVehicleForEdit>(_onLoadVehicleForEdit);
    on<SubmitVehicleForm>(_onSubmitVehicleForm);
    on<AddVehicleImage>(_onAddVehicleImage);
    on<RemoveVehicleImage>(_onRemoveVehicleImage);
    on<ResetVehicleForm>(_onResetVehicleForm);
    on<ClearFormError>(_onClearFormError);
  }

  Future<void> _onLoadVehicleForEdit(
    LoadVehicleForEdit event,
    Emitter<VehicleFormState> emit,
  ) async {
    emit(state.copyWith(status: VehicleFormStatus.loading));

    final result = await getVehicleById(IdParams(id: event.vehicleId));

    result.fold(
      (failure) => emit(state.copyWith(
        status: VehicleFormStatus.error,
        errorMessage: failure.message,
      )),
      (vehicle) => emit(state.copyWith(
        status: VehicleFormStatus.loaded,
        vehicle: vehicle,
        isEditing: true,
      )),
    );
  }

  Future<void> _onSubmitVehicleForm(
    SubmitVehicleForm event,
    Emitter<VehicleFormState> emit,
  ) async {
    emit(state.copyWith(status: VehicleFormStatus.submitting));

    if (state.isEditing && state.vehicle != null) {
      // Update existing vehicle
      final result = await updateVehicle(UpdateVehicleParams(
        id: state.vehicle!.id,
        name: event.name,
        plateNumber: event.plateNumber,
        brand: event.brand,
        model: event.model,
        year: event.year,
        color: event.color,
      ));

      result.fold(
        (failure) => emit(state.copyWith(
          status: VehicleFormStatus.error,
          errorMessage: failure.message,
        )),
        (vehicle) => emit(state.copyWith(
          status: VehicleFormStatus.success,
          vehicle: vehicle,
        )),
      );
    } else {
      // Create new vehicle
      final result = await createVehicle(CreateVehicleParams(
        name: event.name,
        plateNumber: event.plateNumber,
        brand: event.brand,
        model: event.model,
        year: event.year,
        color: event.color,
      ));

      result.fold(
        (failure) => emit(state.copyWith(
          status: VehicleFormStatus.error,
          errorMessage: failure.message,
        )),
        (vehicle) => emit(state.copyWith(
          status: VehicleFormStatus.success,
          vehicle: vehicle,
        )),
      );
    }
  }

  Future<void> _onAddVehicleImage(
    AddVehicleImage event,
    Emitter<VehicleFormState> emit,
  ) async {
    if (state.vehicle == null) {
      emit(state.copyWith(
        status: VehicleFormStatus.error,
        errorMessage: 'Please save the vehicle first before adding images',
      ));
      return;
    }

    emit(state.copyWith(
      status: VehicleFormStatus.uploadingImage,
      uploadingImageIndex: state.vehicle!.imageUrls.length,
    ));

    final result = await uploadVehicleImage(UploadImageParams(
      vehicleId: state.vehicle!.id,
      filePath: event.filePath,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: VehicleFormStatus.error,
        errorMessage: failure.message,
        uploadingImageIndex: null,
      )),
      (imageUrl) {
        // Update local vehicle state with new image
        final updatedImageUrls = [...state.vehicle!.imageUrls, imageUrl];
        final updatedVehicle = state.vehicle!.copyWith(
          imageUrls: updatedImageUrls,
        );
        emit(state.copyWith(
          status: VehicleFormStatus.loaded,
          vehicle: updatedVehicle,
          uploadingImageIndex: null,
        ));
      },
    );
  }

  Future<void> _onRemoveVehicleImage(
    RemoveVehicleImage event,
    Emitter<VehicleFormState> emit,
  ) async {
    if (state.vehicle == null) return;

    emit(state.copyWith(status: VehicleFormStatus.deletingImage));

    final result = await deleteVehicleImage(DeleteImageParams(
      vehicleId: state.vehicle!.id,
      imageUrl: event.imageUrl,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: VehicleFormStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        // Update local vehicle state
        final updatedImageUrls = state.vehicle!.imageUrls
            .where((url) => url != event.imageUrl)
            .toList();
        final updatedVehicle = state.vehicle!.copyWith(
          imageUrls: updatedImageUrls,
        );
        emit(state.copyWith(
          status: VehicleFormStatus.loaded,
          vehicle: updatedVehicle,
        ));
      },
    );
  }

  void _onResetVehicleForm(
    ResetVehicleForm event,
    Emitter<VehicleFormState> emit,
  ) {
    emit(VehicleFormState.initial());
  }

  void _onClearFormError(
    ClearFormError event,
    Emitter<VehicleFormState> emit,
  ) {
    emit(state.copyWith(
      status: state.vehicle != null
          ? VehicleFormStatus.loaded
          : VehicleFormStatus.initial,
      errorMessage: null,
    ));
  }
}
