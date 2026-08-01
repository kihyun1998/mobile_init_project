import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/generation_exception.dart';
import 'package:mobile_init_builder/src/generation/theme_css.dart';
import 'package:mobile_init_builder/src/preview/preview_theme.dart';

void main() {
  test('원문을 한 글자도 바꾸지 않고 들고 있는다', () {
    // 결과물의 tweakcn.css 로 그대로 쓰이고, 생성기가 그 파일을 다시 읽는다.
    // 여기서 정규화하면 사용자가 붙여넣은 것과 다른 것이 생성기로 간다.
    const css = ':root {\r\n  --primary: #FF0000;\r\n}\r\n';

    expect(ThemeCss.parse(css).value, css);
  });

  test('비어 있으면 붙여넣지 않은 것으로 본다', () {
    expect(ThemeCss.parseOrNull(''), isNull);
    expect(ThemeCss.parseOrNull('   \n  '), isNull);
  });

  test('비어 있는 것을 굳이 파싱하려 하면 던진다', () {
    expect(() => ThemeCss.parse('  '), throwsA(isA<GenerationException>()));
  });

  test('색 토큰이 하나도 없으면 던진다', () {
    // tweakcn 이 아닌 것을 붙여넣은 경우다. 파서는 조용히 빈 결과를 준다.
    expect(
      () => ThemeCss.parse('body { color: red; }'),
      throwsA(isA<GenerationException>()),
    );
  });

  test('색 토큰이 하나라도 있으면 통과한다', () {
    expect(ThemeCss.parse(':root { --primary: #FF0000; }').value, isNotEmpty);
  });

  test('.dark 블록에만 색이 있어도 통과한다', () {
    expect(ThemeCss.parse('.dark { --primary: #FF0000; }').value, isNotEmpty);
  });

  /// **이 규칙은 한 벌뿐이어야 한다.**
  ///
  /// 미리보기가 받아들인 CSS 를 생성이 거부하거나 그 반대가 되는 순간, 이
  /// 도구가 파는 유일한 약속("본 것이 그대로 나온다")이 깨진다. 규칙이 둘로
  /// 갈라지면 그 갈라짐은 조용하다 — 어느 쪽도 컴파일 에러를 내지 않는다.
  group('미리보기와 같은 규칙을 쓴다', () {
    const cases = [
      '',
      '   ',
      'body { color: red; }',
      'not css at all {{{',
      ':root { --primary: #FF0000; }',
      '.dark { --background: #000000; }',
    ];

    for (final css in cases) {
      test('"${css.trim()}" 에 대해 둘의 판정이 같다', () {
        bool accepts(void Function() f) {
          try {
            f();
            return true;
          } catch (_) {
            return false;
          }
        }

        expect(
          accepts(() => ThemeCss.parse(css)),
          accepts(() => PreviewTheme.fromCss(css)),
          reason: '생성과 미리보기가 같은 CSS 를 다르게 판정한다',
        );
      });
    }
  });
}
