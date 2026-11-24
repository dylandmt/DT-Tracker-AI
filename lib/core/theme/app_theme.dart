import 'package:flutter/material.dart';

import '../design/dt_design_tokens.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Material 3 themes aligned to the approved DT Tracker visual system.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final onSurface = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final colors = DTThemeColors(
      surfaceRaised: isDark ? const Color(0xFF101F36) : const Color(0xFFEEF3FA),
      surfaceOverlay: isDark
          ? const Color(0xFF14253D)
          : const Color(0xFFE7F0FD),
      border: isDark ? const Color(0xFF253D5D) : const Color(0xFFDCE5F1),
      textSecondary: isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
      muted: isDark ? const Color(0xFF6F85A5) : const Color(0xFF8190A6),
      primaryBright: const Color(0xFF36A3FF),
      primaryDeep: const Color(0xFF0752B8),
      primaryPale: const Color(0xFFD7E8FF),
      cyan: const Color(0xFF20C5FF),
      purple: const Color(0xFF9658FF),
      online: AppColors.statusOnline,
      offline: AppColors.statusOffline,
      moving: AppColors.statusMoving,
      idle: AppColors.statusIdle,
      alert: AppColors.statusAlert,
    );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.seedColor,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: AppColors.seedColor,
          onPrimary: Colors.white,
          secondary: colors.cyan,
          error: colors.alert,
          surface: surface,
          onSurface: onSurface,
          surfaceContainerHighest: colors.surfaceRaised,
          outlineVariant: colors.border,
        );
    final textTheme = _textTheme(onSurface, colors.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: [colors],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(DTRadius.lg),
          side: BorderSide(color: colors.border, width: .8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: DTSpacing.xl),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(DTRadius.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: DTSpacing.xl),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(DTRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: DTSpacing.xl),
          side: BorderSide(color: colors.border),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(DTRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DTSpacing.md,
          vertical: DTSpacing.md,
        ),
        border: _inputBorder(colors.border),
        enabledBorder: _inputBorder(colors.border),
        focusedBorder: _inputBorder(scheme.primary, width: 1.5),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: .16),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : colors.textSecondary,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.muted.withValues(alpha: .6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: DTRadius.xl),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceOverlay,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: onSurface),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(DTRadius.md),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    displaySmall: AppTextStyles.displaySmall.copyWith(color: primary),
    headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
    headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
    headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
    titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
    titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
    titleSmall: AppTextStyles.titleSmall.copyWith(color: primary),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
    bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
    bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
    labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
    labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
    labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(DTRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
}
