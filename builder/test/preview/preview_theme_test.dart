import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/preview/preview_theme.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

/// 값이 눈에 보이도록 hex 로 쓴다. 파서는 oklch/rgb/hsl 도 받는다.
const _css = '''
:root {
  --background: #FFFFFF;
  --foreground: #111111;
  --card: #00FF00;
  --primary: #FF0000;
  --radius: 0.75rem;
}
.dark {
  --background: #000000;
  --primary: #0000FF;
}
''';

TweakcnColors _colors(ThemeData theme) => theme.extension<TweakcnColors>()!;
TweakcnRadius _radius(ThemeData theme) => theme.extension<TweakcnRadius>()!;

void main() {
  test('붙여넣은 CSS 의 색이 라이트 테마에 실린다', () {
    final themes = PreviewTheme.fromCss(_css);

    expect(_colors(themes.light).primary, const Color(0xFFFF0000));
    expect(_colors(themes.light).card, const Color(0xFF00FF00));
    expect(_colors(themes.light).background, const Color(0xFFFFFFFF));
  });

  test('.dark 블록은 다크 테마에 실린다', () {
    final themes = PreviewTheme.fromCss(_css);

    expect(_colors(themes.dark).primary, const Color(0xFF0000FF));
    expect(_colors(themes.dark).background, const Color(0xFF000000));
  });

  test('CSS 에 없는 토큰은 extension 에서 생성기와 같이 투명이다', () {
    // 템플릿 색으로 채우면 미리보기만 멀쩡하고 생성된 앱은 투명해진다.
    // 예쁘게 보이는 것보다 같게 보이는 것이 중요하다.
    //
    // ColorScheme 은 규칙이 다르다 — 생성기가 파생 fallback 을 넣으므로
    // 미리보기도 그렇게 한다. preview_colorscheme_parity_test.dart 참고.
    final themes = PreviewTheme.fromCss(_css);

    expect(_colors(themes.light).secondary, const Color(0x00000000));
    expect(_colors(themes.light).ring, const Color(0x00000000));
    expect(
      _colors(themes.light).secondary,
      isNot(TweakcnColors.light.secondary),
    );
  });

  test('빠진 토큰이 무엇인지 알려준다', () {
    final themes = PreviewTheme.fromCss(_css);

    expect(themes.missingTokens, contains('secondary'));
    expect(themes.missingTokens, contains('ring'));
    expect(themes.missingTokens, isNot(contains('primary')));
  });

  test('토큰이 전부 있으면 빠진 것이 없다고 한다', () {
    final full = File('../template/tweakcn.css').readAsStringSync();

    expect(PreviewTheme.fromCss(full).missingTokens, isEmpty);
  });

  test('--radius 에서 sm/md/lg/xl 을 생성기와 같은 공식으로 만든다', () {
    // 생성기 규칙: lg = radius, md = radius-2, sm = radius-4, xl = radius+4
    // 0.75rem = 12px
    final radius = _radius(PreviewTheme.fromCss(_css).light);

    expect(radius.lg, 12.0);
    expect(radius.md, 10.0);
    expect(radius.sm, 8.0);
    expect(radius.xl, 16.0);
  });

  test('--radius 가 없으면 생성기와 같은 기본값 8.0 을 쓴다', () {
    // 템플릿의 TweakcnRadius.standard(10 기준)가 아니다. 생성기는 CSS 에
    // radius 가 없으면 8.0 을 쓰므로 미리보기도 그래야 한다.
    final radius = _radius(
      PreviewTheme.fromCss(':root { --primary: #FF0000; }').light,
    );

    expect(radius.lg, 8.0);
    expect(radius.md, 6.0);
    expect(radius.sm, 4.0);
    expect(radius.xl, 12.0);
    expect(radius.lg, isNot(TweakcnRadius.standard.lg));
  });

  test(
    'ColorScheme 은 생성기 매핑을 따른다 (input→outlineVariant, card→surfaceContainerLowest)',
    () {
      // 템플릿 CSS 는 border==input, card==background 라 틀려도 티가 안 난다.
      // 일부러 값을 다르게 준 CSS 로 고정한다.
      final theme = PreviewTheme.fromCss('''
:root {
  --border: #111111;
  --input: #222222;
  --background: #333333;
  --card: #444444;
  --muted: #555555;
}
''').light;

      expect(theme.colorScheme.outline, const Color(0xFF111111));
      expect(theme.colorScheme.outlineVariant, const Color(0xFF222222));
      expect(theme.colorScheme.surface, const Color(0xFF333333));
      expect(theme.colorScheme.surfaceContainerLowest, const Color(0xFF444444));
      expect(
        theme.colorScheme.surfaceContainerHighest,
        const Color(0xFF555555),
      );
    },
  );

  test('미리보기가 반영 못 하는 폰트를 알려준다', () {
    final themes = PreviewTheme.fromCss(
      ":root { --primary: #FF0000; --font-sans: 'Inter', sans-serif; }",
    );

    expect(themes.unsupportedFont, 'Inter');
  });

  /// 생성기는 `resolvedFontSans` = `lightFontSans ?? darkFontSans` 를 쓴다.
  /// 미리보기가 라이트만 보면, 다크에만 폰트를 적은 CSS 에서 **아무 말도 하지
  /// 않은 채** 생성된 앱만 그 폰트로 나온다. 안내가 없는 것이 곧 거짓말이다.
  test('다크에만 적은 폰트도 알려준다 — 생성기가 그것을 쓰기 때문이다', () {
    final themes = PreviewTheme.fromCss(
      ":root { --primary: #FF0000; } "
      ".dark { --primary: #0000FF; --font-sans: 'Inter', sans-serif; }",
    );

    expect(themes.unsupportedFont, 'Inter');
  });

  /// 라이트가 값 없이 선언했으면(`--font-sans: ;`) 생성기는 그것을 "선언하지
  /// 않았다" 로 보고 다크로 넘어간다.
  test('라이트가 빈 값이면 다크 것을 쓴다', () {
    final themes = PreviewTheme.fromCss(
      ':root { --primary: #FF0000; --font-sans: ; } '
      ".dark { --font-sans: 'Roboto', sans-serif; }",
    );

    expect(themes.unsupportedFont, 'Roboto');
  });

  test('ColorScheme 에도 같은 색이 실려서 Material 위젯이 따라온다', () {
    final theme = PreviewTheme.fromCss(_css).light;

    expect(theme.colorScheme.primary, const Color(0xFFFF0000));
    expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(theme.brightness, Brightness.light);
  });

  group('잘못된 입력', () {
    test('빈 CSS 는 무엇이 문제인지 말해준다', () {
      expect(
        () => PreviewTheme.fromCss('   '),
        throwsA(
          isA<PreviewThemeException>().having(
            (e) => e.message,
            'message',
            contains('비어'),
          ),
        ),
      );
    });

    test('색 토큰이 하나도 없으면 거부한다', () {
      expect(
        () => PreviewTheme.fromCss('body { color: red; }'),
        throwsA(isA<PreviewThemeException>()),
      );
    });

    test('파서가 터져도 예외로 감싸서 앱을 죽이지 않는다', () {
      // 중괄호가 안 맞는 등 무엇이 들어와도 PreviewThemeException 만 나온다.
      expect(
        () => PreviewTheme.fromCss(':root { --primary: '),
        throwsA(isA<PreviewThemeException>()),
      );
    });
  });
}
