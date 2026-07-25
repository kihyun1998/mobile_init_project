import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/main.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/preview/preview_panel.dart';
import 'package:mobile_init_project/ui/components/shadcn_card.dart';
import 'package:path/path.dart' as p;

import '../support/fake_process_runner.dart';
import '../support/rendered_color.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BuilderApp(
        generator: ProjectGenerator(
          templateDir: Directory(p.join('..', 'template')),
          processRunner: FakeProcessRunner(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pasteCss(WidgetTester tester, String css) async {
    await tester.enterText(find.byKey(PreviewPanel.cssFieldKey), css);
    // MaterialApp 은 테마 교체를 애니메이션으로 처리한다. 끝나기 전에 색을
    // 읽으면 보간 중인 값이 나온다.
    await tester.pumpAndSettle();
  }

  testWidgets('CSS 를 붙여넣으면 캔버스가 그 색으로 다시 그려진다', (tester) async {
    await pumpApp(tester);
    final before = renderedCardColor(tester);

    await pasteCss(tester, ':root { --card: #00FF00; }');

    expect(renderedCardColor(tester), const Color(0xFF00FF00));
    expect(renderedCardColor(tester), isNot(before));
  });

  testWidgets('다크로 전환하면 같은 CSS 의 다크 값이 나온다', (tester) async {
    await pumpApp(tester);
    await pasteCss(
      tester,
      ':root { --card: #00FF00; } .dark { --card: #0000FF; }',
    );

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(renderedCardColor(tester), const Color(0xFF0000FF));
  });

  testWidgets('잘못된 CSS 는 앱을 죽이지 않고 무엇이 문제인지 알린다', (tester) async {
    await pumpApp(tester);
    await pasteCss(tester, '이건 CSS 가 아니다');

    expect(find.textContaining('색 토큰'), findsOneWidget);
    // 캔버스는 살아 있어야 한다.
    expect(find.byType(ShadcnCard), findsWidgets);
  });

  testWidgets('CSS 를 지우면 템플릿 기본 테마로 돌아간다', (tester) async {
    await pumpApp(tester);
    final templateDefault = renderedCardColor(tester);

    await pasteCss(tester, ':root { --card: #00FF00; }');
    expect(renderedCardColor(tester), const Color(0xFF00FF00));

    await pasteCss(tester, '');
    expect(renderedCardColor(tester), templateDefault);
  });
}
