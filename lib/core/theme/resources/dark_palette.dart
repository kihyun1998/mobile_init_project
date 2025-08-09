import 'package:flutter/material.dart';

abstract class DarkPalette {
// Primary colors - Neon/Gaming Theme
  static const Color primary = Color(0xFF8B5CF6); // Violet-500
  static const Color primarySoft =
      Color(0x268B5CF6); // primary.withOpacity(0.15) - 활성 탭 배경
  static const Color primaryVariant = Color(0xFF7C3AED); // Violet-600
  static const Color primaryHover =
      Color(0x1A8B5CF6); // Violet-500 with 10% opacity
  static const Color primarySplash =
      Color(0x338B5CF6); // Violet-500 with 20% opacity
  static const Color primaryHighlight =
      Color(0x1A8B5CF6); // Violet-500 with 10% opacity
  static const Color secondary = Color(0xFF10B981); // Emerald-500
  static const Color secondaryVariant = Color(0xFF059669); // Emerald-600

  // Background colors
  static const Color background = Color(0xFF111827); // Gray-900
  static const Color surface = Color(0xFF1F2937); // Gray-800
  static const Color surfaceVariant = Color(0xFF374151); // Gray-700
  static const Color surfaceVariantSoft =
      Color(0x66374151); // surfaceVariant.withOpacity(0.4) - 비활성 탭 배경

  // Terminal specific colors
  static const Color terminalBackground = Color(0xFF000000); // Pure black
  static const Color terminalSurface = Color(0xFF111827); // Gray-900
  static const Color terminalBorder = Color(0xFF374151); // Gray-700

  // Text colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFF9FAFB); // Gray-50
  static const Color onBackgroundSoft =
      Color(0xB3F9FAFB); // onBackground.withOpacity(0.7) - 부드러운 텍스트
  static const Color onSurface = Color(0xFFF9FAFB); // Gray-50
  static const Color onSurfaceVariant = Color(0xFF9CA3AF); // Gray-400

  // Terminal text colors
  static const Color terminalText = Color(0xFFD1D5DB); // Gray-300
  static const Color terminalPrompt = Color(0xFF10B981); // Emerald-500
  static const Color terminalCommand = Color(0xFF8B5CF6); // Violet-500
  static const Color terminalOutput = Color(0xFFD1D5DB); // Gray-300

  // Status colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successVariant = Color(0xFF059669); // Emerald-600
  static const Color error = Color(0xFFF87171); // Red-400
  static const Color errorVariant = Color(0xFFEF4444); // Red-500
  static const Color warning = Color(0xFFFBBF24); // Yellow-400
  static const Color info = Color(0xFF8B5CF6); // Violet-500

  // Connection status
  static const Color connected = Color(0xFF10B981); // Emerald-500
  static const Color disconnected = Color(0xFFF87171); // Red-400
  static const Color connecting = Color(0xFFFBBF24); // Yellow-400

  // Interactive colors
  static const Color hover = Color(0x0DFFFFFF); // White 5% opacity
  static const Color splash = Color(0x1AFFFFFF); // White 10% opacity
  static const Color highlight = Color(0x14FFFFFF); // White 8% opacity
  static const Color pressed = Color(0xFF4B5563); // Gray-600
  static const Color disabled = Color(0xFF6B7280); // Gray-500
  static const Color border = Color(0xFF4B5563); // Gray-600

  // Divider and outline
  static const Color divider = Color(0xFF374151); // Gray-700
  static const Color outline = Color(0xFF4B5563); // Gray-600

  // Accent colors for neon effects - Dark Mode optimized
  static const Color neonPurple =
      Color(0xFFA855F7); // Violet-400 (brighter for dark mode)
  static const Color neonGreen =
      Color(0xFF34D399); // Emerald-400 (brighter for dark mode)
  static const Color neonPink =
      Color(0xFFF472B6); // Pink-400 (brighter for dark mode)
  static const Color neonBlue =
      Color(0xFF60A5FA); // Blue-400 (brighter for dark mode)

  // Gaming-specific colors
  static const Color gamingHighlight = Color(0xFFDDD6FE); // Violet-200
  static const Color gamingShadow = Color(0xFF581C87); // Violet-900
  static const Color powerGlow = Color(0xFF34D399); // Emerald-400
  static const Color neonTrail = Color(0xFFF472B6); // Pink-400 trail effect
  static const Color energyCore =
      Color(0xFFA855F7); // Violet-400 for energy cores
}

// Usage example for Gaming Style SSH Terminal:
// 
// class AppTheme {
//   static ThemeData lightGamingTheme = ThemeData(
//     primaryColor: LightPalette.primary,
//     scaffoldBackgroundColor: LightPalette.background,
//     colorScheme: ColorScheme.light(
//       primary: LightPalette.primary,
//       secondary: LightPalette.secondary,
//       surface: LightPalette.surface,
//       background: LightPalette.background,
//     ),
//   );
//
//   static ThemeData darkGamingTheme = ThemeData(
//     primaryColor: DarkPalette.primary,
//     scaffoldBackgroundColor: DarkPalette.background,
//     colorScheme: ColorScheme.dark(
//       primary: DarkPalette.primary,
//       secondary: DarkPalette.secondary,
//       surface: DarkPalette.surface,
//       background: DarkPalette.background,
//     ),
//   );
// }
//
// Gaming-style connect button:
//
// Widget gamingConnectButton(bool isDarkMode) {
//   final palette = isDarkMode ? DarkPalette : LightPalette;
//   
//   return Container(
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(8),
//       boxShadow: [
//         BoxShadow(
//           color: palette.primary.withOpacity(0.4),
//           blurRadius: 15,
//           spreadRadius: 0,
//           offset: Offset(0, 4),
//         ),
//       ],
//     ),
//     child: ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: palette.primary,
//         foregroundColor: palette.onPrimary,
//         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       child: Text('Connect', 
//            style: TextStyle(fontWeight: FontWeight.bold)),
//       onPressed: () {
//         // Connect logic
//       },
//     ),
//   );
// }