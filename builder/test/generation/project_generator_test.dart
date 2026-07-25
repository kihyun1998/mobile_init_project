import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/generation_exception.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:path/path.dart' as p;

import '../support/fake_process_runner.dart';

void main() {
  late Directory outputParent;
  late FakeProcessRunner runner;
  late ProjectGenerator generator;

  // 진짜 template/ 을 쓴다. 합성 픽스처를 쓰면 템플릿이 바뀌어도 테스트가
  // 통과해버리는데, 여기서 지키려는 계약이 바로 "템플릿이 제대로 얹히는가" 다.
  final templateDir = Directory(p.join('..', 'template'));

  setUp(() {
    outputParent = Directory.systemTemp.createTempSync('gen_test_');
    runner = FakeProcessRunner();
    generator = ProjectGenerator(
      templateDir: templateDir,
      processRunner: runner,
    );
  });

  tearDown(() => outputParent.deleteSync(recursive: true));

  Future<Directory> generate({
    String name = 'my_app',
    String org = 'io.github.kihyun1998',
    String description = '내가 쓴 설명',
  }) {
    return generator.generate(
      GenerationConfig(
        projectName: name,
        organization: org,
        outputParent: outputParent,
        description: description,
      ),
    );
  }

  String read(Directory root, String relative) =>
      File(p.join(root.path, relative)).readAsStringSync();

  test('flutter create 가 입력한 이름과 org 로 실행된다', () async {
    await generate(name: 'my_app', org: 'com.example.team');

    final create = runner.invocations.single;
    expect(create.executable, 'flutter');
    expect(create.arguments.first, 'create');
    expect(create.arguments, contains('--org'));
    expect(create.arguments, contains('com.example.team'));
    expect(create.arguments.last, 'my_app');
  });

  test('allowlist 에 있는 것이 결과물에 얹힌다', () async {
    final root = await generate();

    for (final entry in ['lib', 'test', 'pubspec.yaml', 'tweakcn.css']) {
      expect(
        File(p.join(root.path, entry)).existsSync() ||
            Directory(p.join(root.path, entry)).existsSync(),
        isTrue,
        reason: '$entry 가 복사되지 않았다',
      );
    }
    expect(
      Directory(p.join(root.path, 'lib', 'ui', 'components')).existsSync(),
      isTrue,
    );
  });

  test('템플릿의 플랫폼 폴더와 메타데이터는 복사되지 않는다', () async {
    final root = await generate();

    // flutter create 가 남긴 것이 그대로 있어야 한다.
    expect(read(root, p.join('android', 'marker.txt')), 'from-flutter-create');
    expect(read(root, '.metadata'), 'flutter-create');

    // 템플릿에만 있는 플랫폼 파일이 넘어오면 안 된다.
    expect(
      File(p.join(root.path, 'android', 'app', 'build.gradle.kts')).existsSync(),
      isFalse,
      reason: '템플릿의 android/ 가 복사됐다',
    );
    expect(
      Directory(p.join(root.path, 'macos')).existsSync(),
      isFalse,
      reason: '고르지도 않은 템플릿 플랫폼 폴더가 넘어왔다',
    );
  });

  test('flutter create 가 만든 진입점과 위젯 테스트는 템플릿 것으로 덮어써진다', () async {
    final root = await generate();

    expect(read(root, p.join('lib', 'main.dart')), contains('ScreenUtilInit'));
    expect(
      read(root, p.join('test', 'widget_test.dart')),
      isNot(contains('flutter create default')),
    );
  });

  test('결과물에 템플릿 패키지 참조가 하나도 남지 않는다', () async {
    final root = await generate(name: 'my_app');

    final offenders = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => const {'.dart', '.yaml', '.arb', '.md'}
            .contains(p.extension(f.path)))
        .where((f) => f.readAsStringSync().contains('mobile_init_project'))
        .map((f) => p.relative(f.path, from: root.path))
        .toList();

    expect(offenders, isEmpty);
    expect(
      read(root, p.join('lib', 'core', 'ui', 'top_toast.dart')),
      contains('package:my_app/'),
    );
  });

  test('pubspec 의 이름과 설명이 입력값이다', () async {
    final root = await generate(name: 'my_app', description: '내가 쓴 설명');
    final pubspec = read(root, 'pubspec.yaml');

    expect(pubspec, contains('name: my_app'));
    expect(pubspec, contains('description: "내가 쓴 설명"'));
    expect(pubspec, isNot(contains('created-by-flutter-create')));
    expect(pubspec, isNot(contains('name: mobile_init_project')));
  });

  test('입력받지 않는 버전은 flutter create 가 정한 값을 쓴다', () async {
    final pubspec = read(await generate(), 'pubspec.yaml');

    // 템플릿의 1.0.0+1 을 물려받으면 안 된다.
    expect(pubspec, contains('version: 9.9.9+42'));
  });

  test('템플릿이 정하는 codegen 설정은 따라온다', () async {
    final pubspec = read(await generate(), 'pubspec.yaml');

    expect(pubspec, contains('flutter_tweakcn_generator:'));
    expect(pubspec, contains('flutter_intl:'));
    expect(pubspec, contains('riverpod_generator:'));
  });

  test('설명에 따옴표가 들어와도 pubspec 이 깨지지 않는다', () async {
    final pubspec = read(
      await generate(description: 'He said "hi"'),
      'pubspec.yaml',
    );

    expect(pubspec, contains(r'description: "He said \"hi\""'));
  });

  group('생성 전에 막는 것', () {
    test('Dart 패키지명 규칙에 안 맞는 이름은 flutter create 전에 거부된다', () async {
      for (final bad in ['My-App', '2fast', 'my app', '', 'class']) {
        await expectLater(
          generate(name: bad),
          throwsA(isA<GenerationException>()),
          reason: '"$bad" 이 통과했다',
        );
      }
      expect(runner.invocations, isEmpty);
    });

    test('org 형식이 틀리면 거부된다', () async {
      await expectLater(
        generate(org: 'nodots'),
        throwsA(isA<GenerationException>()),
      );
      expect(runner.invocations, isEmpty);
    });

    test('같은 이름의 폴더가 이미 있으면 아무것도 건드리지 않고 실패한다', () async {
      final existing = Directory(p.join(outputParent.path, 'my_app'))
        ..createSync();
      final precious = File(p.join(existing.path, 'precious.txt'))
        ..writeAsStringSync('건드리지 마시오');

      await expectLater(
        generate(name: 'my_app'),
        throwsA(isA<GenerationException>()),
      );

      expect(precious.readAsStringSync(), '건드리지 마시오');
      expect(existing.listSync(), hasLength(1));
      expect(runner.invocations, isEmpty);
    });
  });
}
