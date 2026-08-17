import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 미리보기와 생성 결과가 **같은 생성기**를 쓰는지 본다.
///
/// 이 저장소의 모든 패리티 장치는 "미리보기가 거짓말하지 않는다" 하나를 지키는데,
/// 그것들이 전부 덮지 못하는 구멍이 하나 있다 — **버전이 갈리는 것.**
///
/// - 미리보기는 `builder/` 가 문 `flutter_tweakcn_generator` 로 CSS 를 파싱하고
///   색을 파생시킨다. 그 버전은 빌더를 빌드할 때 굳는다.
/// - 생성된 프로젝트는 자기 `flutter pub get` 으로 해석한 버전의 CLI 로 테마를
///   만든다. 그 시점은 **생성하는 순간**이다.
///
/// 둘 다 caret 제약이라 한쪽만 `pub upgrade` 를 맞으면 갈릴 수 있다. 갈리면
/// 파서·색 파생·폰트 추출이 서로 다른 규칙을 쓰게 되고, 그건 정확히
/// `preview_theme.dart` 가 사본으로 들고 있는 부분이다.
///
/// 0.4.0 → 0.5.0 때 실제로 밟은 절차가 그것이다 — 양쪽 `pubspec.yaml` 을 같이
/// 올리고 양쪽 `pub get` 을 돌려야 두 lock 이 같은 값이 된다.
///
/// 한쪽만 올린 상태를 실제로 만들어 재봤다: `template/pubspec.lock` 만
/// `0.4.0` 으로 되돌리면 이 테스트가 빨개지고, 실패 문구가 "미리보기는 0.5.0
/// 로 그리고 생성된 앱은 0.4.0 로 만들어진다" 로 어느 쪽이 어느 버전인지까지
/// 짚어준다. 그때 색 파생 규칙은 마침 안 바뀌었지만, 그건 운이지 이 테스트가
/// 보증한 것이 아니다.
///
/// **`preview_colorscheme_parity_test.dart` 는 이걸 구조적으로 못 본다.** 그
/// 테스트는 빌더가 해석한 버전의 생성기를 돌려 빌더의 미리보기와 대조하므로,
/// 양쪽이 같은 버전인 한 언제나 초록이다. 비교 대상이 둘 다 "빌더 쪽" 이다.
///
/// 그래서 여기서는 코드가 아니라 **두 `pubspec.lock`** 을 본다. 조용히 갈릴
/// 것을 시끄럽게 깨지게 만드는 것이 목적이다.
///
/// **생성기 하나만 보다가 넓혔다 (2026-08-17).** `flutter_dropdown_button` 을
/// `^4.2.0` 으로 올렸을 때 `template/pubspec.lock` 만 움직이고
/// `builder/pubspec.lock` 은 4.1.0 에 남았다. 그 상태에서 `template` 테스트는
/// 새 시맨틱으로 초록이었고 **빌더 미리보기는 옛 시맨틱으로 렌더하고 있었다** —
/// 정확히 이 테스트가 막으려는 모양인데, 패키지 이름이 하나로 박혀 있어서
/// 아무것도 안 잡았다. 사람이 눈으로 보고 찾았다.
///
/// 그래서 **미리보기가 그리는 것을 좌우하는 패키지 전부**를 본다. 판정 기준은
/// "버전이 갈리면 미리보기와 생성 결과가 달라지는가" 다.
void main() {
  /// 버전이 갈리면 미리보기가 거짓말하는 패키지들. 값은 갈렸을 때 무엇이
  /// 달라지는지 — 실패 문구에 그대로 실린다.
  const packages = <String, String>{
    'flutter_tweakcn_generator':
        '파서·색 파생·폰트 추출 규칙이 갈린다. '
        'preview_theme.dart 가 사본으로 들고 있는 바로 그 부분이다',
    'flutter_checkbox': '체크박스의 시맨틱과 그림자 슬롯이 갈린다',
    'flutter_dropdown_button': 'select 트리거와 메뉴 행의 시맨틱이 갈린다',
  };

  /// `pubspec.lock` 에서 [package] 가 실제로 해석된 버전.
  ///
  /// 줄바꿈을 정규식에 박지 않는다. `.gitattributes` 가 `* text=auto` 라
  /// Windows 체크아웃은 CRLF 이고, `\n` 을 박은 패턴은 거기서 조용히 아무것도
  /// 못 찾는다.
  String? resolvedVersion(String lockPath, String package) {
    final lines = File(lockPath).readAsStringSync().split(RegExp(r'\r?\n'));

    final header = lines.indexWhere((l) => l.trimRight() == '  $package:');
    if (header < 0) return null;

    for (final line in lines.skip(header + 1)) {
      // 들여쓰기가 얕아지면 이 패키지 블록이 끝난 것이다.
      if (!line.startsWith('    ')) break;
      final match = RegExp(r'^\s+version:\s*"?([^"\s]+)"?').firstMatch(line);
      if (match != null) return match.group(1);
    }
    return null;
  }

  for (final entry in packages.entries) {
    final package = entry.key;
    final whatDiverges = entry.value;

    test('빌더와 템플릿이 같은 버전의 $package 를 해석한다', () {
      final builder = resolvedVersion('pubspec.lock', package);
      final template = resolvedVersion(
        p.join('..', 'template', 'pubspec.lock'),
        package,
      );

      expect(
        builder,
        isNotNull,
        reason: 'builder/pubspec.lock 에서 $package 를 못 찾았다',
      );
      expect(
        template,
        isNotNull,
        reason: 'template/pubspec.lock 에서 $package 를 못 찾았다',
      );

      expect(
        builder,
        template,
        reason:
            '미리보기는 $builder 로 그리고 생성된 앱은 $template 로 만들어진다. '
            '$whatDiverges. '
            '양쪽 pubspec.yaml 의 제약을 맞추고 pub get 을 다시 돌릴 것.',
      );
    });
  }
}
