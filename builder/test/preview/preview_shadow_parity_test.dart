import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';
import 'package:mobile_init_builder/src/preview/preview_theme.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

/// 붙여넣은 CSS 의 `--shadow-*` 가 미리보기와 생성 결과에서 **같게** 도달하는지
/// 본다 (#25 의 수용 기준).
///
/// 왜 필요한가: #25 이전에는 양쪽이 사이좋게 **똑같이 무시**하고 있었다. 카드와
/// 스위치가 손으로 고른 검정을 그렸고 어떤 토큰과도 대응하지 않았는데, 양쪽이
/// 같은 파일을 컴파일하므로 패리티는 초록이었다. 즉 "미리보기 = 생성 결과" 만
/// 재는 것으로는 이 결함이 안 잡혔다. 여기서는 그것과 다른 것을 잰다 —
/// **붙여넣은 값이 실제로 실렸는가.**
///
/// `preview_colorscheme_parity_test.dart` 와 같은 방식으로 **진짜 생성기를
/// 돌려** 나온 리터럴을 기대값으로 쓴다. 기대값을 손으로 적으면 사본이 둘이
/// 되어 상류가 파싱 규칙을 바꿀 때 사이좋게 같이 틀린다.

/// 생성기가 실제로 뱉은 `static const light = TweakcnShadows(...)` 블록에서
/// [level] 단계의 `BoxShadow` 들을 뽑는다.
List<BoxShadow> _generatedLevel(
  String css, {
  required String mode,
  required String level,
}) {
  final source = DartThemeGenerator(
    CssParser.parse(css),
    fontMode: 'local',
  ).generate();

  final block = RegExp(
    'static const $mode = TweakcnShadows\\((.*?)\\n  \\);',
    dotAll: true,
  ).firstMatch(source);

  expect(
    block,
    isNotNull,
    reason: '생성기 출력에서 $mode TweakcnShadows 를 찾지 못했다. 출력 형태가 바뀌었을 수 있다.',
  );

  // `shadowSm: [ ... ],` 한 단계. 다음 단계 이름이 나오기 전까지.
  final levelBlock = RegExp(
    '$level: \\[(.*?)\\n    \\],',
    dotAll: true,
  ).firstMatch(block!.group(1)!);

  if (levelBlock == null) return const [];

  return [
    for (final m in RegExp(
      r'offset: Offset\(([-\d.]+), ([-\d.]+)\),\s*'
      r'blurRadius: ([-\d.]+),\s*'
      r'spreadRadius: ([-\d.]+),\s*'
      r'color: Color\((0x[0-9A-Fa-f]{8})\)',
      dotAll: true,
    ).allMatches(levelBlock.group(1)!))
      BoxShadow(
        offset: Offset(double.parse(m.group(1)!), double.parse(m.group(2)!)),
        blurRadius: double.parse(m.group(3)!),
        spreadRadius: double.parse(m.group(4)!),
        color: Color(int.parse(m.group(5)!)),
      ),
  ];
}

List<BoxShadow> _previewLevel(
  String css, {
  required String mode,
  required List<BoxShadow> Function(TweakcnShadows) pick,
}) {
  final theme = PreviewTheme.fromCss(css);
  final data = mode == 'light' ? theme.light : theme.dark;
  return pick(data.extension<TweakcnShadows>()!);
}

/// light 와 dark 가 **서로 다른** 그림자를 갖고, 단계끼리도 값이 다른 CSS.
///
/// 템플릿 CSS 로는 이걸 잴 수 없다 — 거기서는 `--shadow-sm` 과 `--shadow` 가
/// 같고 light 와 dark 도 같아서, 단계를 뒤바꾸거나 모드를 뒤바꿔도 통과한다.
/// 자기 자신을 오독할 수 있는 측정을 피하는 것이 이 상수의 존재 이유다.
/// 색 토큰이 하나도 없으면 `ThemeCss.parse` 가 거부한다 (그게 그 타입의 일이다).
/// 그림자를 재는 CSS 여도 최소한의 색은 들고 있어야 한다.
const _distinctCss = '''
:root {
  --foreground: #111111;
  --shadow-xs: 0 1px 2px 0px hsl(0 0% 0% / 0.05);
  --shadow-sm: 0 2px 4px -1px hsl(0 0% 0% / 0.10), 0 3px 6px 0px hsl(0 0% 0% / 0.20);
  --shadow-md: 0 4px 8px 0px hsl(0 0% 0% / 0.30);
}
.dark {
  --shadow-xs: 0 9px 18px 0px hsl(0 0% 0% / 0.55);
  --shadow-sm: 0 10px 20px -2px hsl(0 0% 0% / 0.60);
  --shadow-md: 0 11px 22px 0px hsl(0 0% 0% / 0.65);
}
''';

/// 그림자 토큰이 **하나도 없는** CSS. 생성기는 이때 각 단계를 빈 리스트로
/// 만들고, 미리보기도 그래야 한다 — "변하든 안 변하든 같게" 의 뒤쪽 절반이다.
const _noShadowCss = '''
:root {
  --foreground: #111111;
}
''';

void main() {
  group('붙여넣은 그림자가 미리보기와 생성 결과에 같게 실린다', () {
    for (final (mode, pick)
        in <(String, List<BoxShadow> Function(TweakcnShadows))>[
          ('light', (s) => s.shadowSm),
          ('dark', (s) => s.shadowSm),
        ]) {
      test('$mode 의 shadow-sm 이 같다 — 겹이 둘이어도', () {
        // light 만 재면 안 된다. 두 모드에 다른 값을 넣은 CSS 라, 모드를
        // 뒤바꾸는 실수가 여기서만 드러난다.
        expect(
          _previewLevel(_distinctCss, mode: mode, pick: pick),
          _generatedLevel(_distinctCss, mode: mode, level: 'shadowSm'),
        );
      });
    }

    test('단계끼리 섞이지 않는다', () {
      // 세 단계가 서로 다른 값이므로, 한 단계를 다른 단계로 잘못 읽으면
      // 여기가 빨개진다.
      final shadows = PreviewTheme.fromCss(
        _distinctCss,
      ).light.extension<TweakcnShadows>()!;

      expect(
        shadows.shadowXs,
        _generatedLevel(_distinctCss, mode: 'light', level: 'shadowXs'),
      );
      expect(
        shadows.shadowMd,
        _generatedLevel(_distinctCss, mode: 'light', level: 'shadowMd'),
      );
      expect(shadows.shadowXs, isNot(shadows.shadowSm));
      expect(shadows.shadowSm, isNot(shadows.shadowMd));
    });

    test('그림자가 없는 CSS 는 양쪽 다 비운다', () {
      final shadows = PreviewTheme.fromCss(
        _noShadowCss,
      ).light.extension<TweakcnShadows>()!;

      expect(shadows.shadowSm, isEmpty);
      expect(
        shadows.shadowSm,
        _generatedLevel(_noShadowCss, mode: 'light', level: 'shadowSm'),
      );
    });
  });
}
