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
    this.timedOut = false,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  /// 무출력 감시견이 끊었는지.
  ///
  /// 종료 코드만으로는 구분할 수 없다 — 끊긴 프로세스가 돌려주는 값은 신호에
  /// 따라 OS 마다 다르고, 하필 0 이 나오는 경우를 배제할 근거도 없다. 그래서
  /// 끊었다는 사실을 따로 들고 다닌다.
  final bool timedOut;

  bool get succeeded => exitCode == 0 && !timedOut;

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
  const SystemProcessRunner({this.idleTimeout = defaultIdleTimeout});

  /// 이만큼 **아무 출력도 없으면** 자식을 끊는다.
  ///
  /// 총 실행 시간이 아니라 무출력 시간인 것이 요점이다. `build_runner` 는 새
  /// 프로젝트에서 몇 분씩 도는 것이 정상이라 총량으로 자르면 멀쩡한 작업을
  /// 죽인다. 반면 멈춘 자식은 출력까지 멎으므로, 무출력으로 재면 실패 모양과
  /// 정확히 맞고 정상적인 긴 작업을 오인하지 않는다.
  final Duration idleTimeout;

  /// 실측에 맞춘 값.
  ///
  /// 이 파이프라인에서 가장 오래 조용한 구간은 `build_runner` 의 분석 단계이고,
  /// 관측된 최대 무출력 간격은 10초 남짓이었다. 폰트 내려받기도 파일마다
  /// 한 줄씩 뱉는다. 5분은 그 어느 쪽도 오인하지 않으면서, "영원히" 를
  /// "5분 뒤 이유가 적힌 실패" 로 바꾼다.
  static const defaultIdleTimeout = Duration(minutes: 5);

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

    // 자식이 일을 다 끝내고도 끝나지 않는 경우가 실제로 있다 — 상류 CLI 가
    // Google Fonts 응답을 비우지 않고 던지면 요약까지 다 출력한 뒤 영원히
    // 살아 있다. 여기서 끊지 않으면 빌더가 "테마 생성 중" 에 붙박이고,
    // 사용자가 할 수 있는 일은 앱을 죽이는 것뿐이다.
    var timedOut = false;
    final givenUp = Completer<void>();
    Timer? watchdog;
    void resetWatchdog() {
      watchdog?.cancel();
      watchdog = Timer(idleTimeout, () {
        timedOut = true;
        process.kill(ProcessSignal.sigkill);
        if (!givenUp.isCompleted) givenUp.complete();
      });
    }

    Future<void> drain(Stream<List<int>> stream, StringBuffer into) {
      return stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
            resetWatchdog();
            into.writeln(line);
            onOutput?.call(line);
          });
    }

    final draining = Future.wait([
      drain(process.stdout, out),
      drain(process.stderr, err),
    ]);

    resetWatchdog();
    try {
      // **끊었다고 해서 drain 이 끝난다는 보장이 없다.** `runInShell: true` 라
      // 우리가 띄우는 것은 셸이고, 죽이는 것도 셸이다. 손자 프로세스가 살아서
      // 파이프를 붙들고 있으면 스트림이 닫히지 않아 `Future.wait` 가 영원히
      // 안 끝난다 — 감시견을 달아놓고도 그대로 멈추는 것이다. 실제로 Linux 와
      // Windows CI 에서만 그렇게 됐고 macOS 에서는 셸이 exec 로 대체돼 우연히
      // 통과했다. 그래서 끊은 뒤에는 **기다리는 것을 그만둔다.**
      await Future.any([draining, givenUp.future]);
    } finally {
      watchdog?.cancel();
      // 그만두더라도 drain 의 실패를 미아로 남기지 않는다.
      unawaited(draining.then((_) {}, onError: (_) {}));
      // 스트림을 읽다 터져도 프로세스는 반드시 거둬들인다. 안 그러면
      // exitCode 를 기다리는 사람이 없어 좀비가 남는다. 끊은 경우에는
      // 기다리지 않는다 — 붙들려 있는 것이 바로 그 프로세스다.
      if (timedOut) {
        unawaited(process.exitCode.then((_) {}, onError: (_) {}));
      } else {
        await process.exitCode;
      }
    }

    if (timedOut) {
      // 끊긴 프로세스의 종료 코드는 신호값이라 사용자에게 아무것도 말해주지
      // 않는다. 무엇이 왜 끊겼는지를 실패 문구로 남긴다.
      err.writeln(
        '$executable ${arguments.join(' ')} 이(가) '
        '${idleTimeout.inMinutes}분 동안 응답이 없어 중단했습니다. '
        '명령이 끝나고도 종료하지 않았을 수 있습니다.',
      );
    }

    return ProcessRunResult(
      // 끊은 경우 종료 코드를 기다리지 않으므로 자리만 채운다. 성공 여부는
      // [ProcessRunResult.timedOut] 이 이미 결정한다.
      exitCode: timedOut ? -1 : await process.exitCode,
      stdout: out.toString(),
      stderr: err.toString(),
      timedOut: timedOut,
    );
  }
}
