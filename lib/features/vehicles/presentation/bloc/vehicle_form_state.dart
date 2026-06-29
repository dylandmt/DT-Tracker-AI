part of 'vehicle_form_bloc.dart';

/// Status enum for vehicle form state
enum VehicleFormStatus {
  initial,
  loading,
  loaded,
  submitting,
  success,
  error,
  uploadingImage,
  deletingImage,
}

/// State for the VehicleFormBloc
class VehicleFormState extends Equatable {
  final VehicleFormStatus status;
  final VehicleEntity? vehicle;
  final bool isEditing;
  final String? errorMessage;
  final int? uploadingImageIndex;

  const VehicleFormState({
    required this.status,
    this.vehicle,
    required this.isEditing,
    this.errorMessage,
    this.uploadingImageIndex,
  });

  /// Initial state (for creating new vehicle)
  factory VehicleFormState.initial() {
    return const VehicleFormState(
      status: VehicleFormStatus.initial,
      isEditing: false,
    );
  }

  /// State helpers
  bool get isLoading => status == VehicleFormStatus.loading;
  bool get isLoaded => status == VehicleFormStatus.loaded;
  bool get isSubmitting => status == VehicleFormStatus.submitting;
  bool get isSuccess => status == VehicleFormStatus.success;
  bool get hasError => status == VehicleFormStatus.error;
  bool get isUploadingImage => status == VehicleFormStatus.uploadingImage;
  bool get isDeletingImage => status == VehicleFormStatus.deletingImage;

  /// Image helpers
  bool get canAddMoreImages =>
      vehicle == null || vehicle!.imageUrls.length < VehicleEntity.maxImages;
  int get imageCount => vehicle?.imageUrls.length ?? 0;
  int get remainingImageSlots =>
      VehicleEntity.maxImages - (vehicle?.imageUrls.length ?? 0);

  /// Copy with modified fields
  VehicleFormState copyWith({
    VehicleFormStatus? status,
    VehicleEntity? vehicle,
    bool? isEditing,
    String? errorMessage,
    int? uploadingImageIndex,
  }) {
    return VehicleFormState(
      status: status ?? this.status,
      vehicle: vehicle ?? this.vehicle,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: errorMessage,
      uploadingImageIndex: uploadingImageIndex,
    );
  }

  @override
  List<Object?> get props => [
        status,
        vehicle,
        isEditing,
        errorMessage,
        uploadingImageIndex,
      ];
}
