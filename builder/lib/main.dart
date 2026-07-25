import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:path/path.dart' as p;

import 'src/generation/process_runner.dart';
import 'src/generation/project_generator.dart';
import 'src/ui/builder_home_page.dart';

void main() {
  const runner = SystemProcessRunner();

  runApp(
    BuilderApp(
      generator: ProjectGenerator(
        // 템플릿 경로는 당분간 고정이다. 찾아서 기억하는 건 별도 티켓.
        templateDir: Directory(p.join('..', 'template')),
        processRunner: runner,
      ),
      processRunner: runner,
    ),
  );
}

class BuilderApp extends StatelessWidget {
  const BuilderApp({
    super.key,
    required this.generator,
    required this.processRunner,
  });

  final ProjectGenerator generator;
  final ProcessRunner processRunner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Init Builder',
      debugShowCheckedModeBanner: false,
      // 템플릿이 뿌리는 테마를 빌더도 그대로 쓴다.
      theme: TweakcnTheme.light,
      darkTheme: TweakcnTheme.dark,
      home: BuilderHomePage(
        generator: generator,
        processRunner: processRunner,
      ),
    );
  }
}
