import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_language.dart';
import 'generation_config.dart';
import 'generation_event.dart';
import 'generation_exception.dart';
import 'generation_result.dart';
import 'process_runner.dart';
import 'theme_css.dart';

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
  ///
  /// **`fonts/` 가 여기 없는 것은 알고 있는 구멍이다** — 그리고 위의 "빠뜨리면
  /// 즉시 드러난다" 가 유일하게 통하지 않는 자리다. 템플릿 CSS 가 시스템
  /// 스택이라 지금은 `fonts/` 가 존재하지 않아 아무 일도 없다. 누군가 템플릿에
  /// 진짜 Google 폰트를 넣으면 테마 CLI 가 `fonts/*.ttf` 와 pubspec 의
  /// `flutter: fonts:` 블록을 만드는데(실측: Inter → .ttf 9개 + 21줄), pubspec 은
  /// 복사되고 `fonts/` 는 안 된다. 사용자가 **다른** 폰트를 붙여넣으면
  /// `font_exclusive: false` 라 옛 선언이 남아, 컴파일이 아니라 **에셋 번들에서**
  /// 죽는다. 템플릿에 폰트를 넣는 날 이 목록부터 고칠 것.
  static const copyEntries = <String>[
    'lib',
    'test',
    'assets',
    'pubspec.yaml',
    themeCssEntry,
    'analysis_options.yaml',
  ];

  /// 테마의 소스가 되는 CSS 파일. 붙여넣은 CSS 가 여기로 들어간다.
  ///
  /// **템플릿 `pubspec.yaml` 의 `flutter_tweakcn_generator: input:` 과 같은
  /// 값이어야 한다.** 갈리면 생성기는 아무도 읽지 않는 파일에 CSS 를 쓰고
  /// 결과물은 옛 테마로 나온다 — 컴파일은 되므로 조용하다. 그래서
  /// `project_generator_test.dart` 가 템플릿 pubspec 을 읽어 대조한다.
  static const themeCssEntry = 'tweakcn.css';

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
    // **옵션과 무관하게 돈다.** 예제를 끄는 길에 얹으면 켠 쪽이 안 덮이는데,
    // `includeExample` 의 기본값이 `true` 라 흔한 경로가 통째로 새 버린다.
    _rewriteIfPresent(
      File(p.join(projectRoot.path, 'pubspec.yaml')),
      withoutDependencyOverrides,
    );
    _applyThemeCss(projectRoot, config.themeCss);
    _applyLanguages(projectRoot, config.languages);
    _rewriteReferences(projectRoot, config, preserved);
    _applyDisplayName(projectRoot, config.displayName);

    return _runPostProcessing(projectRoot, emit);
  }

  /// 복사가 끝난 프로젝트를 `flutter run` 가능한 상태로 만든다.
  ///
  /// 순서가 중요하다. 의존성이 없으면 나머지가 아예 `dart run` 되지 않고, 코드
  /// 생성은 l10n 생성물을 입력으로 삼으므로 그 뒤여야 한다.
  ///
  /// **테마 생성은 `build_runner` 가 아니라 별도 CLI 다.** 상류 패키지의
  /// `build.yaml` 은 `.tweakcn.css` → `.tweakcn.dart` 만 걸고, pubspec 의
  /// `flutter_tweakcn_generator:` 블록(`input`/`output`)은 CLI 만 읽는다.
  /// 템플릿의 파일 이름은 `tweakcn.css` 라 builder 패턴에 애초에 걸리지 않는다.
  /// 이 단계를 빼면 `build_runner` 가 아무리 돌아도 **복사해온 옛 테마가 그대로
  /// 남는다** — 붙여넣은 CSS 는 파일로만 들어가고 화면에는 반영되지 않는다.
  /// 붙여넣지 않았을 때도 돌린다. 그래야 복사해온 생성물을 믿을 수 있다.
  ///
  /// **그리고 마지막이다.** 이 단계만 네트워크를 타고(Google Fonts), 폰트
  /// 조회 하나가 어긋나도 뒤가 통째로 건너뛰어지면 곤란하다. [_applyLanguages]
  /// 가 고아 `messages_*.dart` 를 `intl_utils` 에게 맡기고 있어서, 그렇게 되면
  /// 결과물이 **컴파일은 되면서** 고르지도 않은 언어를 이고 있게 된다. 뒤로
  /// 미뤄도 잃는 것은 없다 — `build_runner` 는 테마 파일을 입력으로 삼지 않는다
  /// (위의 `build.yaml` 이야기가 그대로 근거다).
  ///
  /// 순서를 이렇게 잡은 원래 이유는 **0.4.0 이 폰트 하나만 못 받아도 `1` 을
  /// 세워서 전면 실패와 구분되지 않았기** 때문이다. 0.5.0 이 그 둘을 갈라
  /// 놓았으므로(아래 [_PostProcessingStep.partialExitCode]) 그 이유는 이제
  /// 없다. 그래도 순서는 그대로 둔다 — 위 문단의 이유는 종료 코드와 무관하게
  /// 여전히 성립하고, 앞으로 옮겨서 얻는 것이 없다.
  static const _postProcessing = <_PostProcessingStep>[
    _PostProcessingStep(GenerationStep.dependencies, 'flutter', ['pub', 'get']),
    _PostProcessingStep(GenerationStep.localization, 'dart', [
      'run',
      'intl_utils:generate',
    ]),
    _PostProcessingStep(GenerationStep.codegen, 'dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ]),
    _PostProcessingStep(
      GenerationStep.theme,
      'dart',
      ['run', 'flutter_tweakcn_generator'],
      // 상류 0.5.0 의 계약: 0 = 그대로 쓸 수 있음, 1 = 아무것도 생성 안 됨,
      // 2 = 테마는 썼지만 필요한 것이 빠짐. 2 는 1 보다 나쁜 것이 아니라 다른
      // 범주이고, 결과물은 `flutter run` 이 된다.
      partialExitCode: 2,
    ),
  ];

  Future<GenerationResult> _runPostProcessing(
    Directory projectRoot,
    void Function(GenerationEvent) emit,
  ) async {
    final warnings = <String>[];

    for (final step in _postProcessing) {
      emit(GenerationStepStarted(step.step));

      final result = await processRunner.run(
        step.executable,
        step.arguments,
        workingDirectory: projectRoot.path,
        onOutput: (line) => emit(GenerationOutput(line)),
      );

      // **끊긴 것은 절대 부분 성공이 아니다.** 감시견이 끊은 프로세스의 종료
      // 코드는 신호값이라 우연히 [_PostProcessingStep.partialExitCode] 와
      // 같아질 수 있고, 그 경우 "덜 됐다" 가 아니라 "무슨 일이 일어났는지
      // 모른다" 가 맞다. 그래서 timedOut 을 먼저 배제한다.
      final partial =
          !result.timedOut && result.exitCode == step.partialExitCode;

      if (partial) {
        // 계속 진행한다 — 이 단계는 자기 몫을 했고, 뒤 단계가 그것에 기대지도
        // 않는다. 다만 조용히 넘기지 않는다.
        warnings.add(
          '${step.executable} ${step.arguments.join(' ')} 이(가) 덜 '
          '끝났습니다 (exit ${result.exitCode}). 프로젝트는 그대로 쓸 수 '
          '있습니다.\n${result.failureOutput}',
        );
        continue;
      }

      if (!result.succeeded) {
        // 한 단계가 실패하면 뒤는 어차피 실패한다. 여기서 멈추되 만들어진
        // 프로젝트는 남긴다 — 사용자가 남은 명령을 직접 이어 돌릴 수 있다.
        return GenerationResult(
          projectRoot: projectRoot,
          failedStep: step.step,
          failureMessage:
              '${step.executable} ${step.arguments.join(' ')} 이(가) '
              '실패했습니다 (exit ${result.exitCode}).\n${result.failureOutput}',
        );
      }
    }

    return GenerationResult(projectRoot: projectRoot, warnings: warnings);
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

    // 템플릿이 형제 저장소를 직접 물고 있으면 여기서 멈춘다. 복사해봐야
    // 그 상대 경로는 사용자 머신에 없고, 올바른 버전 제약을 빌더가 알 수
    // 없어서 고쳐줄 수도 없다. `flutter create` 보다 먼저라 아무것도
    // 만들어지지 않는다.
    final templatePubspec = File(p.join(templateDir.path, 'pubspec.yaml'));
    if (templatePubspec.existsSync()) {
      final local = machineLocalDependencies(
        templatePubspec.readAsStringSync(),
      );
      if (local.isNotEmpty) {
        throw GenerationException(
          '템플릿의 ${local.join(', ')} 가 로컬 경로(path/git)를 가리킵니다. '
          '그대로 복사하면 결과물의 flutter pub get 이 실패합니다. '
          '템플릿 pubspec 을 퍼블리시된 버전으로 되돌린 뒤 다시 시도하세요.',
        );
      }
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

  /// pubspec 의 `name:` / `description:` 과 보존 대상을 갈아끼운다.
  ///
  /// **전부 0열 매칭이고, 그것이 이 함수의 불변식이다.** 줄 단위 `map` 이라
  /// 섹션 상태가 없어도 되는 이유가 그것 하나다 — 섹션 본문의 줄은 YAML 이
  /// 강제로 들여쓰므로 여기 걸릴 수가 없다. `_preservedPrefixes` 에 들여쓴
  /// 접두사를 더하는 순간 그 불변식이 깨지는데, **아무것도 그것을 검사하지
  /// 않는다.**
  ///
  /// **알려진 구멍:** `description:` 은 **한 줄짜리만** 갈아끼운다. 템플릿이
  /// 접힌 스칼라(`description: >` 다음 줄들)로 바뀌면 헤더만 바뀌고 들여쓴
  /// 줄이 고아로 남아 YAML 이 깨진다. 지금 `template/pubspec.yaml` 이 한 줄
  /// 인용 문자열이라 도달 불가다.
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

  /// 예제 페이지를 물고 있는 테스트가 사는 자리.
  ///
  /// `copyEntries` 가 `test` 를 통째로 복사하므로, 예제를 끄면 이쪽도 같이
  /// 지워야 한다. 안 지우면 **지워진 파일을 import 하는 테스트가 남아 결과물이
  /// 컴파일되지 않는다** — `flutter analyze` 는 통과시키고 `flutter test` 에서만
  /// 터지므로 조용하다.
  ///
  /// `lib/example` 과 대칭이라는 것이 규칙이다. 예제에 의존하는 테스트는 이
  /// 폴더 안에 둔다. 밖에 두면 여기서 못 잡고, `project_generator_test.dart` 의
  /// "예제를 가리키는 참조가 남지 않는다" 가 뒤늦게 잡아준다.
  static const exampleTestDirSegments = ['test', 'example'];
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
  ///
  /// **여기에 컴포넌트 개수를 적지 않는다** (#49). 예전에는 "shadcn 13종" 이
  /// 적혀 있었고 지금은 어느 단위로도 13이 아니다. **이 문장은 생성물의
  /// `home_screen.dart` 로 그대로 나가므로 사용자가 읽는 유일한 자리인데,
  /// 아무 게이트도 그 값을 보지 않는다** — 그래서 틀린 채로 오래 나갔다.
  ///
  /// 그 13이 원래 무엇을 세었는지는 **확정할 수 없다.** 당시 파일은 12개,
  /// 디렉토리 전체는 13개, 공개 위젯 클래스는 14개였고 그중 스위치의 라벨
  /// 변형을 빼면 13종이 된다. 맞았다가 드리프트한 것일 수도, 처음부터 다른
  /// 것을 센 것일 수도 있다. **단정하지 않는다** — 확실한 것은 단위가 어디에도
  /// 안 적혀 있었다는 것이다.
  ///
  /// 개수가 필요한 자리는 `CLAUDE.md` 하나이고, 그쪽은 단위를 파일로 못박고
  /// `builder/test/component_count_test.dart` 가 지킨다.
  static const emptyHomeScreenSource = '''
import 'package:flutter/material.dart';

/// 여기서부터 시작하면 된다.
///
/// 컴포넌트가 필요하면 `lib/ui/components/` 에 shadcn 컴포넌트가 그대로 있다.
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

    final exampleTestDir = Directory(
      p.joinAll([projectRoot.path, ...exampleTestDirSegments]),
    );
    if (exampleTestDir.existsSync()) {
      exampleTestDir.deleteSync(recursive: true);
    }

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

  /// 생성물의 pubspec 에서 `dependency_overrides:` 를 **통째로** 걷어낸다.
  ///
  /// 로컬 개발 중에 형제 저장소로 override 를 거는 것은 정상 작업인데, 그것이
  /// 그대로 실려 나가면 결과물의 `flutter pub get` 이 죽는다 — 실측 **exit 66**,
  /// `version solving failed`. override 대상이 `dependencies:` 에 **없어도**
  /// 죽는다. override 자체가 의존성 엣지를 만들기 때문이다.
  ///
  /// **항목 단위가 아니라 섹션 통째인 이유가 있다.** override 는 세 갈래인데
  /// path 만 시끄럽게 죽고 나머지 둘은 **조용히 성공한다** — 실측: hosted 버전
  /// 핀은 exit 0 에 lock 으로 `dependency: "direct overridden"` 이 구워지고,
  /// git 은 exit 0 에 퍼블리시된 적 없는 버전이 `source: git` 으로 구워진다.
  /// 지울 **이름 목록**을 요구하는 방식은 그 조용한 두 갈래에서 이름을 알
  /// 방법이 없다.
  ///
  /// 이식 가능한 hosted 핀까지 같이 사라지는 것은 알고 있다. 지금 템플릿에
  /// 그런 항목이 없고 있었던 적도 없어서, 가정을 위해 분류 로직을 이고 가지
  /// 않는다 — 생기는 날 이 문단부터 고친다.
  ///
  /// **`dependencies:` 쪽은 이 함수가 아니라 [machineLocalDependencies] 가
  /// 본다.** 올바른 처리가 반대이기 때문이다. override 를 지우면 제약으로
  /// 되돌아갈 뿐이지만, 의존성을 지우면 그 패키지가 통째로 사라져 결과물이
  /// **컴파일되지 않는다.**
  ///
  /// 공개해 둔 이유는 테스트가 직접 부르기 위해서다. 지금
  /// `template/pubspec.yaml` 에는 이 섹션이 아예 없어서, 생성 결과물에 거는
  /// 어서션은 **수정 전에도 초록이다** — 끄고 빨개지는 것을 볼 수가 없다.
  ///
  /// 섹션 판정은 반드시 [String.trimRight] 을 거친다. `.gitattributes` 가
  /// `* text=auto` 라 Windows 체크아웃의 pubspec 은 CRLF 이고, 줄바꿈을 박은
  /// 패턴은 거기서 조용히 안 걸린다.
  ///
  /// **인접한 미처리 사례:** 톱레벨 `resolution: workspace` 도 결과물에서 같은
  /// exit 66 을 낸다(실측 — 워크스페이스 루트를 부모에서 못 찾는다). 지금
  /// 템플릿에 없고, 이 저장소가 pub workspaces 를 쓰게 되면 올바른 처리가
  /// 거절이 아니라 드롭이라 지금 정하지 않는다.
  static String withoutDependencyOverrides(String yaml) {
    const section = 'dependency_overrides:';

    final kept = <String>[];
    var dropping = false;

    for (final line in yaml.split('\n')) {
      final bare = line.trimRight();
      if (bare.isNotEmpty && !bare.startsWith(' ')) {
        // 들여쓰지 않은 줄에서 섹션이 바뀐다. 들여쓴 자리의 같은 글자는
        // 남의 설정값이므로 건드리지 않는다.
        //
        // `startsWith` 인 이유는 한 줄 flow 스타일 때문이다 —
        // `dependency_overrides: {a: {path: ../a}}` 는 `==` 로는 안 걸리고
        // 그대로 실려 나간다. 그 경우 매핑 전체가 이 한 줄에 있으므로 줄
        // 하나만 지우면 되고, 다음 톱레벨 키에서 [dropping] 이 저절로 풀린다.
        // `dependency_overrides_foo:` 같은 이름은 콜론 자리가 달라 안 걸린다.
        dropping = bare.startsWith(section);
      } else if (dropping && bare.isEmpty) {
        // 섹션을 끝내는 빈 줄은 섹션과 함께 사라진다. 남기면 앞뒤로 빈 줄이
        // 둘 남는다.
        continue;
      }
      if (!dropping) kept.add(line);
    }

    return kept.join('\n');
  }

  /// 템플릿 pubspec 에서 **결과물로 실리면 안 되는 머신 종속 의존성**의 이름들.
  ///
  /// `dependencies:` / `dev_dependencies:` 안에서 `path:` 또는 `git:` 소스를
  /// 쓰는 항목이다. 로컬 개발 중에 직접 의존성을 형제 저장소로 바꿔보는 것은
  /// override 를 거는 것만큼이나 정상 작업이고
  /// (`flutter_dropdown_button:\n    path: ../../flutter_dropdown_button`),
  /// 그대로 실려 나가면 결과물의 `flutter pub get` 이 **exit 66** 으로 죽는다 —
  /// `dependency_overrides` 와 글자 하나 다르지 않은 실패다(실측).
  ///
  /// **찾기만 하고 지우지 않는다.** 지우면 그 패키지가 통째로 사라져 결과물이
  /// 컴파일되지 않고, 빌더는 올바른 버전 제약을 알 방법이 없어서 **추측하면
  /// 안 된다.** 그래서 [_validate] 가 이것으로 생성을 **거절한다** —
  /// `flutter create` 보다 먼저 돌므로 아무것도 만들어지지 않는다.
  ///
  /// `dependency_overrides:` 는 여기서 **안 본다.** 그쪽은 지워도 제약으로
  /// 되돌아갈 뿐이라 처리가 반대이고 [withoutDependencyOverrides] 가 맡는다.
  ///
  /// `sdk: flutter` 는 머신 종속이 아니다 — 어느 머신에서나 유효하다.
  static List<String> machineLocalDependencies(String yaml) {
    const sections = {'dependencies:', 'dev_dependencies:'};
    const localSources = {'path', 'git'};

    final found = <String>[];
    var inSection = false;
    String? entry;

    for (final raw in yaml.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;

      if (!line.startsWith(' ')) {
        inSection = sections.contains(line);
        entry = null;
        continue;
      }
      if (!inSection) continue;

      final item = RegExp(
        r'^  ([A-Za-z_][A-Za-z0-9_]*):(.*)$',
      ).firstMatch(line);
      if (item != null) {
        entry = item.group(1);
        // 한 줄 flow 스타일 — `a: {path: ../a}`. 값 자리에서만 본다. 그래야
        // hosted `path: ^1.9.0` 이 자기 이름 때문에 걸리지 않는다.
        final inline = item.group(2)!;
        if (localSources.any(
          (s) => RegExp('[{,]\\s*$s\\s*:').hasMatch(inline),
        )) {
          found.add(entry!);
          entry = null;
        }
        continue;
      }

      // 더 깊이 들여쓴 줄은 앞 항목에 딸린 것이다.
      if (entry == null) continue;
      final key = RegExp(r'^\s+([A-Za-z_][A-Za-z0-9_]*):').firstMatch(line);
      if (key != null && localSources.contains(key.group(1))) {
        found.add(entry);
        entry = null;
      }
    }

    return found;
  }

  /// 붙여넣은 CSS 를 결과물의 테마 소스로 앉힌다.
  ///
  /// 복사해온 템플릿 CSS 를 **덮어쓴다.** 이어붙이면 두 `:root` 블록이 남아
  /// 뒤엣것이 이기는데, 그건 사용자가 붙여넣은 것과 다를 수 있다.
  ///
  /// 붙여넣지 않았으면(null) 아무것도 하지 않는다 — 템플릿 CSS 가 그대로
  /// 남고, 후처리의 테마 생성이 그것으로 같은 테마를 다시 만든다.
  void _applyThemeCss(Directory projectRoot, ThemeCss? css) {
    if (css == null) return;

    File(p.join(projectRoot.path, themeCssEntry)).writeAsStringSync(css.value);
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

/// 후처리 한 단계. 무엇을 돌리고, 그 명령의 **어떤 종료 코드를 "덜 됐지만
/// 실패는 아님" 으로 읽을지**를 함께 들고 다닌다.
///
/// 종료 코드의 뜻은 명령마다 다르므로 파이프라인이 일률적으로 정할 수 없다.
/// `flutter pub get` 의 `2` 는 그냥 실패지만, 테마 CLI 의 `2` 는 상류가
/// 문서로 못박은 "테마는 썼고 그것이 필요로 하는 것이 빠졌다" 다. 그래서
/// 값을 단계에 붙인다 — 전역 규칙으로 두면 다른 명령의 `2` 까지 조용히
/// 통과시키게 된다.
class _PostProcessingStep {
  const _PostProcessingStep(
    this.step,
    this.executable,
    this.arguments, {
    this.partialExitCode,
  });

  final GenerationStep step;
  final String executable;
  final List<String> arguments;

  /// 이 값과 같은 종료 코드는 실패가 아니라 경고다. 그런 계약이 없는 명령은
  /// null — `int == null` 은 언제나 false 라 어떤 종료 코드도 걸리지 않는다.
  final int? partialExitCode;
}
