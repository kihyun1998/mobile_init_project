import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';
import 'package:mobile_init_builder/src/preview/preview_theme.dart';

/// 미리보기 `ColorScheme` 이 생성기가 실제로 뱉는 것과 같은지 본다.
///
/// **기대값을 손으로 적지 않는다.** 미리보기의 `ColorScheme` 매핑은 상류
/// `ColorSchemeResolver` 의 사본이고(export 되지 않아 부를 수 없다 —
/// kihyun1998/flutter_tweakcn_generator#22), 기대값까지 손으로 적으면 사본이
/// 둘이 되어 상류가 규칙을 바꿀 때 사이좋게 같이 틀린다. 그래서 이 파일은
/// **진짜 생성기를 돌려** 나온 리터럴을 기대값으로 쓴다. 상류가 fallback 을
/// 바꾸면 이 테스트가 깨진다 — 조용히 낡는 사본을 시끄럽게 깨지는 사본으로
/// 바꾸는 것이 요점이다.

/// 생성기를 실제로 돌려 `const _<mode>ColorScheme = ColorScheme(...)` 에 실제로
/// 실린 프로퍼티만 뽑는다.
///
/// 생성기는 필수 8개를 항상 쓰고(없으면 파생 fallback), optional 5개는 CSS 가
/// 정의했을 때만 쓴다. 그래서 여기 없는 키는 "생성기가 생략했다" 는 뜻이고,
/// 생성된 앱에서는 Flutter 기본값이 적용된다.
Map<String, Color> _generatedScheme(String css, {required String mode}) {
  final source = DartThemeGenerator(
    CssParser.parse(css),
    // 템플릿 설정과 같게 둔다. 폰트 모드는 색과 무관하지만 google_fonts 를
    // 끌어오면 생성 출력이 달라져 굳이 다르게 둘 이유가 없다.
    fontMode: 'local',
  ).generate();

  final block = RegExp(
    'const _${mode}ColorScheme = ColorScheme\\((.*?)\\);',
    dotAll: true,
  ).firstMatch(source);

  expect(
    block,
    isNotNull,
    reason: '생성기 출력에서 $mode ColorScheme 을 찾지 못했다. 출력 형태가 바뀌었을 수 있다.',
  );

  return {
    for (final m in RegExp(
      r'(\w+): Color\((0x[0-9A-Fa-f]{8})\)',
    ).allMatches(block!.group(1)!))
      m.group(1)!: Color(int.parse(m.group(2)!)),
  };
}

Color _read(ColorScheme scheme, String property) => switch (property) {
  'surface' => scheme.surface,
  'onSurface' => scheme.onSurface,
  'primary' => scheme.primary,
  'onPrimary' => scheme.onPrimary,
  'secondary' => scheme.secondary,
  'onSecondary' => scheme.onSecondary,
  'error' => scheme.error,
  'onError' => scheme.onError,
  'outline' => scheme.outline,
  'outlineVariant' => scheme.outlineVariant,
  'surfaceContainerLowest' => scheme.surfaceContainerLowest,
  'surfaceContainerHighest' => scheme.surfaceContainerHighest,
  'onSurfaceVariant' => scheme.onSurfaceVariant,
  _ => throw ArgumentError('모르는 ColorScheme 프로퍼티: $property'),
};

/// 필수 토큰이 여럿 빠진 CSS. 완전한 CSS 로는 이 버그가 드러나지 않는다.
const _sparseCss = '''
:root {
  --foreground: #111111;
  --border: #222222;
}
.dark {
  --foreground: #EEEEEE;
}
''';

void main() {
  test('토큰이 빠진 CSS 에서 미리보기 ColorScheme 이 생성기와 같다', () {
    final generated = _generatedScheme(_sparseCss, mode: 'light');
    final preview = PreviewTheme.fromCss(_sparseCss).light.colorScheme;

    // 루프가 헛돌지 않는지 먼저 본다. 필수 8개는 무슨 일이 있어도 나온다.
    expect(generated.length, greaterThanOrEqualTo(8));

    for (final entry in generated.entries) {
      expect(_read(preview, entry.key), entry.value, reason: entry.key);
    }
  });

  test('다크 모드도 자기 모드의 fallback 을 따른다', () {
    final generated = _generatedScheme(_sparseCss, mode: 'dark');
    final preview = PreviewTheme.fromCss(_sparseCss).dark.colorScheme;

    expect(generated.length, greaterThanOrEqualTo(8));

    for (final entry in generated.entries) {
      expect(_read(preview, entry.key), entry.value, reason: entry.key);
    }
  });

  test('빠진 필수 토큰은 투명이 아니라 파생 fallback 이 된다', () {
    // 위의 루프는 "전부 같다" 만 말한다. 무엇이 같아졌는지를 못 박아 두지
    // 않으면, 양쪽이 나란히 투명이 되어도 초록이 나온다.
    final preview = PreviewTheme.fromCss(_sparseCss).light.colorScheme;

    expect(preview.primary, isNot(const Color(0x00000000)));
    expect(preview.surface, isNot(const Color(0x00000000)));

    // secondary 가 없으면 생성기는 Material 의 무관한 teal 대신 primary 를
    // 재사용한다. 사본이 이 규칙을 놓치면 여기서 걸린다.
    expect(preview.secondary, preview.primary);
  });

  test('생성기가 생략한 optional 프로퍼티는 Flutter 기본값이 된다', () {
    const css = ':root { --primary: #FF0000; }';
    final generated = _generatedScheme(css, mode: 'light');

    // 전제 확인 — CSS 가 --border 를 안 줬으니 생성기는 outline 을 안 쓴다.
    expect(generated.containsKey('outline'), isFalse);

    // 생성된 앱이 실제로 갖게 되는 값: 생성기가 쓴 필수 8개만으로 만든 것.
    final asGenerated = ColorScheme(
      brightness: Brightness.light,
      surface: generated['surface']!,
      onSurface: generated['onSurface']!,
      primary: generated['primary']!,
      onPrimary: generated['onPrimary']!,
      secondary: generated['secondary']!,
      onSecondary: generated['onSecondary']!,
      error: generated['error']!,
      onError: generated['onError']!,
    );

    final preview = PreviewTheme.fromCss(css).light.colorScheme;

    expect(preview.outline, asGenerated.outline);
    expect(preview.outline, isNot(const Color(0x00000000)));
  });

  test('토큰이 다 있으면 CSS 값이 그대로 실린다 (fallback 이 끼어들지 않는다)', () {
    // fallback 을 넣다가 정의된 값까지 덮어쓰는 것이 이 변경의 반대쪽 사고다.
    const css = '''
:root {
  --background: #333333;
  --foreground: #111111;
  --primary: #FF0000;
  --primary-foreground: #FFFFFF;
  --secondary: #00FF00;
  --secondary-foreground: #000000;
  --destructive: #FF00FF;
  --destructive-foreground: #FFFFFF;
  --border: #111111;
  --input: #222222;
  --card: #444444;
  --muted: #555555;
  --muted-foreground: #666666;
}
''';
    final generated = _generatedScheme(css, mode: 'light');
    final preview = PreviewTheme.fromCss(css).light.colorScheme;

    expect(generated.length, 13);
    for (final entry in generated.entries) {
      expect(_read(preview, entry.key), entry.value, reason: entry.key);
    }
    expect(preview.secondary, const Color(0xFF00FF00));
  });
}
