import 'package:flutter/material.dart';

abstract class LightPalette {
  // Primary colors - shadcn/ui Zinc theme
  static const Color primary = Color(0xFF18181b); // Zinc-900
  static const Color primaryForeground = Color(0xFFfafafa); // Zinc-50
  static const Color secondary = Color(0xFF71717a); // Zinc-500
  static const Color secondaryForeground = Color(0xFFfafafa); // Zinc-50

  // Background colors - shadcn/ui Light Mode
  static const Color background = Color(0xFFfafafa); // Zinc-50
  static const Color surface = Color(0xFFf4f4f5); // Zinc-100
  static const Color surfaceVariant = Color(0xFFe4e4e7); // Zinc-200

  // Text colors
  static const Color onPrimary = Color(0xFFfafafa); // Zinc-50
  static const Color onSecondary = Color(0xFFfafafa); // Zinc-50
  static const Color onBackground = Color(0xFF18181b); // Zinc-900
  static const Color onSurface = Color(0xFF18181b); // Zinc-900
  static const Color onSurfaceVariant = Color(0xFF71717a); // Zinc-500

  // shadcn/ui semantic colors
  static const Color border = Color(0xFFe4e4e7); // Zinc-200
  static const Color input = Color(0xFFffffff); // White
  static const Color ring = Color(0xFF18181b); // Zinc-900
  static const Color muted = Color(0xFFf4f4f5); // Zinc-100
  static const Color mutedForeground = Color(0xFF71717a); // Zinc-500
  static const Color accent = Color(0xFFf4f4f5); // Zinc-100
  static const Color accentForeground = Color(0xFF18181b); // Zinc-900

  // Status colors
  static const Color success = Color(0xFF22c55e); // Green-500
  static const Color error = Color(0xFFef4444); // Red-500
  static const Color warning = Color(0xFFf59e0b); // Yellow-500

  // Interactive colors
  static const Color hover = Color(0x0D000000); // Black 5% opacity
  static const Color pressed = Color(0xFFe4e4e7); // Zinc-200
  static const Color disabled = Color(0xFFa1a1aa); // Zinc-400
  static const Color outline = Color(0xFFe4e4e7); // Zinc-200
}
