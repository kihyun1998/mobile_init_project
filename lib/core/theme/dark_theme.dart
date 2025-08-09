import 'package:flutter/material.dart';

import 'foundation/app_theme.dart';
import 'resources/dark_palette.dart';
import 'resources/font.dart';

class DarkTheme implements AppTheme {
  static final DarkTheme _instance = DarkTheme._internal();

  factory DarkTheme() => _instance;

  late final AppColor _color;
  late final AppFont _font;

  DarkTheme._internal() {
    _color = const AppColor(
      primary: DarkPalette.primary,
      primaryForeground: DarkPalette.primaryForeground,
      secondary: DarkPalette.secondary,
      secondaryForeground: DarkPalette.secondaryForeground,
      background: DarkPalette.background,
      surface: DarkPalette.surface,
      surfaceVariant: DarkPalette.surfaceVariant,
      onPrimary: DarkPalette.onPrimary,
      onSecondary: DarkPalette.onSecondary,
      onBackground: DarkPalette.onBackground,
      onSurface: DarkPalette.onSurface,
      onSurfaceVariant: DarkPalette.onSurfaceVariant,
      border: DarkPalette.border,
      input: DarkPalette.input,
      ring: DarkPalette.ring,
      muted: DarkPalette.muted,
      mutedForeground: DarkPalette.mutedForeground,
      accent: DarkPalette.accent,
      accentForeground: DarkPalette.accentForeground,
      success: DarkPalette.success,
      error: DarkPalette.error,
      warning: DarkPalette.warning,
      hover: DarkPalette.hover,
      pressed: DarkPalette.pressed,
      disabled: DarkPalette.disabled,
      outline: DarkPalette.outline,
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
  AppMode get mode => AppMode.dark;

  @override
  ThemeData get themeData => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _color.background,
      );
}
