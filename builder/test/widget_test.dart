import 'dart:io';

import 'package:flutter/material.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/main.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/ui/generate_form_page.dart';
import 'package:path/path.dart' as p;

import 'support/fake_process_runner.dart';

void main() {
  late Directory outputParent;
  late FakeProcessRunner runner;

  setUp(() {
    outputParent = Directory.systemTemp.createTempSync('form_test_');
    runner = FakeProcessRunner();
  });

  tearDown(() => outputParent.deleteSync(recursive: true));

  Future<void> pumpForm(WidgetTester tester) async {
    // 기본 테스트 표면(800x600)은 데스크톱 창치고 너무 작아서 폼 아래쪽이
    // 잘린다. 필드는 뒤따르는 티켓에서 더 늘어나므로 넉넉히 잡는다.
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BuilderApp(
        generator: ProjectGenerator(
          templateDir: Directory(p.join('..', 'template')),
          processRunner: runner,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String name,
    String org = 'io.github.kihyun1998',
    String? description,
  }) async {
    await tester.enterText(
      find.byKey(GenerateFormPage.nameFieldKey),
      name,
    );
    await tester.enterText(
      find.byKey(GenerateFormPage.organizationFieldKey),
      org,
    );
    await tester.enterText(
      find.byKey(GenerateFormPage.outputParentFieldKey),
      outputParent.path,
    );
    if (description != null) {
      await tester.enterText(
        find.byKey(GenerateFormPage.descriptionFieldKey),
        description,
      );
    }
    await tester.tap(find.text('생성'));
    await tester.pumpAndSettle();
  }

  testWidgets('이름·org·위치를 넣고 생성하면 프로젝트 경로가 표시된다', (tester) async {
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    expect(find.text('만들었습니다'), findsOneWidget);
    expect(
      find.text(p.join(outputParent.path, 'my_app')),
      findsOneWidget,
    );
    expect(runner.invocations, hasLength(1));
  });

  testWidgets('폼에 적은 설명이 결과물 pubspec 까지 간다', (tester) async {
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app', description: '내 앱 설명');

    final pubspec = File(
      p.join(outputParent.path, 'my_app', 'pubspec.yaml'),
    ).readAsStringSync();
    expect(pubspec, contains('description: "내 앱 설명"'));
  });

  testWidgets('잘못된 이름은 오류로 보이고 flutter create 가 실행되지 않는다', (tester) async {
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'My-App');

    expect(find.text('만들었습니다'), findsNothing);
    expect(
      find.textContaining('Dart 패키지 이름으로 쓸 수 없습니다'),
      findsOneWidget,
    );
    expect(runner.invocations, isEmpty);
  });

  testWidgets('flutter create 가 실패하면 그 사실이 화면에 남는다', (tester) async {
    runner = FakeProcessRunner(exitCode: 1, stderr: '디스크가 가득 찼습니다');
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    expect(find.textContaining('디스크가 가득 찼습니다'), findsOneWidget);
    expect(find.text('만들었습니다'), findsNothing);
  });
}
