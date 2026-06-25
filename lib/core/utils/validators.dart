/// Form validation utilities
class Validators {
  Validators._();

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (!value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Password must contain at least one letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  /// Validate vehicle plate number
  static String? validatePlateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Plate number is required';
    }

    if (value.trim().length < 2) {
      return 'Please enter a valid plate number';
    }

    return null;
  }

  /// Validate vehicle name
  static String? validateVehicleName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }

    return null;
  }

  /// Validate geofence name
  static String? validateGeofenceName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Geofence name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }

    return null;
  }

  /// Validate geofence radius
  static String? validateGeofenceRadius(String? value) {
    if (value == null || value.isEmpty) {
      return 'Radius is required';
    }

    final radius = double.tryParse(value);
    if (radius == null) {
      return 'Please enter a valid number';
    }

    if (radius < 100) {
      return 'Radius must be at least 100 meters';
    }

    if (radius > 10000) {
      return 'Radius must be less than 10,000 meters';
    }

    return null;
  }

  /// Validate speed limit
  static String? validateSpeedLimit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Speed limit is required';
    }

    final speed = double.tryParse(value);
    if (speed == null) {
      return 'Please enter a valid number';
    }

    if (speed < 1) {
      return 'Speed limit must be at least 1 km/h';
    }

    if (speed > 300) {
      return 'Speed limit must be less than 300 km/h';
    }

    return null;
  }
}
