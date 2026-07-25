import 'package:flutter/material.dart';
import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

/// 붙여넣은 CSS 가 미리보기로 갈 수 없을 때 던진다.
class PreviewThemeException implements Exception {
  const PreviewThemeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// tweakcn CSS 한 덩어리를 라이트/다크 [ThemeData] 한 쌍으로 바꾼다.
///
/// **파서 출력을 테마로 옮기는 매핑은 전부 이 파일 안에 있다.**
/// `flutter_tweakcn_generator` 는 빌드 타임 코드 생성기라 CSS → Dart 소스는
/// 하지만 CSS → 런타임 객체는 하지 못한다. 그 간극을 여기서 메운다.
/// 생성기에 런타임 팩토리가 들어오면
/// (kihyun1998/flutter_tweakcn_generator#11) [_colorsFrom]·[_radiusFrom]·
/// [_shadowsFrom] 세 함수만 그 호출로 바꾸면 된다.
///
/// **모든 파생 규칙은 생성기가 하는 것을 그대로 따라간다** — 색 매핑, 누락
/// 토큰 처리, radius 공식까지. 여기서 한 군데라도 갈리면 미리보기가 생성
/// 결과와 다른 화면을 보여주고, 그 순간 이 도구의 존재 이유가 사라진다.
/// "미리보기에서 더 예쁘게 보이도록" 하는 처리를 넣지 말 것.
class PreviewTheme {
  const PreviewTheme({
    required this.light,
    required this.dark,
    required this.missingTokens,
    required this.unsupportedFont,
  });

  final ThemeData light;
  final ThemeData dark;

  /// CSS 에 없어서 생성기가 투명으로 채울 색 토큰들.
  ///
  /// 미리보기도 똑같이 투명으로 둔다. 템플릿 색으로 대신 채우면 화면은
  /// 그럴듯해지지만 생성된 앱은 투명하게 나온다.
  final List<String> missingTokens;

  /// CSS 가 지정했지만 미리보기가 반영하지 못하는 폰트.
  ///
  /// 생성기는 Google Font 를 받아 `fontFamily` 로 굽지만, 미리보기는 런타임에
  /// 폰트를 내려받지 않는다. 생성된 앱과 글꼴이 다를 수 있다는 뜻이다.
  final String? unsupportedFont;

  factory PreviewTheme.fromCss(String css) {
    if (css.trim().isEmpty) {
      throw const PreviewThemeException('CSS 가 비어 있습니다.');
    }

    final TweakcnThemeData parsed;
    try {
      parsed = CssParser.parse(css);
    } catch (e) {
      throw PreviewThemeException('CSS 를 읽지 못했습니다: $e');
    }

    if (parsed.light.colors.isEmpty && parsed.dark.colors.isEmpty) {
      throw const PreviewThemeException(
        '색 토큰을 하나도 찾지 못했습니다. '
        'tweakcn 에서 복사한 :root { --background: ... } 형태가 맞는지 보세요.',
      );
    }

    // 생성기와 같다: 라이트 우선, 없으면 다크, 둘 다 없으면 8.0.
    // 두 모드가 하나의 radius 를 공유한다.
    final radius = _radiusFrom(parsed.light.radius ?? parsed.dark.radius);

    final missing = <String>{
      ..._missingIn(parsed.light.colors),
      ..._missingIn(parsed.dark.colors),
    }.toList()..sort();

    return PreviewTheme(
      light: _themeFrom(
        brightness: Brightness.light,
        colors: _colorsFrom(parsed.light.colors),
        radius: radius,
        shadows: _shadowsFrom(parsed.light.shadows),
      ),
      dark: _themeFrom(
        brightness: Brightness.dark,
        colors: _colorsFrom(parsed.dark.colors),
        radius: radius,
        shadows: _shadowsFrom(parsed.dark.shadows),
      ),
      missingTokens: missing,
      // 생성기와 같은 추출기를 쓴다. 미리보기는 폰트를 반영하지 못하므로
      // 이름만 들고 있다가 사용자에게 알린다.
      unsupportedFont:
          DartThemeGenerator.extractGoogleFontNames(parsed.light.fontSans)
              .firstOrNull,
    );
  }

  /// 생성기의 `_extensionColorTokens` 와 같은 목록이어야 한다.
  static const colorTokens = <String>[
    'background', 'foreground',
    'card', 'card-foreground',
    'popover', 'popover-foreground',
    'primary', 'primary-foreground',
    'secondary', 'secondary-foreground',
    'muted', 'muted-foreground',
    'accent', 'accent-foreground',
    'destructive', 'destructive-foreground',
    'border', 'input', 'ring',
    'chart-1', 'chart-2', 'chart-3', 'chart-4', 'chart-5',
    'sidebar', 'sidebar-foreground',
    'sidebar-primary', 'sidebar-primary-foreground',
    'sidebar-accent', 'sidebar-accent-foreground',
    'sidebar-border', 'sidebar-ring',
  ];

