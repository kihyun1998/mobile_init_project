import 'package:flutter/material.dart';

import 'foundation/app_theme.dart';
import 'resources/font.dart';
import 'resources/light_palette.dart';

class LightTheme implements AppTheme {
  static final LightTheme _instance = LightTheme._internal();

  factory LightTheme() => _instance;

  late final AppColor _color;
  late final AppFont _font;

  LightTheme._internal() {
    _color = const AppColor(
      primary: LightPalette.primary,
      primaryForeground: LightPalette.primaryForeground,
      secondary: LightPalette.secondary,
      secondaryForeground: LightPalette.secondaryForeground,
      background: LightPalette.background,
      surface: LightPalette.surface,
      surfaceVariant: LightPalette.surfaceVariant,
      onPrimary: LightPalette.onPrimary,
      onSecondary: LightPalette.onSecondary,
      onBackground: LightPalette.onBackground,
      onSurface: LightPalette.onSurface,
      onSurfaceVariant: LightPalette.onSurfaceVariant,
      border: LightPalette.border,
      input: LightPalette.input,
      ring: LightPalette.ring,
      muted: LightPalette.muted,
      mutedForeground: LightPalette.mutedForeground,
      accent: LightPalette.accent,
      accentForeground: LightPalette.accentForeground,
      success: LightPalette.success,
      error: LightPalette.error,
      warning: LightPalette.warning,
      hover: LightPalette.hover,
      pressed: LightPalette.pressed,
      disabled: LightPalette.disabled,
      outline: LightPalette.outline,
    );

    _font = AppFont(
      font: const Pretendard(),
      monoFont: const SpaceMono(),
      textColor: _color.onBackground,
      hintColor: _color.mutedForeground,
    );
  }

  @override
  AppColor get color => _color;

  @override
  AppFont get font => _font;

  @override
  AppMode get mode => AppMode.light;

  @override
  ThemeData get themeData => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _color.background,
      );
}
