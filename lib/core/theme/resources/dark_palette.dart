import 'package:flutter/material.dart';

abstract class DarkPalette {
  // Primary colors - shadcn/ui Zinc theme
  static const Color primary = Color(0xFFfafafa); // Zinc-50
  static const Color primaryForeground = Color(0xFF18181b); // Zinc-900
  static const Color secondary = Color(0xFFa1a1aa); // Zinc-400
  static const Color secondaryForeground = Color(0xFF18181b); // Zinc-900

  // Background colors - shadcn/ui Dark Mode
  static const Color background = Color(0xFF09090b); // Zinc-950
  static const Color surface = Color(0xFF18181b); // Zinc-900
  static const Color surfaceVariant = Color(0xFF27272a); // Zinc-800

  // Text colors
  static const Color onPrimary = Color(0xFF18181b); // Zinc-900
  static const Color onSecondary = Color(0xFF18181b); // Zinc-900
  static const Color onBackground = Color(0xFFfafafa); // Zinc-50
  static const Color onSurface = Color(0xFFfafafa); // Zinc-50
  static const Color onSurfaceVariant = Color(0xFFa1a1aa); // Zinc-400

  // shadcn/ui semantic colors
  static const Color border = Color(0xFF27272a); // Zinc-800
  static const Color input = Color(0xFF09090b); // Zinc-950
  static const Color ring = Color(0xFFfafafa); // Zinc-50
  static const Color muted = Color(0xFF18181b); // Zinc-900
  static const Color mutedForeground = Color(0xFFa1a1aa); // Zinc-400
  static const Color accent = Color(0xFF27272a); // Zinc-800
  static const Color accentForeground = Color(0xFFfafafa); // Zinc-50

  // Status colors
  static const Color success = Color(0xFF22c55e); // Green-500
  static const Color error = Color(0xFFef4444); // Red-500
  static const Color warning = Color(0xFFf59e0b); // Yellow-500

  // Interactive colors
  static const Color hover = Color(0x0DFFFFFF); // White 5% opacity
  static const Color pressed = Color(0xFF27272a); // Zinc-800
  static const Color disabled = Color(0xFF71717a); // Zinc-500
  static const Color outline = Color(0xFF27272a); // Zinc-800
}