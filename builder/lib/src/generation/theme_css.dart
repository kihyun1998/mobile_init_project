import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';

import 'generation_exception.dart';

/// 결과물의 테마 소스가 될 tweakcn CSS.
///
/// 값 타입인 이유는 이름·org 와 같다 — 읽을 수 없는 CSS 로는 [GenerationConfig]
/// 가 만들어지지조차 않게 하려는 것이다.
///
/// **읽을 수 있는지 판정하는 규칙은 여기 한 벌뿐이어야 한다.** 미리보기가
/// 받아들인 CSS 를 생성이 거부하거나 그 반대가 되는 순간, 이 도구가 파는 유일한
/// 약속("미리보기에서 본 것이 그대로 나온다")이 깨진다. 그래서 미리보기도
/// `PreviewTheme.fromCss` 를 통해 이 타입을 거친다. 규칙을 한 벌 더 두면 그
/// 갈라짐은 조용하다 — 어느 쪽도 컴파일 에러를 내지 않는다.
///
/// [value] 는 사용자가 붙여넣은 **원문 그대로**다. 결과물의 `tweakcn.css` 로
/// 그대로 쓰이고 생성기 CLI 가 그 파일을 다시 읽으므로, 여기서 정규화하면
/// 미리보기가 파싱한 것과 다른 것이 생성기로 간다.
class ThemeCss {
  const ThemeCss._(this.value, this.parsed);

  /// 붙여넣은 원문.
  final String value;

  /// 파싱 결과. 미리보기가 이걸 테마로 옮긴다.
  final TweakcnThemeData parsed;

  /// 읽을 수 없으면 [GenerationException] 을 던진다.
  factory ThemeCss.parse(String raw) {
    if (raw.trim().isEmpty) {
      throw const GenerationException('CSS 가 비어 있습니다.');
    }

    final TweakcnThemeData parsed;
    try {
      parsed = CssParser.parse(raw);
    } catch (e) {
      throw GenerationException('CSS 를 읽지 못했습니다: $e');
    }

    // 파서는 tweakcn 이 아닌 CSS 에 대해 던지지 않고 조용히 빈 결과를 준다.
    // 그대로 통과시키면 색이 하나도 없는 테마가 생성된다.
    if (parsed.light.colors.isEmpty && parsed.dark.colors.isEmpty) {
      throw const GenerationException(
        '색 토큰을 하나도 찾지 못했습니다. '
        'tweakcn 에서 복사한 :root { --background: ... } 형태가 맞는지 보세요.',
      );
    }

    return ThemeCss._(raw, parsed);
  }

  /// 비어 있으면 null — 붙여넣지 않았다는 뜻이고, 템플릿 기본 테마를 쓴다.
  ///
  /// 빈 값은 오류가 아니다. 그래서 [parse] 와 갈라둔다 — 미리보기의 "지우면
  /// 기본 테마로 돌아간다" 와 생성의 "안 붙여넣으면 템플릿 것을 쓴다" 가 같은
  /// 판정을 쓰게 된다.
  static ThemeCss? parseOrNull(String raw) =>
      raw.trim().isEmpty ? null : ThemeCss.parse(raw);
}
