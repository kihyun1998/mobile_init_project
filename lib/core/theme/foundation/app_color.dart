// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'app_theme.dart';

class AppColor {
  // Primary colors
  final Color primary;
  final Color primarySoft;
  final Color primaryVariant;
  final Color primaryHover;
  final Color primarySplash;
  final Color primaryHighlight;

  final Color secondary;
  final Color secondaryVariant;

  // Background colors
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceVariantSoft;

  // Terminal specific colors
  final Color terminalBackground;
  final Color terminalSurface;
  final Color terminalBorder;

  // Text colors
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onBackgroundSoft;
  final Color onSurface;
  final Color onSurfaceVariant;

  // Terminal text colors
  final Color terminalText;
  final Color terminalPrompt;
  final Color terminalCommand;
  final Color terminalOutput;

  // Status colors
  final Color success;
  final Color successVariant;
  final Color error;
  final Color errorVariant;
  final Color warning;
  final Color info;

  // Connection status
  final Color connected;
  final Color disconnected;
  final Color connecting;

  // Interactive colors
  final Color hover;
  final Color splash;
  final Color highlight;
  final Color pressed;
  final Color disabled;
  final Color border;

  // Divider and outline
  final Color divider;
  final Color outline;

  // Accent colors for neon effects
  final Color neonPurple;
  final Color neonGreen;
  final Color neonPink;
  final Color neonBlue;

  // Gaming-specific colors
  final Color gamingHighlight;
  final Color gamingShadow;
  final Color powerGlow;
  final Color neonTrail;
  final Color energyCore;

  const AppColor({
    required this.primary,
    required this.primarySoft,
    required this.primaryVariant,
    required this.primaryHover,
    required this.primarySplash,
    required this.primaryHighlight,
    required this.secondary,
    required this.secondaryVariant,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceVariantSoft,
    required this.terminalBackground,
    required this.terminalSurface,
    required this.terminalBorder,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onBackgroundSoft,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.terminalText,
    required this.terminalPrompt,
    required this.terminalCommand,
    required this.terminalOutput,
    required this.success,
    required this.successVariant,
    required this.error,
    required this.errorVariant,
    required this.warning,
    required this.info,
    required this.connected,
    required this.disconnected,
    required this.connecting,
    required this.hover,
    required this.splash,
    required this.highlight,
    required this.pressed,
    required this.disabled,
    required this.border,
    required this.divider,
    required this.outline,
    required this.neonPurple,
    required this.neonGreen,
    required this.neonPink,
    required this.neonBlue,
    required this.gamingHighlight,
    required this.gamingShadow,
    required this.powerGlow,
    required this.neonTrail,
    required this.energyCore,
  });

  AppColor copyWith({
    Color? primary,
    Color? primarySoft,
    Color? primaryVariant,
    Color? primaryHover,
    Color? primarySplash,
    Color? primaryHighlight,
    Color? secondary,
    Color? secondaryVariant,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceVariantSoft,
    Color? terminalBackground,
    Color? terminalSurface,
    Color? terminalBorder,
    Color? onPrimary,
    Color? onSecondary,
    Color? onBackground,
    Color? onBackgroundSoft,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? terminalText,
    Color? terminalPrompt,
    Color? terminalCommand,
    Color? terminalOutput,
    Color? success,
    Color? successVariant,
    Color? error,
    Color? errorVariant,
    Color? warning,
    Color? info,
    Color? connected,
    Color? disconnected,
    Color? connecting,
    Color? hover,
    Color? splash,
    Color? highlight,
    Color? pressed,
    Color? disabled,
    Color? border,
    Color? divider,
    Color? outline,
    Color? neonPurple,
    Color? neonGreen,
    Color? neonPink,
    Color? neonBlue,
    Color? gamingHighlight,
    Color? gamingShadow,
    Color? powerGlow,
    Color? neonTrail,
    Color? energyCore,
  }) {
    return AppColor(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      primaryHover: primaryHover ?? this.primaryHover,
      primarySplash: primarySplash ?? this.primarySplash,
      primaryHighlight: primaryHighlight ?? this.primaryHighlight,
      secondary: secondary ?? this.secondary,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceVariantSoft: surfaceVariantSoft ?? this.surfaceVariantSoft,
      terminalBackground: terminalBackground ?? this.terminalBackground,
      terminalSurface: terminalSurface ?? this.terminalSurface,
      terminalBorder: terminalBorder ?? this.terminalBorder,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onBackground: onBackground ?? this.onBackground,
      onBackgroundSoft: onBackgroundSoft ?? this.onBackgroundSoft,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      terminalText: terminalText ?? this.terminalText,
      terminalPrompt: terminalPrompt ?? this.terminalPrompt,
      terminalCommand: terminalCommand ?? this.terminalCommand,
      terminalOutput: terminalOutput ?? this.terminalOutput,
      success: success ?? this.success,
      successVariant: successVariant ?? this.successVariant,
      error: error ?? this.error,
      errorVariant: errorVariant ?? this.errorVariant,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      connected: connected ?? this.connected,
      disconnected: disconnected ?? this.disconnected,
      connecting: connecting ?? this.connecting,
      hover: hover ?? this.hover,
      splash: splash ?? this.splash,
      highlight: highlight ?? this.highlight,
      pressed: pressed ?? this.pressed,
      disabled: disabled ?? this.disabled,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      outline: outline ?? this.outline,
      neonPurple: neonPurple ?? this.neonPurple,
      neonGreen: neonGreen ?? this.neonGreen,
      neonPink: neonPink ?? this.neonPink,
      neonBlue: neonBlue ?? this.neonBlue,
      gamingHighlight: gamingHighlight ?? this.gamingHighlight,
      gamingShadow: gamingShadow ?? this.gamingShadow,
      powerGlow: powerGlow ?? this.powerGlow,
      neonTrail: neonTrail ?? this.neonTrail,
      energyCore: energyCore ?? this.energyCore,
    );
  }
}
