import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_language.dart';
import 'generation_config.dart';
import 'generation_event.dart';
import 'generation_exception.dart';
import 'generation_result.dart';
import 'process_runner.dart';

export 'generation_result.dart';

/// `flutter create` 로 새 프로젝트를 만든 뒤 그 위에 템플릿을 얹는다.
///
/// 플랫폼 폴더를 flutter 에게 맡기는 것이 이 도구의 핵심이다. 그래야 새
/// 프로젝트의 android/ios 스캐폴드가 설치된 Flutter 기준으로 항상 최신이고,
/// 패키지명과 번들 ID 가 처음부터 제대로 박힌다.
class ProjectGenerator {
  ProjectGenerator({required this.templateDir, required this.processRunner});

  final Directory templateDir;
  final ProcessRunner processRunner;

  /// 템플릿에서 새 프로젝트로 옮길 것.
  ///
  /// **blocklist 가 아니라 allowlist 여야 한다.** 빠뜨리면 결과물이 컴파일되지
  /// 않아 즉시 드러나지만, blocklist 에서 빠뜨린 항목은 조용히 통과해서
  /// 플랫폼 스캐폴드를 낡은 것으로 덮어써버린다.
  static const copyEntries = <String>[
    'lib',
    'test',
    'assets',
    'pubspec.yaml',
    'tweakcn.css',
    'analysis_options.yaml',
  ];

  /// 템플릿 패키지 이름. 결과물에서 이 참조가 남으면 컴파일되지 않는다.
  static const templatePackageName = 'mobile_init_project';

  /// 템플릿 `main.dart` 의 `MaterialApp(title:)`. 표시 이름으로 갈아끼운다.
  ///
  /// 패키지 이름과 달리 남아 있어도 컴파일은 되므로 조용히 넘어간다.
  /// 템플릿에서 이 문구를 바꾸면 여기도 같이 바꿔야 한다.
  static const templateDisplayName = 'Mobile Init Project';

  /// 치환 대상으로 볼 텍스트 확장자. 그 외(이미지 등)는 건드리지 않는다.
  static const _textExtensions = {'.dart', '.yaml', '.arb', '.md'};

  /// 새 프로젝트를 만들고 바로 쓸 수 있는 상태까지 만든다.
  ///
  /// **쓸 프로젝트가 없으면 던지고, 있는데 덜 됐으면 결과로 돌려준다.**
  /// 입력이 틀렸거나 `flutter create` 가 실패하면 예외다. 후처리가 실패하면
  /// 프로젝트는 남겨둔 채 어느 단계에서 왜 실패했는지를 결과에 담는다.
  Future<GenerationResult> generate(
    GenerationConfig config, {
    void Function(GenerationEvent)? onEvent,
  }) async {
    void emit(GenerationEvent e) => onEvent?.call(e);

    _validate(config);

    emit(const GenerationStepStarted(GenerationStep.scaffold));
    await _runFlutterCreate(config, emit);

    final projectRoot = _targetDirectory(config);
    if (!projectRoot.existsSync()) {
      throw GenerationException(
        'flutter create 는 성공했다고 했는데 ${projectRoot.path} 가 없습니다.',
      );
    }

    emit(const GenerationStepStarted(GenerationStep.applyTemplate));
    // 복사는 동기라 그대로 진행하면 이 단계 표시가 화면에 뜰 틈이 없다.
    // 한 프레임 양보해서 사용자가 무슨 일이 일어나는지 볼 수 있게 한다.
    await Future<void>.delayed(Duration.zero);

    final preserved = _capturePreservedLines(projectRoot);
    _copyTemplate(projectRoot);
    // 예제를 먼저 걷어낸다. 그래야 pubspec 에서 의존성이 빠진 뒤에
    // 이름·설명이 다시 쓰이고, 치환이 어차피 지울 파일을 훑지 않는다.
    if (!config.includeExample) _dropExample(projectRoot);
    _applyLanguages(projectRoot, config.languages);
    _rewriteReferences(projectRoot, config, preserved);
    _applyDisplayName(projectRoot, config.displayName);

    return _runPostProcessing(projectRoot, emit);
  }

  /// 복사가 끝난 프로젝트를 `flutter run` 가능한 상태로 만든다.
  ///
  /// 순서가 중요하다. 의존성이 없으면 나머지가 아예 돌지 않고, 코드 생성은
  /// l10n 생성물을 입력으로 삼으므로 그 뒤여야 한다.
  static const _postProcessing = <(GenerationStep, String, List<String>)>[
    (GenerationStep.dependencies, 'flutter', ['pub', 'get']),
    (GenerationStep.localization, 'dart', ['run', 'intl_utils:generate']),
    (
      GenerationStep.codegen,
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    ),
  ];

