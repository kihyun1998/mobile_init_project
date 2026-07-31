import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 외부 명령 실행을 감싼다.
///
/// 테스트가 진짜 `flutter create` 나 `build_runner` 를 돌리면 한 번에 몇 분이
/// 걸려서 아무도 돌리지 않게 된다. 그래서 실행 지점을 주입 가능하게 둔다.
abstract class ProcessRunner {
  /// [onOutput] 은 줄 단위로 **실행 중에** 불린다. build_runner 는 처음
  /// 돌 때 몇 분이 걸리는데, 끝나야 출력이 보이면 사용자는 멈춘 줄로 안다.
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    void Function(String line)? onOutput,
  });
}

class ProcessRunResult {
  const ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get succeeded => exitCode == 0;

  /// 실패 원인으로 보여줄 만한 문구.
  ///
  /// stderr 가 비면 stdout 을 쓴다 — build_runner 는 오류도 stdout 으로 뱉는다.
  /// 다만 통째로 쓰면 몇 분치 빌드 로그가 화면을 덮어 정작 원인이 묻히므로
  /// 마지막 몇 줄만 남긴다. 전체는 로그 창에 이미 흐르고 있다.
  String get failureOutput {
    final source = stderr.trim().isEmpty ? stdout.trim() : stderr.trim();
    if (source.isEmpty) return source;

    final lines = source.split('\n');
    if (lines.length <= _failureTailLines) return source;
    return '…\n${lines.sublist(lines.length - _failureTailLines).join('\n')}';
  }

  static const _failureTailLines = 20;
}

/// 실제로 프로세스를 띄우는 구현.
class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    void Function(String line)? onOutput,
  }) async {
    // Process.run 이 아니라 start 를 쓴다. run 은 프로세스가 끝나야 출력을
    // 돌려주기 때문에 진행 상황을 흘려보낼 수 없다.
    // Windows 에서 flutter/dart 는 .bat 이라 shell 을 거쳐야 찾는다.
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    // Process.run 은 stdin 을 닫아주지만 start 는 안 닫는다. 자식이 입력을
    // 기다리면(설치 확인 프롬프트 같은 것) 아무도 답하지 않아 영원히 멈춘다.
    unawaited(process.stdin.close().catchError((_) {}));

    final out = StringBuffer();
    final err = StringBuffer();

    Future<void> drain(Stream<List<int>> stream, StringBuffer into) {
      return stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
            into.writeln(line);
            onOutput?.call(line);
          });
    }

    try {
      await Future.wait([
        drain(process.stdout, out),
        drain(process.stderr, err),
      ]);
    } finally {
      // 스트림을 읽다 터져도 프로세스는 반드시 거둬들인다. 안 그러면
      // exitCode 를 기다리는 사람이 없어 좀비가 남는다.
      await process.exitCode;
    }

    return ProcessRunResult(
      exitCode: await process.exitCode,
      stdout: out.toString(),
      stderr: err.toString(),
    );
  }
}
