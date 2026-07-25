import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/preview/preview_canvas.dart';
import 'package:mobile_init_builder/src/preview/preview_theme.dart';
import 'package:mobile_init_project/example/shadcn_components_page.dart';
import 'package:mobile_init_project/ui/components/shadcn_card.dart';

import '../support/rendered_color.dart';

const _css = '''
:root {
  --background: #FFFFFF;
  --card: #00FF00;
  --primary: #FF0000;
}
.dark {
  --background: #000000;
  --card: #0000FF;
}
''';

void main() {
  Future<void> pumpCanvas(
    WidgetTester tester, {
    required Brightness brightness,
    String css = _css,
    Widget? child,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final themes = PreviewTheme.fromCss(css);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreviewCanvas(
            theme: brightness == Brightness.light ? themes.light : themes.dark,
            child: child,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('붙여넣은 CSS 의 색으로 컴포넌트가 그려진다', (tester) async {
    await pumpCanvas(
      tester,
      brightness: Brightness.light,
      child: const Scaffold(body: ShadcnCard(title: '미리보기')),
    );

    expect(renderedCardColor(tester), const Color(0xFF00FF00));
  });

  testWidgets('다크로 바꾸면 같은 컴포넌트가 다크 색으로 다시 그려진다', (tester) async {
    await pumpCanvas(
      tester,
      brightness: Brightness.dark,
      child: const Scaffold(body: ShadcnCard(title: '미리보기')),
    );

    expect(renderedCardColor(tester), const Color(0xFF0000FF));
  });

  testWidgets('기본 캔버스는 템플릿 예제 페이지를 그대로 쓴다', (tester) async {
    // 사본이 아니라 template/ 의 그 파일이어야 한다. 사본을 만드는 순간
    // 미리보기가 생성 결과와 어긋나기 시작한다.
    await pumpCanvas(tester, brightness: Brightness.light);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ShadcnComponentsPage), findsOneWidget);
    expect(find.byType(ShadcnCard), findsWidgets);
  });

  testWidgets('캔버스는 데스크톱 창이 아니라 폰 크기로 그린다', (tester) async {
    // 컴포넌트가 .w/.h 를 쓰므로 데스크톱 폭 그대로 두면 전부 뭉개진다.
    await pumpCanvas(
      tester,
      brightness: Brightness.light,
      child: const Scaffold(body: ShadcnCard(title: '미리보기')),
    );

    final size = tester.getSize(find.byType(PreviewCanvas));
    expect(size.width, PreviewCanvas.phoneSize.width);
    expect(size.height, PreviewCanvas.phoneSize.height);
  });
}
