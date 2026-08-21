import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// `CLAUDE.md` 가 적은 컴포넌트 개수를 실제 파일 수에 묶는다.
///
/// **이 테스트가 있는 이유는 그 숫자를 검사할 방법이 없었기 때문이다** (#49).
/// `project_generator.dart` 의 `emptyHomeScreenSource` 안에 "shadcn 13종" 이
/// 적혀 있었고 — 그 문장은 예제를 끈 **모든 생성물의 `home_screen.dart` 로
/// 나간다** — 지금은 어느 단위로도 13이 아니다.
///
/// **그 13이 원래 무엇을 세었는지는 확정할 수 없다.** `03e43d1`(#6) 시점에
/// `shadcn_*.dart` 는 12개, 디렉토리 전체 파일은 13개(shadcn 12 +
/// `app_bottom_nav_bar.dart`), 공개 위젯 클래스는 14개였다. 그중 스위치의
/// 라벨 변형을 빼면 **13종**이 되므로 "종" 이라는 단어와도 맞는다. 즉 쓰인 날
/// 맞았다가 드리프트한 것일 수도, 처음부터 다른 것을 센 것일 수도 있다.
/// **저자에게 물어볼 수 없으므로 원인을 단정하지 않는다** — 확실한 것은
/// 단위가 어디에도 안 적혀 있어서 **아무도 그 숫자를 검사할 수 없었다**는 것,
/// 그리고 그 결과가 사용자 프로젝트로 나갔다는 것이다.
///
/// 그래서 두 가지를 했다. 생성물로 나가는 문장에서는 **숫자를 뺐고**, 남긴
/// 한 자리(`CLAUDE.md`)에는 이 테스트를 붙였다. **검사할 수 없는 숫자는
/// 문장에 박지 않는다** — 같은 규칙을 `gates.yml` 에도 적용했다(#51).
///
/// **`builder/test/` 에 두는 것이 중요하다.** `copyEntries` 가 `template/test`
/// 를 통째로 복사하므로 template 쪽에 두면 이 테스트가 **생성된 프로젝트로
/// 실려 나가고**, 사용자가 자기 컴포넌트를 하나 더하는 순간 자기 저장소에서
/// 빨개진다. 여기서 지키는 것은 결과물의 성질이 아니라 **우리 문서가 우리
/// 코드와 맞는가** 이므로 빌더 쪽이 맞다. `project_generator_test.dart` 가
/// 진짜 `../template` 을 여는 것과 같은 자리다 (`template_link_test.dart` 는
/// 디스크를 안 읽고 `path:` 의존으로 import 만 한다 — 전례가 아니다).
///
/// **`../CLAUDE.md` 를 읽는 것은 이 저장소에서 처음이다.** 기존 `..` 참조는
/// 전부 `../template` 이었다. 게이트는 양쪽 다 `working-directory: builder`
/// 라 가정이 같고, 없으면 아래 `reason` 을 달고 시끄럽게 실패한다.
void main() {
  final componentsDir = Directory(
    p.join('..', 'template', 'lib', 'ui', 'components'),
  );
  final claudeMd = File(p.join('..', 'CLAUDE.md'));

  test('CLAUDE.md 의 컴포넌트 개수가 실제 shadcn_*.dart 파일 수와 같다', () {
    expect(
      componentsDir.existsSync(),
      isTrue,
      reason: '${componentsDir.path} 가 없다. 저장소 루트에서 cd builder 로 돌리고 있나?',
    );
    expect(claudeMd.existsSync(), isTrue, reason: '${claudeMd.path} 가 없다.');

    final actual = componentsDir
        .listSync()
        .whereType<File>()
        .map((f) => p.basename(f.path))
        .where((n) => n.startsWith('shadcn_') && n.endsWith('.dart'))
        .length;

    // `shadcn_*.dart` **15개** 처럼 적힌 자리에서 숫자만 뽑는다. 문장을 다시
    // 써도 이 모양만 지키면 계속 걸린다.
    final match = RegExp(
      r'`shadcn_\*\.dart`\s*\*\*(\d+)\s*개?\*\*',
    ).firstMatch(claudeMd.readAsStringSync());

    expect(
      match,
      isNotNull,
      reason:
          'CLAUDE.md 에서 개수를 못 찾았다. '
          '`shadcn_*.dart` **N개** 모양을 유지하거나 이 테스트의 패턴을 같이 고칠 것.',
    );

    expect(
      int.parse(match!.group(1)!),
      actual,
      reason:
          'CLAUDE.md 가 적은 개수와 실제 파일 수가 다르다. '
          '컴포넌트를 더했으면 CLAUDE.md 도 같이 고친다.',
    );
  });

  test('app_bottom_nav_bar.dart 는 이 개수에 안 들어간다', () {
    // 단위가 "디렉토리의 파일" 이 아니라 "`shadcn_*.dart` 파일" 이라는 것을
    // 못박는다. 디렉토리를 통째로 세면 shadcn 이 아닌 것이 하나 섞이는데,
    // `CLAUDE.md` 가 그 파일을 두고 "shadcn 컴포넌트가 아니다" 라고 적는다.
    // 두 값이 하나 차이라 눈으로는 구별되지 않는다.
    final all = componentsDir
        .listSync()
        .whereType<File>()
        .map((f) => p.basename(f.path))
        .where((n) => n.endsWith('.dart'))
        .toList();
    final shadcn = all.where((n) => n.startsWith('shadcn_')).toList();

    expect(all, contains('app_bottom_nav_bar.dart'));
    expect(shadcn, isNot(contains('app_bottom_nav_bar.dart')));
    expect(
      all.length,
      greaterThan(shadcn.length),
      reason: '디렉토리 전체와 shadcn_*.dart 수가 같아지면 이 테스트가 아무것도 안 지킨다.',
    );
  });

  test('생성물로 나가는 홈 화면 문장에는 개수가 없다', () {
    // 사용자가 실제로 읽는 유일한 자리다. 예제를 끄면 이 문자열이 결과물의
    // `home_screen.dart` 로 그대로 찍힌다. 숫자가 돌아오면 여기서 잡는다.
    final source = File(
      p.join('lib', 'src', 'generation', 'project_generator.dart'),
    ).readAsStringSync();

    final start = source.indexOf('static const emptyHomeScreenSource');
    expect(start, greaterThan(-1), reason: 'emptyHomeScreenSource 를 못 찾았다.');
    final end = source.indexOf("''';", start);
    expect(end, greaterThan(start));

    final body = source.substring(start, end);

    // **표현을 열거하지 않고 숫자 자체를 막는다.** 처음에는
    // `shadcn N종|컴포넌트 N개` 로 썼는데, 조사 하나만 달라도
    // (`컴포넌트가 15개`) 또는 어순만 바꿔도 (`15개의 shadcn 컴포넌트`)
    // 조용히 통과했다 — 결함을 되살린 변이가 3/3 초록으로 지나갔다.
    // 이 리터럴에는 지금 숫자가 **한 글자도 없으므로** 이 어서션이 정확하다.
    expect(
      RegExp(r'\d').hasMatch(body),
      isFalse,
      reason:
          '생성물로 나가는 문장에 숫자가 들어왔다. 이 문자열은 예제를 끈 모든 '
          '프로젝트의 home_screen.dart 로 나가는데 아무 게이트도 그 값을 '
          '검사하지 않는다 — 그래서 숫자를 적지 않는다 (#49).',
    );
  });
}