  static Iterable<String> _missingIn(Map<String, int> css) =>
      colorTokens.where((t) => !css.containsKey(t));

  static ThemeData _themeFrom({
    required Brightness brightness,
    required TweakcnColors colors,
    required TweakcnRadius radius,
    required TweakcnShadows shadows,
  }) {
    return ThemeData(
      brightness: brightness,
      // 생성기의 _colorSchemeMapping 과 하나씩 대응한다. 특히 outlineVariant 는
      // border 가 아니라 input, surfaceContainerLowest 는 background 가 아니라
      // card 다. 템플릿 CSS 는 두 쌍이 같은 값이라 틀려도 티가 나지 않는다.
      colorScheme: ColorScheme(
        brightness: brightness,
        surface: colors.background,
        onSurface: colors.foreground,
        primary: colors.primary,
        onPrimary: colors.primaryForeground,
        secondary: colors.secondary,
        onSecondary: colors.secondaryForeground,
        error: colors.destructive,
        onError: colors.destructiveForeground,
        outline: colors.border,
        outlineVariant: colors.input,
        surfaceContainerLowest: colors.card,
        surfaceContainerHighest: colors.muted,
        onSurfaceVariant: colors.mutedForeground,
      ),
      extensions: [colors, radius, shadows],
    );
  }

  /// CSS 변수 이름(kebab) → [TweakcnColors] 필드.
  ///
  /// 없는 토큰은 **생성기와 똑같이 투명**으로 둔다. 템플릿 색으로 채우면
  /// 미리보기는 멀쩡한데 생성된 앱만 투명해진다.
  static TweakcnColors _colorsFrom(Map<String, int> css) {
    Color pick(String token) => Color(css[token] ?? 0x00000000);

    return TweakcnColors(
      background: pick('background'),
      foreground: pick('foreground'),
      card: pick('card'),
      cardForeground: pick('card-foreground'),
      popover: pick('popover'),
      popoverForeground: pick('popover-foreground'),
      primary: pick('primary'),
      primaryForeground: pick('primary-foreground'),
      secondary: pick('secondary'),
      secondaryForeground: pick('secondary-foreground'),
      muted: pick('muted'),
      mutedForeground: pick('muted-foreground'),
      accent: pick('accent'),
      accentForeground: pick('accent-foreground'),
      destructive: pick('destructive'),
      destructiveForeground: pick('destructive-foreground'),
      border: pick('border'),
      input: pick('input'),
      ring: pick('ring'),
      chart1: pick('chart-1'),
      chart2: pick('chart-2'),
      chart3: pick('chart-3'),
      chart4: pick('chart-4'),
      chart5: pick('chart-5'),
      sidebar: pick('sidebar'),
      sidebarForeground: pick('sidebar-foreground'),
      sidebarPrimary: pick('sidebar-primary'),
      sidebarPrimaryForeground: pick('sidebar-primary-foreground'),
      sidebarAccent: pick('sidebar-accent'),
      sidebarAccentForeground: pick('sidebar-accent-foreground'),
      sidebarBorder: pick('sidebar-border'),
      sidebarRing: pick('sidebar-ring'),
    );
  }

  /// shadcn 규칙: lg = radius, md = radius-2, sm = radius-4, xl = radius+4.
  /// `--radius` 가 없을 때의 기본 8.0 까지 생성기와 같다.
  static TweakcnRadius _radiusFrom(double? radius) {
    final base = radius ?? 8.0;

    return TweakcnRadius(
      sm: (base - 4).clamp(0.0, double.infinity),
      md: (base - 2).clamp(0.0, double.infinity),
      lg: base,
      xl: base + 4,
    );
  }

  /// 없는 그림자는 생성기와 같이 빈 목록이다.
  static TweakcnShadows _shadowsFrom(Map<String, List<ShadowData>> css) {
    List<BoxShadow> pick(String token) =>
        (css[token] ?? const <ShadowData>[])
            .map(
              (s) => BoxShadow(
                offset: Offset(s.offsetX, s.offsetY),
                blurRadius: s.blurRadius,
                spreadRadius: s.spreadRadius,
                color: Color(s.color),
              ),
            )
            .toList();

    return TweakcnShadows(
      shadow2xs: pick('shadow-2xs'),
      shadowXs: pick('shadow-xs'),
      shadowSm: pick('shadow-sm'),
      shadow: pick('shadow'),
      shadowMd: pick('shadow-md'),
      shadowLg: pick('shadow-lg'),
      shadowXl: pick('shadow-xl'),
      shadow2xl: pick('shadow-2xl'),
    );
  }
}
