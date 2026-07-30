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
/// **색·radius·그림자 파생은 생성기가 한다.** 0.4.0 이
/// `TweakcnColors.fromMap` · `TweakcnRadius.fromRadius` ·
/// `TweakcnShadows.fromShadowMap` 을 생성 파일에 함께 뱉으므로
/// (kihyun1998/flutter_tweakcn_generator#11), 이 파일은 그것을 부른다.
/// 손으로 베낀 사본이 없으니 색 토큰이 추가돼도 조용히 뒤처질 수 없다.
///
/// **아직 사본으로 남은 두 군데가 있고, 둘 다 갈릴 수 있다:**
///
/// - [colorTokens] — CSS 가 정의하지 않은 토큰을 사용자에게 알리는 데만 쓴다.
///   생성기의 목록(`_extensionColorTokens`)이 private 이라 가져올 수 없다.
///   여기가 낡으면 잘못된 색이 아니라 **잘못된 안내**가 나간다.
/// - [_themeFrom] 의 [ColorScheme] 매핑 — 생성기의 `_colorSchemeMapping` 에
///   대응하는 런타임 팩토리가 아직 없다. 여기가 갈리면 화면이 실제로 달라진다.
///
/// 그 두 곳에 "미리보기에서 더 예쁘게 보이도록" 하는 처리를 넣지 말 것.
/// 반영하지 못하는 것은 감추지 않고 [missingTokens] · [unsupportedFont] 로
/// 화면에 알린다.
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

    // 라이트 우선, 없으면 다크. 둘 다 없으면 팩토리가 8.0 을 쓴다.
    // 두 모드가 하나의 radius 를 공유한다.
    final radius = TweakcnRadius.fromRadius(
      parsed.light.radius ?? parsed.dark.radius,
    );

    final missing = <String>{
      ..._missingIn(parsed.light.colors),
      ..._missingIn(parsed.dark.colors),
    }.toList()..sort();

    return PreviewTheme(
      light: _themeFrom(
        brightness: Brightness.light,
        colors: TweakcnColors.fromMap(parsed.light.colors),
        radius: radius,
        shadows: TweakcnShadows.fromShadowMap(parsed.light.shadowLayers),
      ),
      dark: _themeFrom(
        brightness: Brightness.dark,
        colors: TweakcnColors.fromMap(parsed.dark.colors),
        radius: radius,
        shadows: TweakcnShadows.fromShadowMap(parsed.dark.shadowLayers),
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
  ///
  /// 사본인 이유는 그 목록이 private 이기 때문이다. 색을 만드는 데는 쓰이지
  /// 않고 — 그건 `TweakcnColors.fromMap` 이 한다 — CSS 가 정의하지 않은
  /// 토큰을 사용자에게 알리는 데만 쓴다. 그래서 낡았을 때의 증상은 잘못된
  /// 색이 아니라 잘못된 안내다.
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
      // 생성기의 _colorSchemeMapping 과 하나씩 대응한다. 여기에 대응하는
      // 런타임 팩토리는 아직 없어서 사본으로 남는다. 특히 outlineVariant 는
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
}
