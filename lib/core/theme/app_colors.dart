import 'package:flutter/material.dart';

/// Application color constants using Material 3 design
class AppColors {
  AppColors._();

  // Seed color for Material 3 color scheme generation
  static const Color seedColor = Color(0xFF1976D2);

  // Primary colors
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF90CAF9);

  // Secondary colors
  static const Color secondaryLight = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF80CBC4);

  // Error colors
  static const Color errorLight = Color(0xFFD32F2F);
  static const Color errorDark = Color(0xFFEF5350);

  // Success colors
  static const Color successLight = Color(0xFF388E3C);
  static const Color successDark = Color(0xFF66BB6A);

  // Warning colors
  static const Color warningLight = Color(0xFFF57C00);
  static const Color warningDark = Color(0xFFFFB74D);

  // Background colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status colors for vehicles/tracking
  static const Color statusOnline = Color(0xFF4CAF50);
  static const Color statusOffline = Color(0xFF9E9E9E);
  static const Color statusMoving = Color(0xFF2196F3);
  static const Color statusIdle = Color(0xFFFF9800);
  static const Color statusAlert = Color(0xFFF44336);

  // Map colors
  static const Color geofenceStroke = Color(0xFF1976D2);
  static const Color geofenceFill = Color(0x331976D2);
  static const Color routeColor = Color(0xFF1976D2);
}
