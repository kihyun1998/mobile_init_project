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
