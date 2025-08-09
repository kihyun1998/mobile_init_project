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
      primarySoft: DarkPalette.primarySoft,
      primaryVariant: DarkPalette.primaryVariant,
      primaryHover: DarkPalette.primaryHover,
      primarySplash: DarkPalette.primarySplash,
      primaryHighlight: DarkPalette.primaryHighlight,
      secondary: DarkPalette.secondary,
      secondaryVariant: DarkPalette.secondaryVariant,
      background: DarkPalette.background,
      surface: DarkPalette.surface,
      surfaceVariant: DarkPalette.surfaceVariant,
      surfaceVariantSoft: DarkPalette.surfaceVariantSoft,
      terminalBackground: DarkPalette.terminalBackground,
      terminalSurface: DarkPalette.terminalSurface,
      terminalBorder: DarkPalette.terminalBorder,
      onPrimary: DarkPalette.onPrimary,
      onSecondary: DarkPalette.onSecondary,
      onBackground: DarkPalette.onBackground,
      onBackgroundSoft: DarkPalette.onBackgroundSoft,
      onSurface: DarkPalette.onSurface,
      onSurfaceVariant: DarkPalette.onSurfaceVariant,
      terminalText: DarkPalette.terminalText,
      terminalPrompt: DarkPalette.terminalPrompt,
      terminalCommand: DarkPalette.terminalCommand,
      terminalOutput: DarkPalette.terminalOutput,
      success: DarkPalette.success,
      successVariant: DarkPalette.successVariant,
      error: DarkPalette.error,
      errorVariant: DarkPalette.errorVariant,
      warning: DarkPalette.warning,
      info: DarkPalette.info,
      connected: DarkPalette.connected,
      disconnected: DarkPalette.disconnected,
      connecting: DarkPalette.connecting,
      hover: DarkPalette.hover,
      splash: DarkPalette.splash,
      highlight: DarkPalette.highlight,
      pressed: DarkPalette.pressed,
      disabled: DarkPalette.disabled,
      border: DarkPalette.border,
      divider: DarkPalette.divider,
      outline: DarkPalette.outline,
      neonPurple: DarkPalette.neonPurple,
      neonGreen: DarkPalette.neonGreen,
      neonPink: DarkPalette.neonPink,
      neonBlue: DarkPalette.neonBlue,
      gamingHighlight: DarkPalette.gamingHighlight,
      gamingShadow: DarkPalette.gamingShadow,
      powerGlow: DarkPalette.powerGlow,
      neonTrail: DarkPalette.neonTrail,
      energyCore: DarkPalette.energyCore,
    );

    _font = AppFont(
      font: const Pretendard(),
      monoFont: const SpaceMono(),
      textColor: _color.onBackground,
      hintColor: _color.onSurfaceVariant,
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
