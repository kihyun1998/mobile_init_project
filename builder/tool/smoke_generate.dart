import 'dart:io';

import 'package:mobile_init_builder/src/generation/app_language.dart';
import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';
import 'package:mobile_init_builder/src/generation/process_runner.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/generation/project_platform.dart';
import 'package:path/path.dart' as p;

/// 진짜 `flutter create` 로 한 번 만들어보는 수동 확인용 스크립트.
///
/// 자동 테스트는 전부 가짜 러너를 쓴다(그래야 자주 돌린다). 이 스크립트는
/// 그 가정이 현실과 맞는지 가끔 사람이 확인하는 용도다.
///
///   dart run tool/smoke_generate.dart <템플릿경로> <출력폴더> [이름] [--no-example] [--only-ko]
Future<void> main(List<String> rawArgs) async {
  // 모르는 플래그를 조용히 무시하면 안 된다. `--no-examples` 라고 잘못 쳐도
  // 통과해버리면, 예제를 끈 줄 알고 켠 결과물을 확인하게 된다.
  const flags = {'--no-example', '--only-ko'};
  final unknown = rawArgs.where(
    (a) => a.startsWith('--') && !flags.contains(a),
  );
  if (unknown.isNotEmpty) {
    stderr.writeln('모르는 옵션입니다: ${unknown.join(' ')}');
    exit(64);
  }

  final includeExample = !rawArgs.contains('--no-example');
  final languages = LanguageSelection.of(
    rawArgs.contains('--only-ko') ? const [AppLanguage.ko] : AppLanguage.values,
  );
  final args = rawArgs.where((a) => !a.startsWith('--')).toList();

  if (args.length < 2) {
    stderr.writeln(
      '사용법: dart run tool/smoke_generate.dart <템플릿> <출력폴더> [이름] '
      '[--no-example] [--only-ko]',
    );
    exit(64);
  }

  final generator = ProjectGenerator(
    templateDir: Directory(args[0]),
    processRunner: const SystemProcessRunner(),
  );

  final result = await generator.generate(
    GenerationConfig(
      projectName: PackageName.parse(args.length > 2 ? args[2] : 'smoke_app'),
      organization: Organization.parse('io.github.kihyun1998'),
      outputParent: Directory(args[1]),
      // 가짜 러너가 흉내낸 manifest·plist 모양이 현실과 같은지 보려면
      // 표시 이름이 프로젝트 이름과 달라야 한다.
      displayName: '연기 시험 앱',
      includeExample: includeExample,
      languages: languages,
      platforms: PlatformSelection.of(const [
        ProjectPlatform.android,
        ProjectPlatform.ios,
      ]),
    ),
  );

  stdout.writeln(result.projectRoot.path);
  if (!result.succeeded) {
    stderr.writeln('${result.failedStep?.label}: ${result.failureMessage}');
    exit(1);
  }

  final complaints = _checkLanguages(result.projectRoot, languages);
  for (final complaint in complaints) {
    stderr.writeln('✗ $complaint');
  }
  if (complaints.isNotEmpty) exit(1);
  stdout.writeln(
    '✓ 지원 언어가 ${languages.languages.map((l) => l.code).join(', ')} '
    '하나로 맞습니다',
  );
}

/// 후처리가 실제로 l10n 을 다시 만들었는지 본다.
///
/// 자동 테스트는 가짜 러너를 써서 `intl_utils:generate` 를 돌리지 않는다.
/// 그래서 "생성물이 재생성되어 고른 언어만 반영한다" 는 약속은 **여기서만**
/// 확인된다. 눈으로 훑는 대신 스크립트가 실패하게 만들어 둔다.
List<String> _checkLanguages(Directory root, LanguageSelection languages) {
  final wanted = languages.languages.map((l) => l.code).toSet();
  final complaints = <String>[];

  final arbDir = Directory(
    p.joinAll([root.path, ...ProjectGenerator.arbDirSegments]),
  );
  final arbs = arbDir
      .listSync()
      .whereType<File>()
      .where((f) => p.extension(f.path) == '.arb')
      .map((f) => p.basenameWithoutExtension(f.path).split('_').last)
      .toSet();
  if (arbs.difference(wanted).isNotEmpty ||
      wanted.difference(arbs).isNotEmpty) {
    complaints.add('번역 원본이 $arbs 입니다. $wanted 여야 합니다.');
  }

  final generated = Directory(
    p.join(root.path, 'lib', 'core', 'localization', 'generated', 'intl'),
  );
  final messages = generated
      .listSync()
      .whereType<File>()
      .map((f) => p.basenameWithoutExtension(f.path))
      .where((name) => name != 'messages_all')
      .map((name) => name.split('_').last)
      .toSet();
  if (messages.difference(wanted).isNotEmpty) {
    complaints.add(
      '고르지 않은 언어의 생성물이 남았습니다: ${messages.difference(wanted)}. '
      'intl_utils 가 고아를 지우지 않았습니다.',
    );
  }

  final l10n = File(
    p.join(root.path, 'lib', 'core', 'localization', 'generated', 'l10n.dart'),
  ).readAsStringSync();
  for (final code in wanted) {
    if (!l10n.contains("languageCode: '$code'")) {
      complaints.add('생성된 supportedLocales 에 $code 가 없습니다.');
    }
  }
  for (final code in AppLanguage.values.map((l) => l.code)) {
    if (!wanted.contains(code) && l10n.contains("languageCode: '$code'")) {
      complaints.add('생성된 supportedLocales 에 고르지 않은 $code 가 남았습니다.');
    }
  }
  // main_locale 을 빼먹으면 intl_utils 가 빈 arb 를 만들어 번역이 전부 사라진다.
  if (!l10n.contains('String get ')) {
    complaints.add('생성된 S 에 번역이 하나도 없습니다. main_locale 을 확인하세요.');
  }

  return complaints;
}
