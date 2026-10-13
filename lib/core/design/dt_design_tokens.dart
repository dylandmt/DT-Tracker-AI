import 'package:flutter/material.dart';

abstract final class DTSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

abstract final class DTRadius {
  static const sm = Radius.circular(10);
  static const md = Radius.circular(14);
  static const lg = Radius.circular(20);
  static const xl = Radius.circular(26);
  static const pill = Radius.circular(999);
}

abstract final class DTMotion {
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 320);
}

abstract final class DTAssets {
  static const darkAmbient =
      'assets/design_system/backgrounds/dark-ambient.svg';
  static const lightAmbient =
      'assets/design_system/backgrounds/light-ambient.svg';
  static const mapMarkerHalo =
      'assets/design_system/backgrounds/map-marker-halo.svg';
}

class DTThemeColors extends ThemeExtension<DTThemeColors> {
  const DTThemeColors({
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.border,
    required this.textSecondary,
    required this.muted,
    required this.primaryBright,
    required this.primaryDeep,
    required this.primaryPale,
    required this.cyan,
    required this.purple,
    required this.online,
    required this.offline,
    required this.moving,
    required this.idle,
    required this.alert,
  });

  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color border;
  final Color textSecondary;
  final Color muted;
  final Color primaryBright;
  final Color primaryDeep;
  final Color primaryPale;
  final Color cyan;
  final Color purple;
  final Color online;
  final Color offline;
  final Color moving;
  final Color idle;
  final Color alert;

  @override
  DTThemeColors copyWith({
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? border,
    Color? textSecondary,
    Color? muted,
    Color? primaryBright,
    Color? primaryDeep,
    Color? primaryPale,
    Color? cyan,
    Color? purple,
    Color? online,
    Color? offline,
    Color? moving,
    Color? idle,
    Color? alert,
  }) => DTThemeColors(
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
    border: border ?? this.border,
    textSecondary: textSecondary ?? this.textSecondary,
    muted: muted ?? this.muted,
    primaryBright: primaryBright ?? this.primaryBright,
    primaryDeep: primaryDeep ?? this.primaryDeep,
    primaryPale: primaryPale ?? this.primaryPale,
    cyan: cyan ?? this.cyan,
    purple: purple ?? this.purple,
    online: online ?? this.online,
    offline: offline ?? this.offline,
    moving: moving ?? this.moving,
    idle: idle ?? this.idle,
    alert: alert ?? this.alert,
  );

  @override
  DTThemeColors lerp(DTThemeColors? other, double t) {
    if (other is! DTThemeColors) return this;
    return DTThemeColors(
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      primaryBright: Color.lerp(primaryBright, other.primaryBright, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primaryPale: Color.lerp(primaryPale, other.primaryPale, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      moving: Color.lerp(moving, other.moving, t)!,
      idle: Color.lerp(idle, other.idle, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
    );
  }
}

extension DTThemeColorsContext on BuildContext {
  DTThemeColors get dtColors => Theme.of(this).extension<DTThemeColors>()!;
}
