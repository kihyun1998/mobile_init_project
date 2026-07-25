import 'dart:io';

import 'package:mobile_init_builder/src/generation/generation_config.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';
import 'package:mobile_init_builder/src/generation/process_runner.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';

/// 진짜 `flutter create` 로 한 번 만들어보는 수동 확인용 스크립트.
///
/// 자동 테스트는 전부 가짜 러너를 쓴다(그래야 자주 돌린다). 이 스크립트는
/// 그 가정이 현실과 맞는지 가끔 사람이 확인하는 용도다.
///
///   dart run tool/smoke_generate.dart <템플릿경로> <출력폴더> [이름]
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('사용법: dart run tool/smoke_generate.dart <템플릿> <출력폴더> [이름]');
    exit(64);
  }

  final generator = ProjectGenerator(
    templateDir: Directory(args[0]),
    processRunner: const SystemProcessRunner(),
  );

  final root = await generator.generate(
    GenerationConfig(
      projectName: PackageName.parse(args.length > 2 ? args[2] : 'smoke_app'),
      organization: Organization.parse('io.github.kihyun1998'),
      outputParent: Directory(args[1]),
    ),
  );

  stdout.writeln(root.path);
}
