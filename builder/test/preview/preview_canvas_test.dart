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

  testWidgets('붙여넣은 CSS 의 그림자로 컴포넌트가 그려진다', (tester) async {
    // 파싱이 맞아도 테마에 실리지 않으면 사용자에겐 실패다 — 색에 대해
    // 위 두 테스트가 하는 일을 그림자에 대해 한 번 더 한다. `PreviewTheme`
    // 이 그림자를 들고 있는 것까지는 `preview_shadow_parity_test` 가 보고,
    // 여기는 그것이 **컴포넌트까지 닿는지**를 본다. #25 이전에는 앞의 것만
    // 참이었고 카드는 CSS 와 무관한 검정 3% 를 그리고 있었다.
    await pumpCanvas(
      tester,
      brightness: Brightness.light,
      css: '''
:root {
  --background: #FFFFFF;
  --card: #00FF00;
  --shadow-sm: 0 7px 13px 0px hsl(0 0% 0% / 0.50);
}
''',
      child: const Scaffold(body: ShadcnCard(title: '미리보기')),
    );

    final drawn = renderedCardShadow(tester).single;
    expect(drawn.offset.dy, 7);
    expect(drawn.blurRadius, 13);
    expect(drawn.color.a, closeTo(0.5, 0.01));
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
