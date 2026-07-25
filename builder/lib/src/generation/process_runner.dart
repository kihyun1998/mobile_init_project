import 'dart:io';

/// 외부 명령 실행을 감싼다.
///
/// 테스트가 진짜 `flutter create` 를 돌리면 한 번에 몇 분이 걸려서 아무도
/// 돌리지 않게 된다. 그래서 실행 지점을 주입 가능하게 둔다.
abstract class ProcessRunner {
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
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
}

/// 실제로 프로세스를 띄우는 구현.
class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    // Windows 에서 flutter 는 flutter.bat 이라 shell 을 거쳐야 찾는다.
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    return ProcessRunResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}
