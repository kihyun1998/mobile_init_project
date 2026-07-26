import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/generation_exception.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/generation/project_platform.dart';
import 'package:path/path.dart' as p;

import '../support/fake_process_runner.dart';

/// 텍스트로 읽히면 내용을, 바이너리면 null 을 준다.
/// 확장자로 거르는 대신 이렇게 하면 어떤 파일도 검사에서 빠지지 않는다.
String? _readTextOrNull(File file) {
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

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
    String displayName = '',
    List<ProjectPlatform> platforms = const [
      ProjectPlatform.android,
      ProjectPlatform.ios,
    ],
  }) {
    return generator
        .generate(
          GenerationConfig(
            projectName: PackageName.parse(name),
            organization: Organization.parse(org),
            outputParent: outputParent,
            description: description,
            displayName: displayName,
            platforms: PlatformSelection.of(platforms),
          ),
        )
        .then((r) => r.projectRoot);
  }

  String read(Directory root, String relative) =>
      File(p.join(root.path, relative)).readAsStringSync();

  test('flutter create 가 입력한 이름과 org 로 실행된다', () async {
    await generate(name: 'my_app', org: 'com.example.team');

    final create = runner.invocations.first;
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

    // 확장자 목록을 두지 않는다. 구현이 다루는 확장자가 늘어도 이 검사는
    // 자동으로 따라가야 한다 — 목록을 복사해두면 조용히 범위만 좁아진다.
    final offenders = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _readTextOrNull(f)?.contains('mobile_init_project') ?? false)
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

  group('플랫폼', () {
    test('고른 플랫폼만 --platforms 로 넘어간다', () async {
      await generate(
        platforms: [ProjectPlatform.web, ProjectPlatform.android],
      );

      expect(
        runner.invocations.first.arguments,
        contains('--platforms=android,web'),
        reason: '체크한 순서가 아니라 선언 순서로 정규화돼야 한다',
      );
    });

    test('고르지 않은 플랫폼 폴더는 결과물에 없다', () async {
      final root = await generate(platforms: [ProjectPlatform.android]);

      expect(Directory(p.join(root.path, 'android')).existsSync(), isTrue);
      for (final absent in ['ios', 'macos', 'windows', 'linux', 'web']) {
        expect(
          Directory(p.join(root.path, absent)).existsSync(),
          isFalse,
          reason: '고르지 않은 $absent 가 생겼다',
        );
      }
    });

    test('하나도 고르지 않으면 만들 수 없다', () {
      // 빈 --platforms= 를 넘기면 flutter 가 한참 뒤에 알아듣기 힘든 소리를
      // 한다. 그 전에 값 타입이 막는다 — 생성기까지 갈 방법이 없다.
      expect(
        () => PlatformSelection.of(const []),
        throwsA(isA<GenerationException>()),
      );
    });
  });

  group('표시 이름', () {
    test('앱 타이틀·안드로이드 라벨·iOS 표시 이름에 모두 들어간다', () async {
      final root = await generate(name: 'my_app', displayName: '내 가계부');

      expect(read(root, p.join('lib', 'main.dart')), contains("'내 가계부'"));
      expect(
        read(root, p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')),
        contains('android:label="내 가계부"'),
      );
      expect(
        read(root, p.join('ios', 'Runner', 'Info.plist')),
        contains('<string>내 가계부</string>'),
      );
    });

    test('비워두면 프로젝트 이름을 쓴다', () async {
      final root = await generate(name: 'my_app', displayName: '   ');

      expect(read(root, p.join('lib', 'main.dart')), contains("'my_app'"));
      // 안드로이드 라벨은 flutter create 도 프로젝트 이름을 넣는다. 그래서 이
      // 검사는 결과가 맞는지만 보고, 치환이 실제로 돌았는지는 구분하지 못한다
      // — 그건 위의 '내 가계부' 검사가 본다.
      expect(
        read(root, p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')),
        contains('android:label="my_app"'),
      );
      // plist 는 다르다. flutter create 가 'My App' 을 넣어두므로 치환이
      // 빠지면 여기서 걸린다.
      expect(
        read(root, p.join('ios', 'Runner', 'Info.plist')),
        contains('<string>my_app</string>'),
      );
      expect(
        read(root, p.join('ios', 'Runner', 'Info.plist')),
        isNot(contains('<string>My App</string>')),
      );
    });

    test('템플릿 표시 이름이 결과물에 남지 않는다', () async {
      final root = await generate(displayName: '내 가계부');

      expect(
        read(root, p.join('lib', 'main.dart')),
        isNot(contains(ProjectGenerator.templateDisplayName)),
      );
    });

    test('생성기가 아는 표시 이름을 템플릿이 실제로 쓰고 있다', () {
      // 위 검사들은 전부 생성기의 상수를 기준으로 삼는다. 템플릿에서 이 문구를
      // 바꾸면 치환이 조용히 아무것도 하지 않게 되는데, 상수끼리만 비교해서는
      // 그걸 잡지 못한다. 결합을 여기서 못박는다.
      expect(
        File(p.join(templateDir.path, 'lib', 'main.dart')).readAsStringSync(),
        contains("title: '${ProjectGenerator.templateDisplayName}'"),
        reason: '템플릿의 앱 타이틀이 바뀌었다. '
            'ProjectGenerator.templateDisplayName 도 같이 고쳐야 한다.',
      );
    });

    test('따옴표와 앰퍼샌드가 들어와도 dart 와 xml 이 깨지지 않는다', () async {
      // 'Ki's App' 은 컴파일되지 않고, android:label="A & B" 는 XML 이 아니다.
      final root = await generate(displayName: r"Ki's $A & B");

      expect(
        read(root, p.join('lib', 'main.dart')),
        contains(r"'Ki\'s \$A & B'"),
      );
      expect(
        read(root, p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')),
        contains('android:label="Ki\'s \$A &amp; B"'),
      );
      expect(
        read(root, p.join('ios', 'Runner', 'Info.plist')),
        contains('<string>Ki\'s \$A &amp; B</string>'),
      );
    });

    test('고르지 않은 플랫폼의 설정 파일을 찾지 못해도 실패하지 않는다', () async {
      final root = await generate(
        platforms: [ProjectPlatform.web],
        displayName: '내 가계부',
      );

      expect(read(root, p.join('lib', 'main.dart')), contains("'내 가계부'"));
    });
  });

  group('생성 전에 막는 것', () {
    test('형식이 틀린 입력은 flutter create 를 시작조차 하지 않는다', () {
      // 값 타입이 GenerationConfig 를 만드는 시점에 던지므로, 잘못된 입력으로는
      // 생성기에 도달할 방법 자체가 없다.
      for (final bad in ['My-App', '2fast', 'my app', '', 'class']) {
        expect(
          () => generate(name: bad),
          throwsA(isA<GenerationException>()),
          reason: '"$bad" 이 통과했다',
        );
      }
      expect(
        () => generate(org: 'nodots'),
        throwsA(isA<GenerationException>()),
      );
      expect(runner.invocations, isEmpty);
    });

    test('템플릿이 없으면 거부된다', () async {
      generator = ProjectGenerator(
        templateDir: Directory(p.join(outputParent.path, 'none')),
        processRunner: runner,
      );

      await expectLater(
        generate(),
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
