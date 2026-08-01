import 'dart:io';

import 'package:mobile_init_builder/src/generation/app_language.dart';
import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';
import 'package:mobile_init_builder/src/generation/process_runner.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/generation/project_platform.dart';
import 'package:mobile_init_builder/src/generation/theme_css.dart';
import 'package:path/path.dart' as p;

/// 진짜 `flutter create` 로 한 번 만들어보는 수동 확인용 스크립트.
///
/// 자동 테스트는 전부 가짜 러너를 쓴다(그래야 자주 돌린다). 이 스크립트는
/// 그 가정이 현실과 맞는지 가끔 사람이 확인하는 용도다.
///
///   dart run tool/smoke_generate.dart <템플릿경로> <출력폴더> [이름] [--no-example] [--only-ko] [--css=<파일>]
Future<void> main(List<String> rawArgs) async {
  // 모르는 플래그를 조용히 무시하면 안 된다. `--no-examples` 라고 잘못 쳐도
  // 통과해버리면, 예제를 끈 줄 알고 켠 결과물을 확인하게 된다.
  const flags = {'--no-example', '--only-ko'};
  const valueFlags = {'--css'};
  final unknown = rawArgs.where(
    (a) =>
        a.startsWith('--') &&
        !flags.contains(a) &&
        !valueFlags.contains(a.split('=').first),
  );
  if (unknown.isNotEmpty) {
    stderr.writeln('모르는 옵션입니다: ${unknown.join(' ')}');
    exit(64);
  }

  final cssArg = rawArgs
      .where((a) => a.startsWith('--css='))
      .map((a) => a.substring('--css='.length))
      .firstOrNull;
  ThemeCss? themeCss;
  if (cssArg != null) {
    final file = File(cssArg);
    if (!file.existsSync()) {
      stderr.writeln('CSS 파일이 없습니다: $cssArg');
      exit(64);
    }
    themeCss = ThemeCss.parse(file.readAsStringSync());
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
      themeCss: themeCss,
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

  final complaints = [
    ..._checkLanguages(result.projectRoot, languages),
    ..._checkTheme(result.projectRoot, themeCss),
  ];
  for (final complaint in complaints) {
    stderr.writeln('✗ $complaint');
  }
  if (complaints.isNotEmpty) exit(1);
  stdout.writeln(
    '✓ 지원 언어가 ${languages.languages.map((l) => l.code).join(', ')} '
    '하나로 맞습니다',
  );
  if (themeCss != null) stdout.writeln('✓ 붙여넣은 CSS 가 결과물 테마에 실렸습니다');
}

/// 후처리가 실제로 테마를 다시 만들었는지 본다.
///
/// **가짜 러너로는 이걸 볼 수 없다.** 자동 테스트가 확인하는 것은 "그 명령이
/// 인자 목록에 있었다" 까지이고, `dart run flutter_tweakcn_generator` 가 정말로
/// `tweakcn_theme.g.dart` 를 갈아치웠는지는 진짜로 돌려봐야 안다. 그리고 이
/// 단계를 빼먹었을 때의 증상은 컴파일 에러가 아니라 **복사해온 옛 테마가 그냥
/// 남는 것**이라 조용하다.
List<String> _checkTheme(Directory root, ThemeCss? themeCss) {
  if (themeCss == null) return const [];

  final complaints = <String>[];

  final onDisk = File(
    p.join(root.path, ProjectGenerator.themeCssEntry),
  ).readAsStringSync();
  if (onDisk != themeCss.value) {
    complaints.add('결과물의 ${ProjectGenerator.themeCssEntry} 가 붙여넣은 CSS 와 다릅니다.');
  }

  final generated = File(
    p.join(root.path, 'lib', 'core', 'theme', 'tweakcn_theme.g.dart'),
  ).readAsStringSync();

  // 파싱된 색이 실제로 생성물에 박혔는지 본다. 토큰 이름이 아니라 값으로
  // 확인해야 "옛 테마가 그대로 남은" 경우를 잡는다.
  for (final token in ['primary', 'background']) {
    final value = themeCss.parsed.light.colors[token];
    if (value == null) continue;

    final literal =
        '0x${value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
    if (!generated.contains(literal)) {
      complaints.add(
        '생성된 테마에 --$token ($literal) 이 없습니다. '
        '테마 재생성이 돌지 않았거나 옛 테마가 남았습니다.',
      );
    }
  }

  return complaints;
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
