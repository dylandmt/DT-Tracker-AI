import 'package:flutter/material.dart';

/// Application color constants using Material 3 design
class AppColors {
  AppColors._();

  // Seed color for Material 3 color scheme generation
  static const Color seedColor = Color(0xFF1688FF);

  // Primary colors
  static const Color primaryLight = Color(0xFF1688FF);
  static const Color primaryDark = Color(0xFF36A3FF);

  // Secondary colors
  static const Color secondaryLight = Color(0xFF20C5FF);
  static const Color secondaryDark = Color(0xFF20C5FF);

  // Error colors
  static const Color errorLight = Color(0xFFFF496C);
  static const Color errorDark = Color(0xFFFF496C);

  // Success colors
  static const Color successLight = Color(0xFF13D99A);
  static const Color successDark = Color(0xFF13D99A);

  // Warning colors
  static const Color warningLight = Color(0xFFFFAA35);
  static const Color warningDark = Color(0xFFFFAA35);

  // Background colors
  static const Color backgroundLight = Color(0xFFF7F9FD);
  static const Color backgroundDark = Color(0xFF050B16);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0B1629);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF101827);
  static const Color textPrimaryDark = Color(0xFFF5F8FF);
  static const Color textSecondaryLight = Color(0xFF58687F);
  static const Color textSecondaryDark = Color(0xFFA5B6D2);

  // Status colors for vehicles/tracking
  static const Color statusOnline = Color(0xFF13D99A);
  static const Color statusOffline = Color(0xFF6F85A5);
  static const Color statusMoving = Color(0xFF1688FF);
  static const Color statusIdle = Color(0xFFFFAA35);
  static const Color statusAlert = Color(0xFFFF496C);

  // Map colors
  static const Color geofenceStroke = Color(0xFF1688FF);
  static const Color geofenceFill = Color(0x331688FF);
  static const Color routeColor = Color(0xFF1688FF);
}
