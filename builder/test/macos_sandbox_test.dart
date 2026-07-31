import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 빌더는 샌드박스 안에서 동작할 수 없다.
///
/// `flutter create` 는 파일 하나 못 쓰고, 템플릿 폴더도 못 읽고, 파인더도 못
/// 연다. 실제로 확인한 것: 샌드박스를 켜면 `Directory.current` 가
/// `~/Library/Containers/.../Data` 라서 `../template` 이 아예 해석되지 않고,
/// `Process.run('flutter', ...)` 도 실패한다. 끄면 둘 다 정상이다.
///
/// `flutter create` 로 macos/ 를 다시 만들면 이 키가 기본값으로 되살아난다.
/// 그때 앱은 조용히 아무것도 못 하는 상태가 되고 테스트는 전부 초록이다.
/// 그래서 여기서 본다.
void main() {
  const sandboxKey = 'com.apple.security.app-sandbox';

  for (final name in ['DebugProfile', 'Release']) {
    test('$name.entitlements 에 앱 샌드박스가 꺼져 있다', () {
      final file = File(p.join('macos', 'Runner', '$name.entitlements'));

      expect(file.existsSync(), isTrue, reason: '${file.path} 가 없다');

      // 키를 아예 빼도, 명시적으로 <false/> 로 둬도 괜찮다. 막으려는 건
      // "켜져 있는 것" 하나다.
      final enabled = RegExp(
        '<key>${RegExp.escape(sandboxKey)}</key>\\s*<true\\s*/>',
      ).hasMatch(file.readAsStringSync());

      expect(
        enabled,
        isFalse,
        reason: '샌드박스가 켜지면 flutter create 도 템플릿 읽기도 안 된다.',
      );
    });
  }
}
