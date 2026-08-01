import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/process_runner.dart';
import 'package:path/path.dart' as p;

/// 여기서만 **진짜 프로세스**를 띄운다.
///
/// 나머지 테스트는 전부 가짜 러너를 쓰는데, 가짜는 출력을 동기로 뱉기 때문에
/// SystemProcessRunner 가 버퍼링 방식으로 되돌아가도 눈치채지 못한다.
/// "출력이 진행 중에 흐른다" 는 #4 의 핵심 약속이므로 여기서 못박는다.
///
/// 피실험자로 `dart` 를 쓴다. 예전에는 `sh -c` 였는데 Windows 에 `sh` 가 없어
/// 세 케이스가 통째로 skip 됐고, 하필 Windows 에서 `flutter` 가 `flutter.bat`
/// 이라 shell 을 거쳐야 하는 — 즉 가장 확인이 필요한 — 플랫폼이 사각지대로
/// 남았다. `dart` 는 Flutter SDK 안에 반드시 있으므로 양쪽에서 돈다.
void main() {
  const runner = SystemProcessRunner();

  late Directory scripts;
  late String dartPath;

  setUpAll(() {
    scripts = Directory.systemTemp.createTempSync('runner_test_');
    dartPath = _resolveDart();
  });

  tearDownAll(() => scripts.deleteSync(recursive: true));

  /// 자식으로 띄울 스크립트를 만들고 경로를 준다.
  String script(String name, String source) {
    final file = File(p.join(scripts.path, '$name.dart'))
      ..writeAsStringSync(source);
    return file.path;
  }

  test('출력이 프로세스가 끝나기 전에 흘러나온다', () async {
    // 자식은 첫 줄을 뱉고 나서 게이트 파일이 생길 때까지 기다린다. 언제
    // 끝낼지를 테스트가 쥐고 있으므로 벽시계로 잴 필요가 없다 — 첫 줄을
    // 받아야만 게이트를 열 수 있고, 게이트가 열려야만 자식이 끝난다.
    // 버퍼링이면 첫 줄이 끝날 때까지 오지 않으므로 서로를 기다리다 timeout 이
    // 터진다. 예전처럼 "700ms 안에 와야 한다" 로 재면 구현이 맞아도 느린
    // 머신에서 빨개진다.
    final gate = File(p.join(scripts.path, 'gate'));
    final path = script('streaming', '''
import 'dart:io';

Future<void> main(List<String> args) async {
  stdout.writeln('첫줄');
  await stdout.flush();
  while (!File(args.first).existsSync()) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  stdout.writeln('마지막줄');
}
''');

    final firstLine = Completer<String>();
    final pending = runner.run(
      dartPath,
      [path, gate.path],
      onOutput: (line) {
        if (line.trim().isEmpty) return;
        if (!firstLine.isCompleted) firstLine.complete(line);
      },
    );

    final line = await firstLine.future.timeout(
      _generous,
      onTimeout: () =>
          throw StateError('자식이 아직 살아 있는데 첫 줄이 오지 않았다 — 출력이 버퍼링되고 있다'),
    );
    expect(line, '첫줄');

    gate.writeAsStringSync('go');

    final result = await pending.timeout(_generous);
    expect(result.succeeded, isTrue);
    expect(result.stdout, contains('마지막줄'));
  });

  test('stdin 을 읽는 명령이 멈추지 않는다', () async {
    // Process.run 은 stdin 을 닫아주지만 start 는 안 닫는다. 안 닫으면
    // 입력을 기다리는 자식이 영원히 멈춘다.
    final path = script('reads_stdin', '''
import 'dart:io';

Future<void> main() async {
  await stdin.forEach((_) {});
}
''');

    final result = await runner
        .run(dartPath, [path])
        .timeout(
          _generous,
          onTimeout: () =>
              throw StateError('자식이 stdin 을 기다리며 멈췄다 — stdin 을 닫지 않고 있다'),
        );

    expect(result.exitCode, 0);
  });

  test('실패한 명령의 종료 코드와 stderr 를 돌려준다', () async {
    final path = script('fails', '''
import 'dart:io';

void main() {
  stderr.writeln('망했다');
  exit(3);
}
''');

    final result = await runner.run(dartPath, [path]).timeout(_generous);

    expect(result.succeeded, isFalse);
    expect(result.exitCode, 3);
    expect(result.failureOutput, contains('망했다'));
  });

  /// 자식이 **일을 다 끝내고도 끝나지 않는** 경우가 실제로 있다.
  ///
  /// 상류 `flutter_tweakcn_generator` 는 Google Fonts API 가 200 이 아니면
  /// 응답 본문을 비우지 않고 던진다(`font_downloader.dart:289-303`). 그러면
  /// CLI 는 테마 파일을 쓰고 요약까지 다 출력한 뒤 영원히 살아 있다. 실측:
  /// `--font-sans: "Segoe UI"` (Google Fonts 에 없어 400) 로 60초 넘게 안 죽었다.
  /// 정상 실행은 1초 미만이다.
  ///
  /// 벽시계 총량이 아니라 **무출력 시간**으로 자르는 이유는, build_runner 가
  /// 새 프로젝트에서 몇 분씩 도는 것이 정상이기 때문이다. 총량으로 자르면
  /// 정상적인 긴 작업을 죽이게 된다. 멈춘 자식은 출력까지 멎으므로 이쪽이
  /// 실패 모양과 정확히 맞는다.
  group('무출력 감시견', () {
    test('출력이 멎은 채 살아 있는 자식을 끊고 이유를 남긴다', () async {
      final path = script('hangs', '''
import 'dart:io';

Future<void> main() async {
  stdout.writeln('일은 다 했다');
  await stdout.flush();
  // 상류 CLI 가 미배출 응답 때문에 빠지는 상태와 같은 모양 —
  // 할 일은 끝났는데 이벤트 루프에 살아 있는 핸들이 남아 끝나지 않는다.
  await Future<void>.delayed(const Duration(days: 1));
}
''');

      final result = await const SystemProcessRunner(
        idleTimeout: Duration(seconds: 2),
      ).run(dartPath, [path]).timeout(_generous);

      expect(result.succeeded, isFalse);
      expect(result.stdout, contains('일은 다 했다'));
      expect(
        result.failureOutput,
        contains('응답이 없어'),
        reason: '왜 끊겼는지 화면에 남아야 사용자가 다음 수를 둘 수 있다',
      );
    });

    test('출력이 계속 나오는 동안에는 끊지 않는다', () async {
      // 감시견이 총 실행 시간으로 자르면 여기서 걸린다. 자식은 감시견 간격의
      // 몇 배를 살지만 그동안 꾸준히 뱉는다 — build_runner 가 하는 일이다.
      final path = script('chatty', '''
import 'dart:io';

Future<void> main() async {
  for (var i = 0; i < 8; i++) {
    stdout.writeln('진행 \$i');
    await stdout.flush();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
''');

      final result = await const SystemProcessRunner(
        idleTimeout: Duration(seconds: 2),
      ).run(dartPath, [path]).timeout(_generous);

      expect(result.succeeded, isTrue);
      expect(result.stdout, contains('진행 7'));
    });
  });

  test('실패 문구는 긴 로그를 통째로 쏟지 않는다', () {
    const result = ProcessRunResult(exitCode: 1, stdout: '', stderr: '');
    expect(result.failureOutput, isEmpty);

    final long = ProcessRunResult(
      exitCode: 1,
      stdout: List.generate(500, (i) => 'line $i').join('\n'),
      stderr: '',
    );
    expect(long.failureOutput.split('\n').length, lessThan(30));
    expect(long.failureOutput, contains('line 499'));
    expect(long.failureOutput, isNot(contains('line 0\n')));
  });
}

/// 자식은 dart VM 을 새로 띄우므로 머신에 따라 몇 초가 걸린다. 여기서 재려는
/// 것은 속도가 아니라 순서라서, 넉넉히 주고 멈춘 경우만 걸러낸다.
///
/// `flutter test` 의 기본 제한이 30초다. 그보다 크게 주면 우리 진단 문구가
/// 뜨기 전에 프레임워크가 먼저 잘라서 "Test timed out" 만 남는다 — 멈춘 이유를
/// 알려주는 것이 이 테스트의 값이므로 그 아래로 둔다.
const _generous = Duration(seconds: 15);

/// `flutter test` 안에서 `Platform.resolvedExecutable` 은 `dart` 가 아니라
/// `flutter_tester` 다. FLUTTER_ROOT 로 SDK 안의 dart 를 직접 찾고, 없으면
/// PATH 에 맡긴다.
String _resolveDart() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) {
    final candidate = p.join(
      root,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      Platform.isWindows ? 'dart.exe' : 'dart',
    );
    if (File(candidate).existsSync()) return candidate;
  }
  return 'dart';
}
