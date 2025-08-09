// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'app_theme.dart';

class AppColor {
  // shadcn/ui Primary colors
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;

  // Background colors
  final Color background;
  final Color surface;
  final Color surfaceVariant;

  // Text colors
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;

  // shadcn/ui semantic colors
  final Color border;
  final Color input;
  final Color ring;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;

  // Status colors
  final Color success;
  final Color error;
  final Color warning;

  // Interactive colors
  final Color hover;
  final Color pressed;
  final Color disabled;
  final Color outline;

  const AppColor({
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.border,
    required this.input,
    required this.ring,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.success,
    required this.error,
    required this.warning,
    required this.hover,
    required this.pressed,
    required this.disabled,
    required this.outline,
  });

  AppColor copyWith({
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? onPrimary,
    Color? onSecondary,
    Color? onBackground,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? border,
    Color? input,
    Color? ring,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? success,
    Color? error,
    Color? warning,
    Color? hover,
    Color? pressed,
    Color? disabled,
    Color? outline,
  }) {
    return AppColor(
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      hover: hover ?? this.hover,
      pressed: pressed ?? this.pressed,
      disabled: disabled ?? this.disabled,
      outline: outline ?? this.outline,
    );
  }
}
