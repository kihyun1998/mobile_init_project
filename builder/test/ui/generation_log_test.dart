import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/ui/generation_log.dart';

void main() {
  test('들어온 줄을 순서대로 담는다', () {
    final log = GenerationLog()
      ..add('첫줄')
      ..add('둘째줄');

    expect(log.lines, ['첫줄', '둘째줄']);
    expect(log.isEmpty, isFalse);
  });

  test('상한을 넘으면 오래된 줄부터 버린다', () {
    // build_runner 는 처음 돌 때 수천 줄을 뱉는다. 전부 들고 있으면
    // 화면이 버벅이고, 위쪽은 어차피 아무도 안 본다.
    final log = GenerationLog();
    for (var i = 0; i < GenerationLog.maxLines + 200; i++) {
      log.add('line $i');
    }

    expect(log.lines, hasLength(GenerationLog.maxLines));
    expect(log.lines.last, 'line ${GenerationLog.maxLines + 199}');
    expect(log.lines.first, isNot('line 0'));
  });

  test('줄이 들어올 때마다 듣는 쪽에 알린다', () {
    var notified = 0;
    final log = GenerationLog()..addListener(() => notified++);

    log.add('한 줄');
    expect(notified, 1);
  });

  test('비어 있을 때 지우면 헛되이 알리지 않는다', () {
    var notified = 0;
    final log = GenerationLog()..addListener(() => notified++);

    log.clear();
    expect(notified, 0);

    // 내용이 있을 때만 알린다: add 한 번 + clear 한 번.
    log.add('한 줄');
    log.clear();
    expect(log.isEmpty, isTrue);
    expect(notified, 2);
  });
}
