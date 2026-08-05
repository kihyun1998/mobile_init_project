import 'dart:io';

import 'process_runner.dart';

/// 만들어진 폴더를 파인더/탐색기에서 연다.
///
/// [ProcessRunner] 를 재사용하는 이유는 테스트에서 진짜 창이 뜨지 않게 하기
/// 위해서다. 가짜 러너를 꽂으면 어떤 명령을 부르려 했는지만 확인된다.
Future<ProcessRunResult> revealInFileManager(
  String path,
  ProcessRunner runner,
) {
  final (executable, arguments) = switch (Platform.operatingSystem) {
    'macos' => ('open', [path]),
    'windows' => ('explorer', [path]),
    _ => ('xdg-open', [path]),
  };

  return runner.run(executable, arguments);
}

/// 열어본 결과를 **실패라고 말할지.**
///
/// [ProcessRunResult.succeeded] 를 그대로 쓰면 안 된다 — **Windows 의
/// `explorer` 는 성공해도 `1` 을 돌려준다.** 실측 (2026-08-05, Windows 11):
///
/// ```
/// explorer C:\Users\User\mib-builder-release-test
///   → 창이 정상적으로 열린 상태에서 exitCode 1
/// ```
///
/// 그래서 종료 코드에 정보가 없고, 1 을 실패로 읽으면 이 버튼은 Windows 에서
/// **항상** "폴더를 열지 못했습니다" 를 띄운다. 간헐적이 아니라 100% 다.
/// #32 의 릴리스 왕복에서 실제로 그렇게 나왔고, macOS 의 `open` 은 0 을
/// 돌려주므로 개발 머신에서는 보이지 않았다.
///
/// Windows 에서 남는 유일한 신호는 **감시견이 끊었는지**다. 그것마저 무시하면
/// 매달린 프로세스를 성공으로 보고하게 된다.
///
/// [operatingSystem] 을 인자로 받는 이유는 이 판정이 OS 마다 다른데 테스트는 한
/// OS 에서만 돌기 때문이다. `Platform.operatingSystem` 을 안에서 읽으면 Windows
/// 규칙이 Windows 러너에서만 검증되고, 나머지 두 OS 의 CI 에서는 이 자리가
/// 빈칸으로 남는다.
bool revealFailed(ProcessRunResult result, {required String operatingSystem}) =>
    operatingSystem == 'windows' ? result.timedOut : !result.succeeded;
