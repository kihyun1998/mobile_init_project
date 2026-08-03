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
  /// 이 단계는 유일하게 네트워크를 탄다(Google Fonts). 앞에 두면 거기서 난
  /// 실패 한 번으로 l10n 과 코드 생성이 통째로 건너뛰어진다. 그런데
  /// `_applyLanguages` 는 **일부러** 생성물을 손대지 않고 `intl_utils` 가 고아
  /// `messages_*.dart` 를 지워주는 데 기대고 있어서, 결과물은 **컴파일은
  /// 되는데** 고르지도 않은 언어를 이고 있는 상태가 된다. 조용해서 더 나쁘다.
  ///
  /// 뒤로 미뤄도 잃는 것이 없다 — 상류 `build.yaml` 은 `.tweakcn.css` 만
  /// claim 하므로 `build_runner` 는 테마 파일을 입력으로 삼지 않는다.
  ///
  /// 실패 사유를 **CSS 를 못 읽은 것**으로 잡은 데 이유가 있다. 0.5.0 부터
  /// 폰트를 못 받은 것은 `1` 이 아니라 `2` 라서, 그걸로는 이 테스트가 재려는
  /// "하드 실패해도 앞 단계는 끝나 있다" 를 못 만든다 (`2` 는 아예 실패가
  /// 아니다). `1` 은 생성된 테마가 없다는 뜻이고, 그 대표적인 원인이 이것이다.
  test('테마 생성이 마지막이라, 실패해도 언어와 코드 생성은 끝나 있다', () async {
    runner = FakeProcessRunner(
      failingCommand: 'flutter_tweakcn_generator',
      stderr: 'Error: CSS file not found: tweakcn.css',
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

  /// **exit 2 는 실패가 아니다 — 상류 0.5.0 이 정한 값이다.**
  ///
  /// `0` = 생성된 테마를 그대로 쓸 수 있음, `1` = 아무것도 생성되지 않음,
  /// `2` = 테마는 썼지만 그것이 필요로 하는 것이 빠짐. 세 값뿐이고, `2` 는
  /// `1` 보다 나쁜 것이 아니라 **다른 범주**다 (상류 `bin/` 의 `_exitPartial`
  /// doc-comment 가 명시한다).
  ///
  /// 실제로 걸리는 경로다 — 붙여넣은 CSS 의 `--font-sans` 가 Google Fonts 에
  /// 없는 이름으로 시작하면 조회가 400 을 받고, 테마는 정상적으로 써진 채
  /// 폰트만 빠진다. 상류 실측으로 `Segoe UI`·`Arial`·`SF Pro Display` 가
  /// 전부 그렇고, 셋 다 tweakcn 이 흔히 뱉는 스택의 맨 앞자리다.
  ///
  /// 이걸 하드 실패로 취급하면 **`flutter run` 이 그냥 되는 결과물**을
  /// "테마 생성에서 실패했습니다" 로 띄우게 된다. 상류가 갈라준 구분을
  /// 하류에서 도로 뭉개는 것이라, 0.4.0 시절의 우회를 그대로 이고 있는 셈이다.
  test('테마 생성이 exit 2 면 실패가 아니라 경고다', () async {
    runner = FakeProcessRunner(
      failingCommand: 'flutter_tweakcn_generator',
      failureExitCode: 2,
      stderr:
          'Error: the generated theme names 1 font family(ies) that '
          'pubspec.yaml does not declare, so Flutter falls back to the '
          'default font at runtime:\n  Segoe UI',
    );

    final result = await generate();

    expect(result.succeeded, isTrue);
    expect(result.failedStep, isNull);
    expect(result.projectRoot.existsSync(), isTrue);
    expect(
      result.warnings.join('\n'),
      contains('pubspec.yaml does not declare'),
      reason: '조용히 삼키면 사용자는 폰트가 빠진 것을 영영 모른다',
    );
  });

  /// 위 테스트의 짝. **`2` 만 통과시키는 것**이지 non-zero 를 통과시키는 게
  /// 아니다 — `1` 은 생성된 테마가 아예 없다는 뜻이라 예전대로 하드 실패다.
  test('같은 단계라도 exit 1 은 여전히 하드 실패다', () async {
    runner = FakeProcessRunner(
      failingCommand: 'flutter_tweakcn_generator',
      failureExitCode: 1,
      stderr: 'Error: CSS file not found: tweakcn.css',
    );

    final result = await generate();

    expect(result.succeeded, isFalse);
    expect(result.failedStep, GenerationStep.theme);
    expect(result.warnings, isEmpty);
  });

  /// exit 2 를 관대하게 보는 것은 **테마 단계 하나뿐**이다. 다른 단계에는
  /// 그런 계약이 없다 — `build_runner` 의 2 는 그냥 실패다.
  test('테마가 아닌 단계의 exit 2 는 하드 실패다', () async {
    runner = FakeProcessRunner(
      failingCommand: 'build_runner',
      failureExitCode: 2,
      stderr: '코드 생성이 터졌습니다',
    );

    final result = await generate();

    expect(result.succeeded, isFalse);
    expect(result.failedStep, GenerationStep.codegen);
  });

  test('전부 성공하면 경고도 없다', () async {
    final result = await generate();

    expect(result.warnings, isEmpty);
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
