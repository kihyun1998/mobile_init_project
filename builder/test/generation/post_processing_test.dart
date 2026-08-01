import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/generation_event.dart';
import 'package:mobile_init_builder/src/generation/generation_exception.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:path/path.dart' as p;

import '../support/fake_process_runner.dart';

void main() {
  late Directory outputParent;
  late FakeProcessRunner runner;

  setUp(() {
    outputParent = Directory.systemTemp.createTempSync('post_test_');
    runner = FakeProcessRunner();
  });

  tearDown(() => outputParent.deleteSync(recursive: true));

  Future<GenerationResult> generate({
    void Function(GenerationEvent)? onEvent,
  }) async {
    return ProjectGenerator(
      templateDir: Directory(p.join('..', 'template')),
      processRunner: runner,
    ).generate(
      GenerationConfig(
        projectName: PackageName.parse('my_app'),
        organization: Organization.parse('io.github.kihyun1998'),
        outputParent: outputParent,
      ),
      onEvent: onEvent,
    );
  }

  List<String> commandsRun() => runner.invocations
      .map((i) => '${i.executable} ${i.arguments.join(' ')}')
      .toList();

  test('의존성 설치 → l10n 생성 → 코드 생성 → 테마 생성 순서로 실행된다', () async {
    await generate();

    final commands = commandsRun();
    expect(commands.first, startsWith('flutter create'));
    expect(commands.sublist(1), [
      'flutter pub get',
      'dart run intl_utils:generate',
      'dart run build_runner build --delete-conflicting-outputs',
      'dart run flutter_tweakcn_generator',
    ]);
  });

  /// **테마를 만드는 것은 build_runner 가 아니다.**
  ///
  /// 상류 패키지의 build.yaml 은 `.tweakcn.css` → `.tweakcn.dart` 만 걸고,
  /// pubspec 의 `flutter_tweakcn_generator:` 블록(`input`/`output`)은 CLI 만
  /// 읽는다. 템플릿의 파일 이름은 `tweakcn.css` 라 builder 패턴에 애초에 걸리지
  /// 않는다. 그래서 build_runner 만 돌리면 **복사해온 옛 테마가 그대로 남는다.**
  ///
  /// 실제로 확인했다 — 템플릿의 `--primary` 를 바꾸고 build_runner 를 돌리면
  /// `tweakcn_theme.g.dart` 는 한 글자도 바뀌지 않고, CLI 를 돌리면 바뀐다.
  test('테마 생성은 별도 명령이고 build_runner 에 묻어가지 않는다', () async {
    await generate();

    expect(
      commandsRun(),
      contains('dart run flutter_tweakcn_generator'),
      reason: 'build_runner 는 tweakcn 테마를 재생성하지 않는다',
    );
  });

  /// **테마 생성이 마지막이어야 하는 이유는 실패했을 때다.**
  ///
  /// 이 단계는 유일하게 네트워크를 타고(Google Fonts), 폰트 파일 하나만 못
  /// 받아도 상류 CLI 가 `exitCode = 1` 을 세운다. 앞에 두면 그 한 번의 실패로
  /// l10n 과 코드 생성이 통째로 건너뛰어진다. 그런데 `_applyLanguages` 는
  /// **일부러** 생성물을 손대지 않고 `intl_utils` 가 고아 `messages_*.dart` 를
  /// 지워주는 데 기대고 있어서, 결과물은 **컴파일은 되는데** 고르지도 않은
  /// 언어를 이고 있는 상태가 된다. 조용해서 더 나쁘다.
  ///
  /// 뒤로 미뤄도 잃는 것이 없다 — 상류 `build.yaml` 은 `.tweakcn.css` 만
  /// claim 하므로 `build_runner` 는 테마 파일을 입력으로 삼지 않는다.
  test('테마 생성이 마지막이라, 실패해도 언어와 코드 생성은 끝나 있다', () async {
    runner = FakeProcessRunner(
      failingCommand: 'flutter_tweakcn_generator',
      stderr: '폰트를 받지 못했습니다',
    );

    final result = await generate();
    final commands = commandsRun().join('\n');

    expect(result.failedStep, GenerationStep.theme);
    expect(commands, contains('intl_utils'));
    expect(commands, contains('build_runner'));
  });

  test('테마 생성은 pub get 뒤에 온다 — 그래야 dart run 이 된다', () async {
    await generate();

    final commands = commandsRun();
    expect(
      commands.indexOf('dart run flutter_tweakcn_generator'),
      greaterThan(commands.indexOf('flutter pub get')),
    );
  });

  test('후처리는 새 프로젝트 폴더 안에서 실행된다', () async {
    final result = await generate();

    for (final invocation in runner.invocations.skip(1)) {
      expect(invocation.workingDirectory, result.projectRoot.path);
    }
  });

  test('단계가 순서대로 보고된다', () async {
    final steps = <GenerationStep>[];
    await generate(
      onEvent: (e) {
        if (e is GenerationStepStarted) steps.add(e.step);
      },
    );

    expect(steps, [
      GenerationStep.scaffold,
      GenerationStep.applyTemplate,
      GenerationStep.dependencies,
      GenerationStep.localization,
      GenerationStep.codegen,
      GenerationStep.theme,
    ]);
  });

  test('테마 생성이 실패하면 그 단계로 보고되고 프로젝트는 남는다', () async {
    runner = FakeProcessRunner(
      failingCommand: 'flutter_tweakcn_generator',
      stderr: 'CSS 를 읽지 못했습니다',
    );

    final result = await generate();

    expect(result.succeeded, isFalse);
    expect(result.failedStep, GenerationStep.theme);
    expect(result.failureMessage, contains('CSS 를 읽지 못했습니다'));
    expect(result.projectRoot.existsSync(), isTrue);
  });

  test('명령 출력이 진행 중에 흘러나온다', () async {
    runner = FakeProcessRunner(
      outputLines: ['Resolving...', 'Got dependencies!'],
    );

    final lines = <String>[];
    await generate(
      onEvent: (e) {
        if (e is GenerationOutput) lines.add(e.line);
      },
    );

    expect(lines, contains('Got dependencies!'));
  });

  group('후처리가 실패해도', () {
    test('만들어진 프로젝트는 지워지지 않는다', () async {
      runner = FakeProcessRunner(
        failingCommand: 'build_runner',
        stderr: '코드 생성이 터졌습니다',
      );

      final result = await generate();

      expect(result.projectRoot.existsSync(), isTrue);
      expect(
        File(p.join(result.projectRoot.path, 'pubspec.yaml')).existsSync(),
        isTrue,
      );
    });

    test('어느 단계에서 왜 실패했는지 알 수 있다', () async {
      runner = FakeProcessRunner(
        failingCommand: 'build_runner',
        stderr: '코드 생성이 터졌습니다',
      );

      final result = await generate();

      expect(result.succeeded, isFalse);
      expect(result.failedStep, GenerationStep.codegen);
      expect(result.failureMessage, contains('코드 생성이 터졌습니다'));
    });

    test('실패한 단계 뒤의 명령은 실행하지 않는다', () async {
      runner = FakeProcessRunner(failingCommand: 'pub get');

      await generate();

      expect(commandsRun().join('\n'), isNot(contains('build_runner')));
      expect(commandsRun().join('\n'), isNot(contains('intl_utils')));
      expect(
        commandsRun().join('\n'),
        isNot(contains('flutter_tweakcn_generator')),
      );
    });
  });

  test('전부 성공하면 결과가 성공이다', () async {
    final result = await generate();

    expect(result.succeeded, isTrue);
    expect(result.failedStep, isNull);
  });

  test('flutter create 가 실패하면 쓸 프로젝트가 없으므로 예외다', () async {
    runner = FakeProcessRunner(
      failingCommand: 'create',
      stderr: '디스크가 가득 찼습니다',
    );

    await expectLater(generate(), throwsA(isA<GenerationException>()));
  });
}
