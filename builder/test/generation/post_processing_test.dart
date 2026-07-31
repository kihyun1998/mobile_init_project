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

  test('의존성 설치 → l10n 생성 → 코드 생성 순서로 실행된다', () async {
    await generate();

    final commands = commandsRun();
    expect(commands.first, startsWith('flutter create'));
    expect(commands.sublist(1), [
      'flutter pub get',
      'dart run intl_utils:generate',
      'dart run build_runner build --delete-conflicting-outputs',
    ]);
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
    ]);
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
