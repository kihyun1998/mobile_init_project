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
/// 둘 다 `^0.4.0` 이라 0.5.x 가 나오면 갈릴 수 있다. 갈리면 파서·색 파생·폰트
/// 추출이 서로 다른 규칙을 쓰게 되고, 그건 정확히 `preview_theme.dart` 가
/// 사본으로 들고 있는 부분이다.
///
/// **`preview_colorscheme_parity_test.dart` 는 이걸 구조적으로 못 본다.** 그
/// 테스트는 빌더가 해석한 버전의 생성기를 돌려 빌더의 미리보기와 대조하므로,
/// 양쪽이 같은 버전인 한 언제나 초록이다. 비교 대상이 둘 다 "빌더 쪽" 이다.
///
/// 그래서 여기서는 코드가 아니라 **두 `pubspec.lock`** 을 본다. 조용히 갈릴
/// 것을 시끄럽게 깨지게 만드는 것이 목적이다.
void main() {
  const package = 'flutter_tweakcn_generator';

  /// `pubspec.lock` 에서 [package] 가 실제로 해석된 버전.
  ///
  /// 줄바꿈을 정규식에 박지 않는다. `.gitattributes` 가 `* text=auto` 라
  /// Windows 체크아웃은 CRLF 이고, `\n` 을 박은 패턴은 거기서 조용히 아무것도
  /// 못 찾는다.
  String? resolvedVersion(String lockPath) {
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

  test('빌더와 템플릿이 같은 버전의 생성기를 해석한다', () {
    final builder = resolvedVersion('pubspec.lock');
    final template = resolvedVersion(p.join('..', 'template', 'pubspec.lock'));

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
          '파서·색 파생·폰트 추출 규칙이 갈리면 미리보기가 거짓말을 시작한다. '
          '양쪽 pubspec.yaml 의 제약을 맞추고 pub get 을 다시 돌릴 것.',
    );
  });
}
