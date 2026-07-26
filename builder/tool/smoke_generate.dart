import 'dart:io';

import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';
import 'package:mobile_init_builder/src/generation/process_runner.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/generation/project_platform.dart';

/// 진짜 `flutter create` 로 한 번 만들어보는 수동 확인용 스크립트.
///
/// 자동 테스트는 전부 가짜 러너를 쓴다(그래야 자주 돌린다). 이 스크립트는
/// 그 가정이 현실과 맞는지 가끔 사람이 확인하는 용도다.
///
///   dart run tool/smoke_generate.dart <템플릿경로> <출력폴더> [이름] [--no-example]
Future<void> main(List<String> rawArgs) async {
  // 모르는 플래그를 조용히 무시하면 안 된다. `--no-examples` 라고 잘못 쳐도
  // 통과해버리면, 예제를 끈 줄 알고 켠 결과물을 확인하게 된다.
  final unknown = rawArgs.where(
    (a) => a.startsWith('--') && a != '--no-example',
  );
  if (unknown.isNotEmpty) {
    stderr.writeln('모르는 옵션입니다: ${unknown.join(' ')}');
    exit(64);
  }

  final includeExample = !rawArgs.contains('--no-example');
  final args = rawArgs.where((a) => !a.startsWith('--')).toList();

  if (args.length < 2) {
    stderr.writeln(
      '사용법: dart run tool/smoke_generate.dart <템플릿> <출력폴더> [이름] '
      '[--no-example]',
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
}
