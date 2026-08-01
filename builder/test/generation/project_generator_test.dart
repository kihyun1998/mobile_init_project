import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/app_language.dart';
import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/generation_exception.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/generation/project_platform.dart';
import 'package:mobile_init_builder/src/generation/theme_css.dart';
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
    bool includeExample = true,
    List<AppLanguage> languages = const [AppLanguage.ko, AppLanguage.en],
    List<ProjectPlatform> platforms = const [
      ProjectPlatform.android,
      ProjectPlatform.ios,
    ],
    String themeCss = '',
  }) {
    return generator
        .generate(
          GenerationConfig(
            projectName: PackageName.parse(name),
            organization: Organization.parse(org),
            outputParent: outputParent,
            description: description,
            displayName: displayName,
            includeExample: includeExample,
            languages: LanguageSelection.of(languages),
            platforms: PlatformSelection.of(platforms),
            themeCss: ThemeCss.parseOrNull(themeCss),
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
      File(
        p.join(root.path, 'android', 'app', 'build.gradle.kts'),
      ).existsSync(),
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
        .where(
          (f) => _readTextOrNull(f)?.contains('mobile_init_project') ?? false,
        )
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
      await generate(platforms: [ProjectPlatform.web, ProjectPlatform.android]);

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
        read(
          root,
          p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'),
        ),
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
        read(
          root,
          p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'),
        ),
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
        reason:
            '템플릿의 앱 타이틀이 바뀌었다. '
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
        read(
          root,
          p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'),
        ),
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

  group('예제 포함 여부', () {
    test('켜면 예제와 차트 의존성이 그대로 온다', () async {
      final root = await generate();

      expect(
        Directory(p.join(root.path, 'lib', 'example')).existsSync(),
        isTrue,
      );
      expect(read(root, 'pubspec.yaml'), contains('fl_chart:'));
      expect(
        read(root, p.join('lib', 'ui', 'screens', 'home', 'home_screen.dart')),
        contains('ShadcnComponentsPage'),
      );
    });

    test('끄면 예제 디렉토리가 없다', () async {
      final root = await generate(includeExample: false);

      expect(
        Directory(p.join(root.path, 'lib', 'example')).existsSync(),
        isFalse,
      );
    });

    test('끄면 홈 화면이 예제를 참조하지 않는 빈 스텁이 된다', () async {
      final root = await generate(includeExample: false);
      final home = read(
        root,
        p.join('lib', 'ui', 'screens', 'home', 'home_screen.dart'),
      );

      // 예제를 지웠는데 import 가 남으면 컴파일되지 않는다.
      expect(home, isNot(contains('example/')));
      expect(home, isNot(contains('ShadcnComponentsPage')));
      expect(home, contains('class HomeScreen extends StatelessWidget'));
      // 스텁이 템플릿 API 를 끌어들이면 그 API 가 바뀔 때 조용히 낡는다.
      expect(
        RegExp(
          r"^import .*$",
          multiLine: true,
        ).allMatches(home).map((m) => m.group(0)),
        ["import 'package:flutter/material.dart';"],
      );
    });

    test('끄면 예제를 가리키는 참조가 결과물 어디에도 남지 않는다', () async {
      final root = await generate(includeExample: false);

      // home_screen.dart 만 보면 안 된다. 나중에 템플릿의 다른 파일이 예제를
      // import 하면, 컴파일되지 않는 프로젝트가 조용히 나오고 테스트는 전부
      // 초록으로 남는다.
      final offenders = root
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => (f, _readTextOrNull(f) ?? ''))
          .where(
            (e) =>
                e.$2.contains('ShadcnComponentsPage') ||
                e.$2.contains('example/') ||
                e.$2.contains('fl_chart'),
          )
          .map((e) => p.relative(e.$1.path, from: root.path))
          .toList();

      expect(offenders, isEmpty);
    });

    test('끄면 예제 전용 차트 의존성이 pubspec 에서 빠진다', () async {
      final pubspec = read(
        await generate(includeExample: false),
        'pubspec.yaml',
      );

      expect(pubspec, isNot(contains('fl_chart')));
      // 옆줄까지 쓸려나가면 안 된다.
      expect(pubspec, contains('shared_preferences:'));
      expect(pubspec, contains('flutter_riverpod:'));
      expect(pubspec, contains('dev_dependencies:'));
      // 의존성과 같은 들여쓰기를 쓰는 설정 블록들. 섹션을 안 보고 지우면
      // 여기가 같이 날아간다.
      expect(pubspec, contains('flutter_intl:'));
      expect(pubspec, contains('flutter_tweakcn_generator:'));
    });

    test('꺼도 shadcn 컴포넌트는 그대로 남는다', () async {
      final root = await generate(includeExample: false);
      final components = Directory(
        p.join(root.path, 'lib', 'ui', 'components'),
      );

      expect(components.existsSync(), isTrue);
      expect(
        components.listSync().whereType<File>(),
        isNotEmpty,
        reason: '아무도 참조하지 않아도 꺼내 쓸 수 있게 남겨둬야 한다',
      );
    });

    test('생성기가 쓰는 홈 화면 모양이 템플릿과 어긋나지 않는다', () async {
      // 스텁은 문자열이라 컴파일러가 봐주지 않는다. 템플릿의 홈 화면이
      // ConsumerWidget 이 되거나 인자를 받게 되면 AppTab 의 `const HomeScreen()`
      // 과 스텁이 어긋나는데, 그건 생성한 뒤에야 드러난다. 여기서 못박는다.
      final templateHome = File(
        p.joinAll([templateDir.path, ...ProjectGenerator.homeScreenSegments]),
      ).readAsStringSync();

      for (final shape in [
        'class HomeScreen extends StatelessWidget',
        'const HomeScreen({super.key});',
      ]) {
        expect(
          templateHome,
          contains(shape),
          reason:
              '템플릿 홈 화면이 바뀌었다. '
              'ProjectGenerator.emptyHomeScreenSource 도 같이 고쳐야 한다.',
        );
        expect(ProjectGenerator.emptyHomeScreenSource, contains(shape));
      }
    });

    test('예제에서만 쓰는 의존성이라고 적어둔 것이 실제로 예제에서만 쓰인다', () {
      // 템플릿이 이 이름을 더 이상 선언하지 않으면 제거는 조용한 no-op 이
      // 되고, 목록만 낡은 채로 남는다.
      final pubspec = File(
        p.join(templateDir.path, 'pubspec.yaml'),
      ).readAsStringSync();
      for (final name in ProjectGenerator.exampleOnlyDependencies) {
        expect(
          pubspec,
          contains('  $name:'),
          reason: '템플릿이 $name 을 더 이상 쓰지 않는다면 목록에서 빼야 한다.',
        );
      }

      // 다른 데서도 쓰는 패키지를 이 목록에 넣으면 결과물이 컴파일되지 않는다.
      final users = Directory(p.join(templateDir.path, 'lib'))
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.dart')
          .where(
            (f) => ProjectGenerator.exampleOnlyDependencies.any(
              (d) => f.readAsStringSync().contains('package:$d/'),
            ),
          )
          .map((f) => p.relative(f.path, from: templateDir.path));

      expect(users, everyElement(startsWith(p.joinAll(['lib', 'example']))));
    });
  });

  group('지원 언어', () {
    String arb(String code) =>
        p.joinAll([...ProjectGenerator.arbDirSegments, 'intl_$code.arb']);

    test('둘 다 고르면 둘 다 남는다', () async {
      final root = await generate();

      expect(File(p.join(root.path, arb('ko'))).existsSync(), isTrue);
      expect(File(p.join(root.path, arb('en'))).existsSync(), isTrue);
    });

    test('고르지 않은 언어의 번역 원본이 없다', () async {
      final root = await generate(languages: [AppLanguage.ko]);

      expect(File(p.join(root.path, arb('ko'))).existsSync(), isTrue);
      expect(File(p.join(root.path, arb('en'))).existsSync(), isFalse);
    });

    test('main_locale 이 고른 언어를 가리킨다', () async {
      // 이걸 빼먹으면 intl_utils 가 기본값 en 을 찾다가 없는 intl_en.arb 를
      // 빈 파일로 새로 만들고, 번역이 하나도 없는 S 를 생성한다.
      final pubspec = read(
        await generate(languages: [AppLanguage.ko]),
        'pubspec.yaml',
      );

      expect(pubspec, contains('main_locale: ko'));
      expect(
        RegExp(r'^\s+main_locale:', multiLine: true).allMatches(pubspec),
        hasLength(1),
        reason: 'main_locale 이 여러 번 적히면 뒤엣것만 먹는다',
      );
    });

    test('main_locale 은 flutter_intl 블록 안에 들어간다', () async {
      final pubspec = read(
        await generate(languages: [AppLanguage.en]),
        'pubspec.yaml',
      );
      final lines = pubspec.split('\n');
      final header = lines.indexWhere((l) => l.trimRight() == 'flutter_intl:');
      final entry = lines.indexWhere((l) => l.contains('main_locale: en'));

      expect(header, greaterThanOrEqualTo(0));
      expect(entry, greaterThan(header));
      // 블록이 끝나기 전이어야 한다.
      expect(
        lines
            .sublist(header + 1, entry)
            .every((l) => l.trim().isEmpty || l.startsWith(' ')),
        isTrue,
      );
    });

    test('블록 안의 다른 설정은 건드리지 않는다', () async {
      final pubspec = read(
        await generate(languages: [AppLanguage.en]),
        'pubspec.yaml',
      );

      expect(pubspec, contains('arb_dir:'));
      expect(pubspec, contains('output_dir:'));
    });

    test('템플릿에 flutter_intl 블록이 실제로 있다', () {
      // 블록을 못 찾으면 withMainLocale 은 조용히 아무것도 하지 않는다.
      // 이름이 바뀌거나 사라지면 결과물이 컴파일되지 않는데 아무 소리가 없다.
      expect(
        File(p.join(templateDir.path, 'pubspec.yaml')).readAsStringSync(),
        contains('\nflutter_intl:'),
      );
    });

    test('두 언어의 arb 가 같은 키를 갖는다', () {
      // main_locale 이 가리키는 arb 가 S 의 API 면을 정한다. 키가 어긋나면
      // 어느 언어를 고르냐에 따라 없는 메서드가 생긴다.
      Set<String> keysOf(String code) {
        final raw = File(
          p.joinAll([
            templateDir.path,
            ...ProjectGenerator.arbDirSegments,
            'intl_$code.arb',
          ]),
        ).readAsStringSync();
        return (jsonDecode(raw) as Map<String, dynamic>).keys
            .where((k) => !k.startsWith('@'))
            .toSet();
      }

      expect(keysOf('ko'), keysOf('en'));
    });

    group('main_locale 써넣기', () {
      const block = '''
name: x

flutter_intl:
  enabled: true
  arb_dir: lib/l10n

flutter:
  uses-material-design: true
''';

      test('없으면 블록 안에 넣는다', () {
        final out = ProjectGenerator.withMainLocale(block, 'ko');

        expect(out, contains('  main_locale: ko'));
        expect(out, contains('  enabled: true'));
        expect(out, contains('  arb_dir: lib/l10n'));
        final lines = out.split('\n');
        final header = lines.indexOf('flutter_intl:');
        final entry = lines.indexWhere((l) => l.contains('main_locale'));
        expect(entry, greaterThan(header));
        expect(lines.indexOf('flutter:'), greaterThan(entry));
      });

      test('있으면 바꾼다 — 늘어나지 않는다', () {
        final once = ProjectGenerator.withMainLocale(block, 'ko');
        final twice = ProjectGenerator.withMainLocale(once, 'en');

        expect(twice, contains('  main_locale: en'));
        expect(twice, isNot(contains('main_locale: ko')));
        expect(
          RegExp(r'main_locale', multiLine: true).allMatches(twice),
          hasLength(1),
        );
      });

      test('다른 블록의 같은 이름은 건드리지 않는다', () {
        const other = '''
flutter_intl:
  enabled: true

flutter_tweakcn_generator:
  main_locale: 건드리지마
''';
        final out = ProjectGenerator.withMainLocale(other, 'ko');

        expect(out, contains('  main_locale: 건드리지마'));
        expect(out, contains('  main_locale: ko'));
      });

      test('블록이 없으면 아무것도 하지 않는다', () {
        const none = 'name: x\n';
        expect(ProjectGenerator.withMainLocale(none, 'ko'), none);
      });
    });

    test('l10n 생성물을 손으로 건드리지 않는다', () async {
      final root = await generate(languages: [AppLanguage.ko]);

      // 복사된 그대로 남아 있어야 한다. 여기서 손으로 지우거나 고치면
      // "생성 파일을 직접 편집하지 않는다" 가 깨지고, 재생성이 실패했을 때
      // 그 사실이 가려진다.
      //
      // 실제로 언어가 줄어드는 건 후처리의 intl_utils:generate 다. 가짜
      // 러너는 그걸 돌리지 않으므로 여기서는 검사할 수 없다 —
      // tool/smoke_generate.dart 가 진짜로 돌려보고 확인한다.
      final generated = File(
        p.join(
          root.path,
          'lib',
          'core',
          'localization',
          'generated',
          'l10n.dart',
        ),
      );

      expect(generated.existsSync(), isTrue);
      expect(
        generated.readAsStringSync(),
        File(
          p.joinAll([
            templateDir.path,
            'lib',
            'core',
            'localization',
            'generated',
            'l10n.dart',
          ]),
        ).readAsStringSync(),
      );
    });

    test('하나도 고르지 않으면 만들 수 없다', () {
      expect(
        () => LanguageSelection.of(const []),
        throwsA(isA<GenerationException>()),
      );
    });

    test('고른 순서와 무관하게 main_locale 이 같다', () {
      expect(
        LanguageSelection.of([AppLanguage.en, AppLanguage.ko]).main,
        AppLanguage.ko,
      );
      expect(
        LanguageSelection.of([AppLanguage.ko, AppLanguage.en]).main,
        AppLanguage.ko,
      );
    });

    test('템플릿이 실제로 가진 arb 가 고를 수 있는 언어와 일치한다', () {
      // 템플릿에 언어가 하나 늘었는데 AppLanguage 에 없으면, 그 arb 는
      // 어떻게 골라도 지워진다. 반대로 목록에만 있으면 고를 수는 있는데
      // 아무 효과가 없다.
      final onDisk =
          Directory(
                p.joinAll([
                  templateDir.path,
                  ...ProjectGenerator.arbDirSegments,
                ]),
              )
              .listSync()
              .whereType<File>()
              .where((f) => p.extension(f.path) == '.arb')
              .map((f) => p.basenameWithoutExtension(f.path).split('_').last)
              .toSet();

      expect(onDisk, AppLanguage.values.map((l) => l.code).toSet());
    });
  });

  group('테마 CSS', () {
    /// 템플릿 CSS 에는 없는 값이라야 "덮어썼다" 를 구분할 수 있다.
    const pasted = ':root { --primary: #FF0000; --background: #00FF00; }';

    test('붙여넣은 CSS 가 결과물의 테마 소스가 된다', () async {
      final root = await generate(themeCss: pasted);

      expect(read(root, ProjectGenerator.themeCssEntry), pasted);
    });

    test('붙여넣지 않으면 템플릿의 CSS 가 그대로 남는다', () async {
      final root = await generate();

      expect(
        read(root, ProjectGenerator.themeCssEntry),
        File(
          p.join(templateDir.path, ProjectGenerator.themeCssEntry),
        ).readAsStringSync(),
      );
    });

    test('복사해온 옛 테마 CSS 가 남지 않는다', () async {
      final root = await generate(themeCss: pasted);
      final onDisk = read(root, ProjectGenerator.themeCssEntry);

      // 템플릿 CSS 의 지문. 덮어쓰기가 아니라 이어붙이기를 했다면 살아남는다.
      expect(onDisk, isNot(contains('oklch')));
      expect(onDisk, isNot(contains('--sidebar-ring')));
    });

    /// 상수가 템플릿 pubspec 의 `input:` 과 갈리면, 생성기는 아무도 읽지 않는
    /// 파일에 CSS 를 쓰고 결과물은 옛 테마로 나온다. 증상이 조용해서 여기서
    /// 시끄럽게 깬다.
    test('CSS 파일 이름이 템플릿 pubspec 의 input 과 같다', () {
      final pubspec = File(
        p.join(templateDir.path, 'pubspec.yaml'),
      ).readAsStringSync();

      final input = RegExp(
        r'^flutter_tweakcn_generator:\n(?:.*\n)*?\s+input:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec)?.group(1);

      expect(
        input,
        ProjectGenerator.themeCssEntry,
        reason: '템플릿이 읽는 CSS 경로가 바뀌었는데 생성기 상수가 따라가지 않았다',
      );
    });

    test('CSS 파일이 복사 목록에도 들어 있다', () {
      // 붙여넣지 않았을 때 템플릿 것이 넘어가는 경로가 여기다.
      expect(
        ProjectGenerator.copyEntries,
        contains(ProjectGenerator.themeCssEntry),
      );
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

      await expectLater(generate(), throwsA(isA<GenerationException>()));
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
