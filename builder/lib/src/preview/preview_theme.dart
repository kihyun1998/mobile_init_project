import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../generation/generation_exception.dart';
import '../generation/theme_css.dart';

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
/// - [_colorSchemeFrom] — 생성기의 `ColorSchemeResolver` 사본이다. 그 클래스는
///   public 이지만 패키지가 export 하지 않아서 부를 수 없다
///   (kihyun1998/flutter_tweakcn_generator#22 로 export 를 요청해 뒀고, 들어오면
///   이 사본은 통째로 사라진다). 여기가 갈리면 화면이 실제로 달라진다.
///
/// 그 사본이 조용히 낡지 않도록 `preview_colorscheme_parity_test.dart` 가
/// **진짜 생성기를 돌려** 결과를 대조한다. 상류가 fallback 규칙을 바꾸면 그
/// 테스트가 깨진다.
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
  ///
  /// **이건 [TweakcnColors] extension 에 한한 이야기다.** `ColorScheme` 쪽은
  /// 생성기가 투명이 아니라 파생 fallback 을 넣으므로 미리보기도 그렇게 한다
  /// ([_colorSchemeFrom]). 두 경로가 없는 토큰을 다르게 다루는 것이 맞다 —
  /// 생성기가 그렇게 하기 때문이다.
  final List<String> missingTokens;

  /// CSS 가 지정했지만 미리보기가 반영하지 못하는 폰트.
  ///
  /// 생성기는 Google Font 를 받아 `fontFamily` 로 굽지만, 미리보기는 런타임에
  /// 폰트를 내려받지 않는다. 생성된 앱과 글꼴이 다를 수 있다는 뜻이다.
  final String? unsupportedFont;

  /// **읽을 수 있는지 판정하는 것은 [ThemeCss] 다.** 미리보기가 받아들인 CSS 를
  /// 생성이 거부하거나 그 반대가 되면 이 도구의 약속이 깨지므로, 규칙을 여기
  /// 한 벌 더 두지 않고 생성이 쓰는 그 타입을 그대로 거친다. 예외만 화면이
  /// 아는 종류로 갈아 끼운다.
  factory PreviewTheme.fromCss(String css) {
    final ThemeCss source;
    try {
      source = ThemeCss.parse(css);
    } on GenerationException catch (e) {
      throw PreviewThemeException(e.message);
    }

    return PreviewTheme.fromSource(source);
  }

  factory PreviewTheme.fromSource(ThemeCss source) {
    final parsed = source.parsed;

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
        tokens: parsed.light.colors,
        colors: TweakcnColors.fromMap(parsed.light.colors),
        radius: radius,
        shadows: TweakcnShadows.fromShadowMap(parsed.light.shadowLayers),
      ),
      dark: _themeFrom(
        brightness: Brightness.dark,
        tokens: parsed.dark.colors,
        colors: TweakcnColors.fromMap(parsed.dark.colors),
        radius: radius,
        shadows: TweakcnShadows.fromShadowMap(parsed.dark.shadowLayers),
      ),
      missingTokens: missing,
      // 생성기와 같은 추출기를, 생성기가 고르는 것과 같은 스택에서 쓴다.
      // **`light.fontSans` 가 아니라 `resolvedFontSans` 다** — 생성기는
      // `lightFontSans ?? darkFontSans` 를 쓰므로(라이트가 비었으면 다크),
      // 라이트만 보면 다크에만 폰트를 적은 CSS 에서 미리보기가 아무 말도 하지
      // 않은 채 생성된 앱만 그 폰트로 나온다. 규칙을 베끼지 않고 상류의 공개
      // getter 를 그대로 부르는 이유가 이것이다.
      unsupportedFont: DartThemeGenerator.extractGoogleFontNames(
        parsed.resolvedFontSans,
      ).firstOrNull,
    );
  }

  /// 생성기의 `_extensionColorTokens` 와 같은 목록이어야 한다.
  ///
  /// 사본인 이유는 그 목록이 private 이기 때문이다. 색을 만드는 데는 쓰이지
  /// 않고 — 그건 `TweakcnColors.fromMap` 이 한다 — CSS 가 정의하지 않은
  /// 토큰을 사용자에게 알리는 데만 쓴다. 그래서 낡았을 때의 증상은 잘못된
  /// 색이 아니라 잘못된 안내다.
  static const colorTokens = <String>[
    'background',
    'foreground',
    'card',
    'card-foreground',
    'popover',
    'popover-foreground',
    'primary',
    'primary-foreground',
    'secondary',
    'secondary-foreground',
    'muted',
    'muted-foreground',
    'accent',
    'accent-foreground',
    'destructive',
    'destructive-foreground',
    'border',
    'input',
    'ring',
    'chart-1',
    'chart-2',
    'chart-3',
    'chart-4',
    'chart-5',
    'sidebar',
    'sidebar-foreground',
    'sidebar-primary',
    'sidebar-primary-foreground',
    'sidebar-accent',
    'sidebar-accent-foreground',
    'sidebar-border',
    'sidebar-ring',
  ];

  static Iterable<String> _missingIn(Map<String, int> css) =>
      colorTokens.where((t) => !css.containsKey(t));

  static ThemeData _themeFrom({
    required Brightness brightness,
    required Map<String, int> tokens,
    required TweakcnColors colors,
    required TweakcnRadius radius,
    required TweakcnShadows shadows,
  }) {
    return ThemeData(
      brightness: brightness,
      colorScheme: _colorSchemeFrom(tokens, brightness: brightness),
      extensions: [colors, radius, shadows],
    );
  }

  /// 상류 `ColorSchemeResolver` 의 사본. **한 글자도 다르면 안 된다.**
  ///
  /// [TweakcnColors] 를 거치지 않고 파싱된 토큰 맵에서 직접 읽는 이유가 여기
  /// 전부다. `TweakcnColors.fromMap` 은 없는 토큰을 투명으로 만드는데, 그건
  /// **extension 에서만** 맞는 처리다. 생성기는 `ColorScheme` 을 만들 때
  /// `ColorSchemeResolver` 를 거쳐 파생 fallback 을 넣는다. 투명을 그대로
  /// 넘기면 토큰이 빠진 CSS 에서 미리보기와 생성 결과가 갈린다.
  ///
  /// 두 갈래가 있고 둘 다 따라간다:
  ///
  /// - **필수 8개** — 없으면 파생 fallback. `ColorScheme` 이 required 로
  ///   요구하므로 생략할 수 없다.
  /// - **optional 5개** — CSS 가 정의했을 때만 싣는다. 생성기가 그때만 쓰므로,
  ///   여기서 투명이든 무엇이든 채워 넣으면 Flutter 기본값을 쓰는 생성 결과와
  ///   갈린다. `copyWith` 에 null 을 주는 것이 "생략" 에 해당한다.
  static ColorScheme _colorSchemeFrom(
    Map<String, int> tokens, {
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    int resolve(String token, int Function() fallback) =>
        tokens[token] ?? fallback();

    // on 색은 자기 바탕색 지역변수에서 파생시킨다 — 생성기와 같은 순서다.
    final surface = resolve(
      'background',
      () => isDark ? _baselineDarkSurface : _white,
    );
    final onSurface = resolve('foreground', () => _contrastingColor(surface));
    final primary = resolve(
      'primary',
      () => isDark ? _baselineDarkPrimary : _baselineLightPrimary,
    );
    final onPrimary = resolve(
      'primary-foreground',
      () => _contrastingColor(primary),
    );
    // secondary 가 없는 테마는 Material 의 무관한 teal 보다 자기 primary 를
    // 재사용하는 편이 낫다는 것이 생성기의 판단이다.
    final secondary = resolve('secondary', () => primary);
    final onSecondary = resolve(
      'secondary-foreground',
      () => _contrastingColor(secondary),
    );
    final error = resolve(
      'destructive',
      () => isDark ? _baselineDarkError : _baselineLightError,
    );
    final onError = resolve(
      'destructive-foreground',
      () => _contrastingColor(error),
    );

    Color? optional(String token) {
      final value = tokens[token];
      return value == null ? null : Color(value);
    }

    return ColorScheme(
      brightness: brightness,
      surface: Color(surface),
      onSurface: Color(onSurface),
      primary: Color(primary),
      onPrimary: Color(onPrimary),
      secondary: Color(secondary),
      onSecondary: Color(onSecondary),
      error: Color(error),
      onError: Color(onError),
    ).copyWith(
      // outlineVariant 는 border 가 아니라 input, surfaceContainerLowest 는
      // background 가 아니라 card 다. 템플릿 CSS 는 두 쌍이 같은 값이라
      // 틀려도 티가 나지 않는다.
      outline: optional('border'),
      outlineVariant: optional('input'),
      surfaceContainerLowest: optional('card'),
      surfaceContainerHighest: optional('muted'),
      onSurfaceVariant: optional('muted-foreground'),
    );
  }

  static const _white = 0xFFFFFFFF;
  static const _black = 0xFF000000;

  // 테마에서 파생시킬 것이 아무것도 없을 때만 쓰는 Material 자체 기준값.
  // ColorScheme.light() / ColorScheme.dark() 와 같다.
  static const _baselineLightPrimary = 0xFF6200EE;
  static const _baselineDarkPrimary = 0xFFBB86FC;
  static const _baselineLightError = 0xFFB00020;
  static const _baselineDarkError = 0xFFCF6679;
  static const _baselineDarkSurface = 0xFF121212;

  /// 바탕색 위에서 더 잘 읽히는 쪽 — 불투명 검정 또는 흰색.
  ///
  /// 검정과 흰색의 대비가 같아지는 WCAG 상대 휘도 교차점을 쓴다.
  static int _contrastingColor(int background) =>
      _relativeLuminance(background) > 0.179 ? _black : _white;

  /// ARGB 색의 WCAG 2.x 상대 휘도. 알파는 무시한다.
  static double _relativeLuminance(int argb) {
    double linearize(int channel) {
      final s = channel / 255;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * linearize((argb >> 16) & 0xFF) +
        0.7152 * linearize((argb >> 8) & 0xFF) +
        0.0722 * linearize(argb & 0xFF);
  }
}
