import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/process_runner.dart';

/// 여기서만 **진짜 프로세스**를 띄운다.
///
/// 나머지 테스트는 전부 가짜 러너를 쓰는데, 가짜는 출력을 동기로 뱉기 때문에
/// SystemProcessRunner 가 버퍼링 방식으로 되돌아가도 눈치채지 못한다.
/// "출력이 진행 중에 흐른다" 는 이 티켓의 핵심 약속이므로 여기서 못박는다.
void main() {
  const runner = SystemProcessRunner();

  // sh 는 Windows 에 없다. 개발이 macOS 에서 이뤄지므로 여기서만 검증하고,
  // Windows 동작은 사람이 확인한다.
  final skipOnWindows = Platform.isWindows ? 'sh 가 없는 플랫폼' : null;

  test('출력이 프로세스가 끝나기 전에 흘러나온다', () async {
    final firstLine = Completer<String>();

    final pending = runner.run(
      'sh',
      ['-c', 'echo 첫줄; sleep 1; echo 마지막줄'],
      onOutput: (line) {
        if (!firstLine.isCompleted) firstLine.complete(line);
      },
    );

    // 프로세스는 1초를 더 도는데, 첫 줄은 그 전에 와야 한다.
    // 버퍼링이면 여기서 시간 초과로 터진다.
    final line = await firstLine.future.timeout(const Duration(milliseconds: 700));
    expect(line, '첫줄');

    final result = await pending;
    expect(result.succeeded, isTrue);
    expect(result.stdout, contains('마지막줄'));
  }, skip: skipOnWindows);

  test('stdin 을 읽는 명령이 멈추지 않는다', () async {
    // Process.run 은 stdin 을 닫아주지만 start 는 안 닫는다. 안 닫으면
    // cat 이 입력을 기다리며 영원히 멈춘다.
    final result = await runner
        .run('sh', ['-c', 'cat'])
        .timeout(const Duration(seconds: 5));

    expect(result.exitCode, 0);
  }, skip: skipOnWindows);

  test('실패한 명령의 종료 코드와 stderr 를 돌려준다', () async {
    final result = await runner.run('sh', ['-c', 'echo 망했다 >&2; exit 3']);

    expect(result.succeeded, isFalse);
    expect(result.exitCode, 3);
    expect(result.failureOutput, contains('망했다'));
  }, skip: skipOnWindows);

  test('실패 문구는 긴 로그를 통째로 쏟지 않는다', () {
    const result = ProcessRunResult(
      exitCode: 1,
      stdout: '',
      stderr: '',
    );
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
