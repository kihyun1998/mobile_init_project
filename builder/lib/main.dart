import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import 'src/generation/process_runner.dart';
import 'src/generation/project_generator.dart';
import 'src/template/template_chooser.dart';
import 'src/template/template_locator.dart';
import 'src/template/template_path_store.dart';
import 'src/ui/builder_home_page.dart';
import 'src/ui/template_picker_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const runner = SystemProcessRunner();
  final locator = TemplateLocator(store: const PrefsTemplatePathStore());

  runApp(
    BuilderApp(
      locator: locator,
      processRunner: runner,
      // 여기서 한 번 찾아두고 넘긴다. 화면이 뜬 뒤에 찾으면 첫 프레임에
      // 무엇을 그릴지 몰라 빈 화면이 깜빡인다.
      initialTemplateDir: await locator.locate(),
    ),
  );
}

/// 템플릿 경로를 들고 있는 껍데기.
///
/// 경로가 바뀌면 생성기도 새로 만들어야 해서 이 상태가 앱 꼭대기에 있다.
/// 못 찾았으면 폼 대신 물어보는 화면을 띄운다.
class BuilderApp extends StatefulWidget {
  const BuilderApp({
    super.key,
    required this.locator,
    required this.processRunner,
    this.initialTemplateDir,
    this.chooseDirectory = systemDirectoryChooser,
  });

  final TemplateLocator locator;
  final ProcessRunner processRunner;

  /// 시작할 때 찾아둔 템플릿. null 이면 물어본다.
  final Directory? initialTemplateDir;

  /// 폴더를 묻는 방법. 테스트가 진짜 창을 띄우지 않도록 갈라져 있다.
  final DirectoryChooser chooseDirectory;

  @override
  State<BuilderApp> createState() => _BuilderAppState();
}

class _BuilderAppState extends State<BuilderApp> {
  Directory? _templateDir;

  /// 바꾸려던 폴더가 템플릿이 아니었을 때의 이유.
  String? _problem;

  @override
  void initState() {
    super.initState();
    _templateDir = widget.initialTemplateDir;
  }

  /// 폴더를 묻고, 템플릿이면 그것으로 바꾼다.
  ///
  /// 처음 고르는 경우와 쓰던 것을 바꾸는 경우가 같은 흐름이다. 템플릿이
  /// 아니면 [chooseTemplate] 이 저장하지 않고 이유를 돌려주므로, 쓰고 있던
  /// 것을 그대로 두고 이유만 알린다.
  Future<void> _change() async {
    final pick = await chooseTemplate(
      widget.locator.store,
      widget.chooseDirectory,
    );
    if (!mounted) return;

    setState(() {
      // 취소하면 둘 다 null 이라 아무것도 바뀌지 않는다.
      _templateDir = pick.directory ?? _templateDir;
      _problem = pick.problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final templateDir = _templateDir;

    return MaterialApp(
      title: 'Mobile Init Builder',
      debugShowCheckedModeBanner: false,
      // 템플릿이 뿌리는 테마를 빌더도 그대로 쓴다.
      theme: TweakcnTheme.light,
      darkTheme: TweakcnTheme.dark,
      home: templateDir == null
          ? TemplatePickerPage(onBrowse: _change, problem: _problem)
          : BuilderHomePage(
              // 경로가 바뀌면 폼도 처음부터다. 옛 템플릿으로 만든 로그와
              // 결과가 새 템플릿 화면에 남아 있으면 헷갈린다.
              key: ValueKey(templateDir.path),
              generator: ProjectGenerator(
                templateDir: templateDir,
                processRunner: widget.processRunner,
              ),
              processRunner: widget.processRunner,
              templateDir: templateDir,
              templateProblem: _problem,
              onChangeTemplate: _change,
            ),
    );
  }
}