  Future<GenerationResult> _runPostProcessing(
    Directory projectRoot,
    void Function(GenerationEvent) emit,
  ) async {
    for (final (step, executable, arguments) in _postProcessing) {
      emit(GenerationStepStarted(step));

      final result = await processRunner.run(
        executable,
        arguments,
        workingDirectory: projectRoot.path,
        onOutput: (line) => emit(GenerationOutput(line)),
      );

      if (!result.succeeded) {
        // 한 단계가 실패하면 뒤는 어차피 실패한다. 여기서 멈추되 만들어진
        // 프로젝트는 남긴다 — 사용자가 남은 명령을 직접 이어 돌릴 수 있다.
        return GenerationResult(
          projectRoot: projectRoot,
          failedStep: step,
          failureMessage:
              '$executable ${arguments.join(' ')} 이(가) 실패했습니다 '
              '(exit ${result.exitCode}).\n${result.failureOutput}',
        );
      }
    }

    return GenerationResult(projectRoot: projectRoot);
  }

  /// 파일시스템에 의존하는 검증만 남는다. 이름과 org 의 형식은 값 타입이
  /// 이미 보증했으므로 여기서 다시 볼 것이 없다.
  void _validate(GenerationConfig config) {
    if (!templateDir.existsSync()) {
      throw GenerationException('템플릿을 찾을 수 없습니다: ${templateDir.path}');
    }
    if (!config.outputParent.existsSync()) {
      throw GenerationException('출력 폴더가 없습니다: ${config.outputParent.path}');
    }

    final target = _targetDirectory(config);
    if (target.existsSync() || File(target.path).existsSync()) {
      throw GenerationException(
        '${target.path} 가 이미 있습니다. 기존 작업을 덮어쓰지 않기 위해 중단합니다.',
      );
    }
  }

  Directory _targetDirectory(GenerationConfig config) =>
      Directory(p.join(config.outputParent.path, config.projectName.value));

  Future<void> _runFlutterCreate(
    GenerationConfig config,
    void Function(GenerationEvent) emit,
  ) async {
    final result = await processRunner.run(
      'flutter',
      [
        'create',
        '--org',
        config.organization.value,
        '--project-name',
        config.projectName.value,
        '--platforms=${config.platforms.flags}',
        config.projectName.value,
      ],
      workingDirectory: config.outputParent.path,
      onOutput: (line) => emit(GenerationOutput(line)),
    );

    if (!result.succeeded) {
      throw GenerationException(
        'flutter create 가 실패했습니다 (exit ${result.exitCode}).\n'
        '${result.stderr.isEmpty ? result.stdout : result.stderr}',
      );
    }
  }

  /// 버전은 flutter create 가 정한 것을 따른다.
  ///
  /// 템플릿 pubspec 이 얹히기 전에 읽어둔다. 이름과 설명은 사용자가 입력하지만
  /// 버전은 받지 않으므로, 템플릿 값을 물려받는 대신 새 프로젝트의 것을 쓴다.
  static const _preservedPrefixes = ['version:'];

  Map<String, String> _capturePreservedLines(Directory projectRoot) {
    final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return const {};

    return {
      for (final line in pubspec.readAsLinesSync())
        for (final prefix in _preservedPrefixes)
          if (line.startsWith(prefix)) prefix: line,
    };
  }

  void _copyTemplate(Directory projectRoot) {
    for (final entry in copyEntries) {
      final source = p.join(templateDir.path, entry);
      final target = p.join(projectRoot.path, entry);

      if (Directory(source).existsSync()) {
        // 디렉토리는 통째로 갈아끼운다. flutter create 가 남긴 잔여 파일이
        // 템플릿 안에 대응물이 없다는 이유로 살아남으면 안 된다.
        final targetDir = Directory(target);
        if (targetDir.existsSync()) targetDir.deleteSync(recursive: true);
        _copyDirectory(Directory(source), targetDir);
      } else if (File(source).existsSync()) {
        File(source).copySync(target);
      }
      // 템플릿에 없는 항목(예: 빈 assets/ 는 git 이 추적하지 않는다)은 건너뛴다.
    }
  }

