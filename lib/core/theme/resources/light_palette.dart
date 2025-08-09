import 'package:flutter/material.dart';

abstract class LightPalette {
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

  // Background colors - Gaming Style Light Mode
  static const Color background = Color(0xFFF8FAFC); // 약간 보라 틴트
  static const Color surface = Color(0xFFF1F5F9); // 쿨톤 표면
  static const Color surfaceVariant = Color(0xFFE2E8F0); // 더 진한 쿨톤
  static const Color surfaceVariantSoft =
      Color(0x66E2E8F0); // surfaceVariant.withOpacity(0.4) - 비활성 탭 배경

  // Terminal specific colors
  static const Color terminalBackground = Color(0xFF1F2937); // Gray-800
  static const Color terminalSurface = Color(0xFF374151); // Gray-700
  static const Color terminalBorder = Color(0xFF6B7280); // Gray-500

  // Text colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF111827); // Gray-900
  static const Color onBackgroundSoft =
      Color(0xB3111827); // onBackground.withOpacity(0.7) - 부드러운 텍스트
  static const Color onSurface = Color(0xFF111827); // Gray-900
  static const Color onSurfaceVariant = Color(0xFF6B7280); // Gray-500

  // Terminal text colors
  static const Color terminalText = Color(0xFFD1D5DB); // Gray-300
  static const Color terminalPrompt = Color(0xFF10B981); // Emerald-500
  static const Color terminalCommand = Color(0xFF8B5CF6); // Violet-500
  static const Color terminalOutput = Color(0xFFD1D5DB); // Gray-300

  // Status colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successVariant = Color(0xFF059669); // Emerald-600
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorVariant = Color(0xFFDC2626); // Red-600
  static const Color warning = Color(0xFFF59E0B); // Yellow-500
  static const Color info = Color(0xFF8B5CF6); // Violet-500

  // Connection status
  static const Color connected = Color(0xFF10B981); // Emerald-500
  static const Color disconnected = Color(0xFFEF4444); // Red-500
  static const Color connecting = Color(0xFFF59E0B); // Yellow-500

  // Interactive colors - Gaming Style
  static const Color hover = Color(0x0D000000); // Black 5% opacity
  static const Color splash = Color(0x1A000000); // Black 10% opacity
  static const Color highlight = Color(0x14000000); // Black 8% opacity
  static const Color pressed = Color(0xFFCBD5E1); // 쿨톤 pressed
  static const Color disabled = Color(0xFF94A3B8); // 슬레이트 400
  static const Color border = Color(0xFFCBD5E1); // 슬레이트 300

  // Divider and outline - Gaming Style
  static const Color divider = Color(0xFFE2E8F0); // 슬레이트 200
  static const Color outline = Color(0xFFCBD5E1); // 슬레이트 300

  // Gaming-specific accent colors for Light Mode
  static const Color gamingAccent = Color(0xFFE879F9); // 핑크 글로우
  static const Color neonHighlight = Color(0xFFDDD6FE); // 바이올렛 하이라이트
  static const Color energyGlow = Color(0xFF34D399); // 에너지 글로우
  static const Color powerRing = Color(0xFFF0ABFC); // 퓨샤 하이라이트

  // Accent colors for neon effects - Light Mode optimized
  static const Color neonPurple = Color(0xFF8B5CF6); // Violet-500
  static const Color neonGreen = Color(0xFF10B981); // Emerald-500
  static const Color neonPink = Color(0xFFEC4899); // Pink-500
  static const Color neonBlue = Color(0xFF3B82F6); // Blue-500

  // Gaming UI enhancement colors
  static const Color glowShadow =
      Color(0x1A8B5CF6); // 10% opacity violet for shadows
  static const Color energyShadow =
      Color(0x1A10B981); // 10% opacity emerald for shadows

  // Gaming-specific colors
  static const Color gamingHighlight = Color(0xFFDDD6FE); // Violet-200
  static const Color gamingShadow = Color(0xFF581C87); // Violet-900
  static const Color powerGlow = Color(0xFF34D399); // Emerald-400
  static const Color neonTrail = Color(0xFFF472B6); // Pink-400 trail effect
  static const Color energyCore =
      Color(0xFFA855F7); // Violet-400 for energy cores
}
