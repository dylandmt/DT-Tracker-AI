import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as 'MMM dd, yyyy'
  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format as 'HH:mm'
  String get formattedTime {
    return DateFormat('HH:mm').format(this);
  }

  /// Format as 'MMM dd, yyyy HH:mm'
  String get formattedDateTime {
    return DateFormat('MMM dd, yyyy HH:mm').format(this);
  }

  /// Format as relative time (e.g., '5 minutes ago')
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

/// BuildContext extensions
extension ContextExtensions on BuildContext {
  /// Get the theme
  ThemeData get theme => Theme.of(this);

  /// Get the color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get the text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Show a snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  /// Show a success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show an error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, isError: true);
  }
}

/// Double extensions for formatting
extension DoubleExtensions on double {
  /// Format as speed (km/h)
  String get formatSpeed {
    return '${toStringAsFixed(1)} km/h';
  }

  /// Format as distance (km or m)
  String get formatDistance {
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(2)} km';
    }
    return '${toStringAsFixed(0)} m';
  }

  /// Format as coordinates
  String get formatCoordinate {
    return toStringAsFixed(6);
  }
}

/// Duration extensions
extension DurationExtensions on Duration {
  /// Format as 'HH:mm:ss'
  String get formatted {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format as human readable string
  String get humanReadable {
    if (inDays > 0) {
      return '${inDays}d ${inHours % 24}h';
    } else if (inHours > 0) {
      return '${inHours}h ${inMinutes % 60}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds % 60}s';
    } else {
      return '${inSeconds}s';
    }
  }
}
