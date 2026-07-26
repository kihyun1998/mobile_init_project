import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../generation/process_runner.dart';
import '../generation/project_generator.dart';
import '../preview/preview_panel.dart';
import '../preview/preview_theme.dart';
import 'generate_form_page.dart';

/// 빌더의 한 화면. 왼쪽은 생성 폼, 오른쪽은 테마 미리보기.
///
/// CSS 상태를 여기서 들고 있는다. 미리보기가 쓰는 그 CSS 가 나중에 생성될
/// 프로젝트의 테마 소스가 되기 때문이다.
class BuilderHomePage extends StatefulWidget {
  const BuilderHomePage({
    super.key,
    required this.generator,
    required this.processRunner,
    required this.templateDir,
    required this.onChangeTemplate,
    this.templateProblem,
  });

  static const changeTemplateKey = Key('template.change');

  final ProjectGenerator generator;
  final ProcessRunner processRunner;

  /// 지금 걸려 있는 템플릿. 생성기 안을 들여다보는 대신 따로 받는다.
  final Directory templateDir;

  /// 템플릿을 다른 폴더로 바꾸겠다는 요청. 어떤 폴더인지 확인하고 기억하는
  /// 일은 이 화면 몫이 아니다.
  final VoidCallback onChangeTemplate;

  /// 바꾸려던 폴더를 쓸 수 없었던 이유. 없으면 null.
  final String? templateProblem;

  @override
  State<BuilderHomePage> createState() => _BuilderHomePageState();
}

class _BuilderHomePageState extends State<BuilderHomePage> {
  final _css = TextEditingController();

  PreviewTheme? _themes;
  String? _previewError;
  Brightness _brightness = Brightness.light;

  @override
  void dispose() {
    _css.dispose();
    super.dispose();
  }

  void _onCssChanged(String css) {
    if (css.trim().isEmpty) {
      // 지우면 템플릿 기본 테마로 돌아간다. 오류로 취급하지 않는다.
      setState(() {
        _themes = null;
        _previewError = null;
      });
      return;
    }

    try {
      final parsed = PreviewTheme.fromCss(css);
      setState(() {
        _themes = parsed;
        _previewError = null;
      });
    } on PreviewThemeException catch (e) {
      // 마지막으로 성공한 테마는 그대로 둔다. 타이핑 도중 화면이 깜빡이지
      // 않게 하려는 것이다.
      setState(() => _previewError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TemplateBar(
              path: widget.templateDir.path,
              problem: widget.templateProblem,
              onChange: widget.onChangeTemplate,
            ),
            Divider(height: 1, color: colors.border),
            Expanded(child: _body(colors)),
          ],
        ),
      ),
    );
  }

  Widget _body(TweakcnColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GenerateFormPage(
            generator: widget.generator,
            processRunner: widget.processRunner,
          ),
        ),
        VerticalDivider(width: 1, color: colors.border),
        SizedBox(
          width: 460,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PreviewPanel(
              cssController: _css,
              onCssChanged: _onCssChanged,
              themes: _themes,
              error: _previewError,
              brightness: _brightness,
              onBrightnessChanged: (v) => setState(() => _brightness = v),
            ),
          ),
        ),
      ],
    );
  }
}

/// 지금 어느 템플릿을 쓰고 있는지, 그리고 바꾸는 자리.
///
/// 늘 보이게 둔다. 여러 벌을 갖고 있을 때 어느 것이 걸려 있는지 모르는 채로
/// 생성하면, 결과가 왜 그런지 알 방법이 없다.
class _TemplateBar extends StatelessWidget {
  const _TemplateBar({
    required this.path,
    required this.problem,
    required this.onChange,
  });

  final String path;
  final String? problem;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('템플릿', style: TextStyle(color: colors.mutedForeground)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  path,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.foreground),
                ),
              ),
              TextButton(
                key: BuilderHomePage.changeTemplateKey,
                onPressed: onChange,
                child: const Text('바꾸기'),
              ),
            ],
          ),
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                problem!,
                style: TextStyle(color: colors.destructive, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
