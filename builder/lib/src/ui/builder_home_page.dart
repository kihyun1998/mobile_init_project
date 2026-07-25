import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../generation/project_generator.dart';
import '../preview/preview_panel.dart';
import '../preview/preview_theme.dart';
import 'generate_form_page.dart';

/// 빌더의 한 화면. 왼쪽은 생성 폼, 오른쪽은 테마 미리보기.
///
/// CSS 상태를 여기서 들고 있는다. 미리보기가 쓰는 그 CSS 가 나중에 생성될
/// 프로젝트의 테마 소스가 되기 때문이다.
class BuilderHomePage extends StatefulWidget {
  const BuilderHomePage({super.key, required this.generator});

  final ProjectGenerator generator;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GenerateFormPage(generator: widget.generator),
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
        ),
      ),
    );
  }
}