  void _copyDirectory(Directory source, Directory target) {
    target.createSync(recursive: true);
    for (final entity in source.listSync()) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        _copyDirectory(entity, Directory(p.join(target.path, name)));
      } else if (entity is File) {
        entity.copySync(p.join(target.path, name));
      }
    }
  }

  void _rewriteReferences(
    Directory projectRoot,
    GenerationConfig config,
    Map<String, String> preserved,
  ) {
    _rewritePubspec(projectRoot, config, preserved);

    // 템플릿 안의 절대 참조는 두 곳뿐이지만, 새 파일이 늘어나면 조용히 깨지므로
    // 개수를 가정하지 않고 전부 훑는다.
    for (final file
        in projectRoot.listSync(recursive: true).whereType<File>()) {
      if (!_textExtensions.contains(p.extension(file.path))) continue;
      if (p.basename(file.path) == 'pubspec.yaml') continue;

      final content = file.readAsStringSync();
      if (!content.contains(templatePackageName)) continue;
      file.writeAsStringSync(
        content.replaceAll(
          'package:$templatePackageName/',
          'package:${config.projectName.value}/',
        ),
      );
    }
  }

  void _rewritePubspec(
    Directory projectRoot,
    GenerationConfig config,
    Map<String, String> preserved,
  ) {
    final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));

    final rewritten = pubspec.readAsLinesSync().map((line) {
      if (line.startsWith('name:')) return 'name: ${config.projectName.value}';
      if (line.startsWith('description:')) {
        return 'description: ${_quote(config.description)}';
      }
      for (final entry in preserved.entries) {
        if (line.startsWith(entry.key)) return entry.value;
      }
      return line;
    }).toList();

    pubspec.writeAsStringSync('${rewritten.join('\n')}\n');
  }

  /// 예제 페이지가 차지하던 자리.
  ///
  /// 경로는 조각으로 들고 있다가 [p.joinAll] 로 잇는다. Windows 에서도
  /// 돌아야 해서 `/` 를 박은 문자열을 쓰지 않는다.
  static const exampleDirSegments = ['lib', 'example'];
  static const homeScreenSegments = [
    'lib',
    'ui',
    'screens',
    'home',
    'home_screen.dart',
  ];

  /// 예제 페이지에서만 쓰는 의존성. 예제를 끄면 같이 빠져야 한다 —
  /// 안 쓰는 패키지를 이고 시작하지 않도록.
  static const exampleOnlyDependencies = {'fl_chart'};

  /// 예제를 껐을 때 홈 화면 자리에 들어갈 것.
  ///
  /// **`package:flutter/material.dart` 말고는 아무것도 import 하지 않는다.**
  /// 여기서 템플릿 API 를 쓰면 그 API 가 바뀔 때 이 문자열만 조용히 낡는다.
  /// 화면이 비어 보이는 건 의도다 — 여기서부터 짜기 시작하라는 자리다.
  ///
  /// 그래도 [homeScreenSegments] 의 클래스 이름과 생성자 모양에는 묶여 있다
  /// (`AppTab` 이 `const HomeScreen()` 으로 부른다). 컴파일러가 문자열을
  /// 봐주지 않으므로 그 결합은 테스트로 못박아 뒀다.
  static const emptyHomeScreenSource = '''
import 'package:flutter/material.dart';

/// 여기서부터 시작하면 된다.
///
/// 컴포넌트가 필요하면 `lib/ui/components/` 에 shadcn 13종이 그대로 있다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
''';

  /// 예제를 끌 때 함께 움직이는 세 가지.
  ///
  /// 하나라도 빠지면 결과물이 깨지거나(예제를 지웠는데 홈 화면이 그걸
  /// import 한 채로 남는다) 안 쓰는 패키지를 이고 시작한다. 그래서 셋을
  /// 떼어놓지 않고 한 함수에 묶어둔다.
  void _dropExample(Directory projectRoot) {
    final exampleDir = Directory(
      p.joinAll([projectRoot.path, ...exampleDirSegments]),
    );
    if (exampleDir.existsSync()) exampleDir.deleteSync(recursive: true);

    File(
      p.joinAll([projectRoot.path, ...homeScreenSegments]),
    ).writeAsStringSync(emptyHomeScreenSource);

    _rewriteIfPresent(
      File(p.join(projectRoot.path, 'pubspec.yaml')),
      (yaml) => _withoutDependencies(yaml, exampleOnlyDependencies),
    );
  }

  /// pubspec 의 의존성 섹션에서 항목을 지운다.
  ///
  /// **의존성 섹션 안에서만 지운다.** pubspec 에는 `flutter:`,
  /// `flutter_intl:`, `flutter_tweakcn_generator:` 처럼 같은 들여쓰기를 쓰는
  /// 설정 블록이 여럿 있어서, 섹션을 안 보고 이름만 맞추면 엉뚱한 설정이
  /// 사라진다.
  ///
  /// 항목은 두 칸 들여쓴 `  이름:` 이고, 그보다 더 들여쓴 줄은 그 항목에
  /// 딸린 것이다(`  fl_chart:\n    version: ...`). 딸린 줄까지 같이 지워야
  /// 고아 블록이 남지 않는다.
  static String _withoutDependencies(String yaml, Set<String> names) {
    const dependencySections = {'dependencies:', 'dev_dependencies:'};

    final kept = <String>[];
    var inDependencies = false;
    var dropping = false;

    for (final line in yaml.split('\n')) {
      if (line.trim().isEmpty) {
        // 빈 줄은 어느 항목에도 딸려 있지 않다. 같이 지우면 섹션이 붙어버린다.
        dropping = false;
      } else if (!line.startsWith(' ')) {
        // 들여쓰지 않은 줄에서 섹션이 바뀐다.
        inDependencies = dependencySections.contains(line.trim());
        dropping = false;
      } else if (!inDependencies) {
        dropping = false;
      } else {
        final entry = RegExp(r'^  ([A-Za-z_][A-Za-z0-9_]*):').firstMatch(line);
        if (entry != null) {
          dropping = names.contains(entry.group(1));
        } else if (!line.startsWith('   ')) {
          // 들여쓰기가 얕아졌다 = 항목이 끝났다.
          dropping = false;
        }
        // 더 깊이 들여쓴 줄은 앞 항목에 딸린 것이라 상태를 그대로 둔다.
      }
      if (!dropping) kept.add(line);
    }

    return kept.join('\n');
  }

  /// 번역 원본이 있는 자리.
  static const arbDirSegments = ['lib', 'core', 'localization', 'l10n'];

  /// 고르지 않은 언어를 걷어낸다.
  ///
  /// **생성물은 손대지 않는다.** 번역 원본만 지우고 `main_locale` 을 맞춰두면,
  /// 후처리의 `intl_utils:generate` 가 l10n 을 통째로 다시 만들면서 고아가 된
  /// `messages_<code>.dart` 까지 알아서 지운다.
  void _applyLanguages(Directory projectRoot, LanguageSelection languages) {
    final arbDir = Directory(p.joinAll([projectRoot.path, ...arbDirSegments]));
    if (arbDir.existsSync()) {
      final keep = languages.languages
          .map((language) => 'intl_${language.code}.arb')
          .toSet();

      for (final file in arbDir.listSync().whereType<File>()) {
        if (p.extension(file.path) != '.arb') continue;
        if (!keep.contains(p.basename(file.path))) file.deleteSync();
      }
    }

    _rewriteIfPresent(
      File(p.join(projectRoot.path, 'pubspec.yaml')),
      (yaml) => withMainLocale(yaml, languages.main.code),
    );
  }

  /// `flutter_intl:` 블록의 `main_locale` 을 [code] 로 맞춘다.
  ///
  /// 없으면 넣고, 있으면 바꾼다. 빼먹으면 기본값 `en` 이 쓰이는데, 영어를
  /// 고르지 않았다면 `intl_utils` 가 없는 `intl_en.arb` 를 **빈 파일로 새로
  /// 만들고** 번역이 하나도 없는 `S` 를 생성한다. 결과물이 컴파일되지 않는다.
  ///
  /// 공개해 둔 이유는 테스트가 직접 부르기 위해서다. 생성기를 통해서는
  /// 템플릿 pubspec 이 가진 모양 하나만 지나가므로 나머지 갈래가 덮이지 않는다.
  static String withMainLocale(String yaml, String code) {
    const entry = 'main_locale';

    final lines = yaml.split('\n');
    final header = lines.indexWhere((l) => l.trimRight() == 'flutter_intl:');
    if (header < 0) return yaml;

    final end = _blockEnd(lines, header);

    final block = <String>[];
    var written = false;
    for (final line in lines.sublist(header + 1, end)) {
      if (RegExp('^\\s+$entry\\s*:').hasMatch(line)) {
        if (!written) {
          block.add('  $entry: $code');
          written = true;
        }
        continue;
      }
      block.add(line);
    }
    if (!written) block.insert(0, '  $entry: $code');

    return [
      ...lines.sublist(0, header + 1),
      ...block,
      ...lines.sublist(end),
    ].join('\n');
  }

  /// [header] 로 시작하는 최상위 항목이 끝나는 줄 번호.
  ///
  /// 들여쓴 줄과 빈 줄은 그 항목에 딸린 것으로 본다. 들여쓰지 않은 줄이
  /// 나오면 거기서 끝이다.
  static int _blockEnd(List<String> lines, int header) {
    var end = header + 1;
    while (end < lines.length &&
        (lines[end].trim().isEmpty || lines[end].startsWith(' '))) {
      end++;
    }
    return end;
  }

  /// 표시 이름을 사람이 보는 세 자리에 넣는다.
  ///
  /// 자리마다 문법이 달라서 한 번의 문자열 치환으로 밀 수 없다. `title: 'Ki's
  /// App'` 은 컴파일되지 않고, `android:label="A & B"` 는 XML 이 아니다.
  /// 넣는 곳의 규칙대로 각각 이스케이프한다.
  ///
  /// 고르지 않은 플랫폼의 설정 파일은 아예 없으므로 조용히 건너뛴다.
  void _applyDisplayName(Directory projectRoot, String displayName) {
    _rewriteDartTitle(projectRoot, displayName);
    _rewriteAndroidLabel(projectRoot, displayName);
    _rewriteIosDisplayName(projectRoot, displayName);
  }

  /// `MaterialApp(title: '...')`. 템플릿에는 main.dart 한 곳뿐이지만
  /// 늘어나도 따라가도록 복사된 dart 파일을 전부 훑는다.
  void _rewriteDartTitle(Directory projectRoot, String displayName) {
    final quoted = "'${_escapeDartLiteral(displayName)}'";

    for (final file in Directory(
      p.join(projectRoot.path, 'lib'),
    ).listSync(recursive: true).whereType<File>()) {
      if (p.extension(file.path) != '.dart') continue;

      final content = file.readAsStringSync();
      if (!content.contains("'$templateDisplayName'")) continue;
      file.writeAsStringSync(
        content.replaceAll("'$templateDisplayName'", quoted),
      );
    }
  }

  void _rewriteAndroidLabel(Directory projectRoot, String displayName) {
    final manifest = File(
      p.join(
        projectRoot.path,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ),
    );
    // flutter create 는 `android:label` 을 `<application>` 에만 붙이고 그게
    // 파일에서 처음 나온다. 나중에 액티비티 라벨이 생겨도 건드리지 않도록
    // 첫 번째만 바꾼다.
    _rewriteIfPresent(
      manifest,
      (xml) => xml.replaceFirst(
        RegExp(r'android:label="[^"]*"'),
        'android:label="${_escapeXml(displayName)}"',
      ),
    );
  }

  void _rewriteIosDisplayName(Directory projectRoot, String displayName) {
    // plist 는 키와 값이 형제로 나란히 놓이는 구조라 키만으로는 값을 집을 수
    // 없다. 키 바로 뒤의 <string> 을 그 값으로 본다.
    _rewriteIfPresent(
      File(p.join(projectRoot.path, 'ios', 'Runner', 'Info.plist')),
      (xml) => xml.replaceAllMapped(
        RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
        (m) => '${m[1]}${_escapeXml(displayName)}${m[2]}',
      ),
    );
  }

  /// 고르지 않은 플랫폼의 설정 파일은 아예 없다. 없으면 조용히 넘어간다.
  static void _rewriteIfPresent(File file, String Function(String) rewrite) {
    if (!file.existsSync()) return;
    file.writeAsStringSync(rewrite(file.readAsStringSync()));
  }

  /// 큰따옴표로 감싼 XML 속성과 요소 안에 넣을 값. 작은따옴표는 두 자리 모두
  /// 구분자가 아니므로 건드리지 않는다.
  static String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll('\n', ' ');

  /// 작은따옴표 Dart 문자열 리터럴 안에 넣을 값. `$` 는 그냥 두면 보간이 된다.
  static String _escapeDartLiteral(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll(r'$', r'\$')
      .replaceAll("'", r"\'")
      .replaceAll('\n', ' ');

  /// 설명은 사용자가 자유롭게 쓰는 한 줄이라 따옴표와 줄바꿈이 들어올 수 있다.
  /// 그대로 넣으면 pubspec 이 깨지므로 큰따옴표 문자열로 감싼다.
  static String _quote(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', ' ')
        .trim();
    return '"$escaped"';
  }
}
