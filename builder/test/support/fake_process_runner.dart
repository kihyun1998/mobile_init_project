import 'dart:io';

import 'package:mobile_init_builder/src/generation/process_runner.dart';
import 'package:path/path.dart' as p;

/// `flutter create` 와 후처리 명령을 흉내내는 러너.
///
/// 진짜로 돌리면 테스트 한 번에 몇 분이 걸려서 아무도 돌리지 않게 된다.
/// 여기서 검증하려는 건 flutter 의 동작이 아니라 **그 위에 우리가 얹는 것** 이다.
class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner({
    this.failingCommand,
    this.stderr = '',
    this.outputLines = const [],
  });

  /// 명령줄에 이 문자열이 들어 있으면 실패시킨다. 예: `'build_runner'`.
  final String? failingCommand;

  final String stderr;

  /// 모든 명령이 뱉을 출력 줄.
  final List<String> outputLines;

  final List<ProcessInvocation> invocations = [];

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    void Function(String line)? onOutput,
  }) async {
    invocations.add(ProcessInvocation(executable, arguments, workingDirectory));

    final commandLine = '$executable ${arguments.join(' ')}';
    final fails =
        failingCommand != null && commandLine.contains(failingCommand!);

    for (final line in outputLines) {
      onOutput?.call(line);
    }

    if (!fails && executable == 'flutter' && arguments.first == 'create') {
      _scaffold(arguments.last, workingDirectory!);
    }

    return ProcessRunResult(
      exitCode: fails ? 1 : 0,
      stdout: outputLines.join('\n'),
      stderr: fails ? stderr : '',
    );
  }

  /// flutter create 가 만들어놓는 것과 같은 모양의 뼈대.
  /// 플랫폼 폴더에 마커를 남겨서, 우리가 그걸 덮어쓰지 않는지 확인한다.
  void _scaffold(String name, String parent) {
    final root = Directory(p.join(parent, name))..createSync(recursive: true);
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: $name
description: "created-by-flutter-create"
publish_to: "none"
version: 9.9.9+42

environment:
  sdk: ^3.12.2
''');
    File(p.join(root.path, '.metadata')).writeAsStringSync('flutter-create');
    for (final f in ['lib/main.dart', 'test/widget_test.dart']) {
      File(p.join(root.path, f))
        ..createSync(recursive: true)
        ..writeAsStringSync('// flutter create default');
    }
    for (final dir in ['android', 'ios']) {
      File(p.join(root.path, dir, 'marker.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('from-flutter-create');
    }
  }
}

class ProcessInvocation {
  ProcessInvocation(this.executable, this.arguments, this.workingDirectory);

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
}
