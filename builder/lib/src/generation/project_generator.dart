import 'dart:io';

import 'package:path/path.dart' as p;

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
  ProjectGenerator({
    required this.templateDir,
    required this.processRunner,
  });

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
    _rewriteReferences(projectRoot, config, preserved);

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
      throw GenerationException(
        '출력 폴더가 없습니다: ${config.outputParent.path}',
      );
    }

    final target = _targetDirectory(config);
    if (target.existsSync() || File(target.path).existsSync()) {
      throw GenerationException(
        '${target.path} 가 이미 있습니다. 기존 작업을 덮어쓰지 않기 위해 중단합니다.',
      );
    }
  }

  Directory _targetDirectory(GenerationConfig config) => Directory(
        p.join(config.outputParent.path, config.projectName.value),
      );

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
    for (final file in projectRoot.listSync(recursive: true).whereType<File>()) {
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
