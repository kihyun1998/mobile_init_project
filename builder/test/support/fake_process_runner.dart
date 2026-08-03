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
    this.failureExitCode = 1,
  });

  /// 명령줄에 이 문자열이 들어 있으면 실패시킨다. 예: `'build_runner'`.
  final String? failingCommand;

  /// [failingCommand] 가 돌려줄 종료 코드.
  ///
  /// 기본 1 이지만 **값을 고를 수 있어야 한다** — 테마 CLI 는 0.5.0 부터
  /// `1`(아무것도 생성 안 됨)과 `2`(테마는 썼고 필요한 것이 빠짐)를 다른
  /// 뜻으로 쓰고, 빌더는 그 둘을 다르게 다룬다.
  final int failureExitCode;

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
      _scaffold(arguments.last, workingDirectory!, _platformsOf(arguments));
    }

    return ProcessRunResult(
      exitCode: fails ? failureExitCode : 0,
      stdout: outputLines.join('\n'),
      stderr: fails ? stderr : '',
    );
  }

  /// `--platforms=android,ios` 에서 고른 플랫폼을 뽑는다.
  /// 인자가 없으면 진짜 flutter 처럼 전부 만든다.
  static List<String> _platformsOf(List<String> arguments) {
    const prefix = '--platforms=';
    final flag = arguments.firstWhere(
      (a) => a.startsWith(prefix),
      orElse: () => '',
    );
    if (flag.isEmpty) {
      return const ['android', 'ios', 'macos', 'windows', 'linux', 'web'];
    }
    return flag.substring(prefix.length).split(',');
  }

  /// flutter create 가 만들어놓는 것과 같은 모양의 뼈대.
  /// 플랫폼 폴더에 마커를 남겨서, 우리가 그걸 덮어쓰지 않는지 확인한다.
  void _scaffold(String name, String parent, List<String> platforms) {
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

    for (final dir in platforms) {
      File(p.join(root.path, dir, 'marker.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('from-flutter-create');
    }
    if (platforms.contains('android')) _writeManifest(root, name);
    if (platforms.contains('ios')) _writeInfoPlist(root, name);
  }

  /// 표시 이름이 들어갈 자리를 진짜 flutter create 출력과 같은 모양으로 만든다.
  /// 안드로이드 라벨은 패키지 이름 그대로다.
  void _writeManifest(Directory root, String name) {
    File(
        p.join(
          root.path,
          'android',
          'app',
          'src',
          'main',
          'AndroidManifest.xml',
        ),
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="$name"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>
''');
  }

  void _writeInfoPlist(Directory root, String name) {
    File(p.join(root.path, 'ios', 'Runner', 'Info.plist'))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>\$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>${_humanize(name)}</string>
	<key>CFBundleName</key>
	<string>$name</string>
</dict>
</plist>
''');
  }

  /// flutter create 는 plist 의 표시 이름만 `my_app` → `My App` 으로 바꿔 넣는다.
  /// 그대로 흉내내야 "우리가 덮어썼는가" 를 이 값으로 구분할 수 있다 —
  /// 표시 이름을 비워서 프로젝트 이름이 들어가는 경우까지 포함해서.
  static String _humanize(String name) => name
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

class ProcessInvocation {
  ProcessInvocation(this.executable, this.arguments, this.workingDirectory);

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
}
