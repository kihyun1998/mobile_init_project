import 'dart:io';

import 'package:flutter/material.dart' show Key, Size;
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
        processRunner: runner,
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
    // flutter create 하나로 끝나지 않는다 — 후처리까지 돌아야 바로 실행된다.
    expect(runner.invocations.first.arguments.first, 'create');
    expect(runner.invocations, hasLength(4));
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

  testWidgets('진행 중 단계와 명령 출력이 화면에 흐른다', (tester) async {
    runner = FakeProcessRunner(outputLines: ['Resolving dependencies...']);
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    // 끝난 뒤에도 로그가 남아 있어야 무엇이 있었는지 볼 수 있다.
    expect(find.byKey(const Key('generate.log')), findsOneWidget);
    expect(find.textContaining('Resolving dependencies...'), findsWidgets);
    expect(find.textContaining('코드 생성 중'), findsWidgets);
  });

  testWidgets('후처리가 실패해도 경로가 남고 어느 단계였는지 보인다', (tester) async {
    runner = FakeProcessRunner(
      failingCommand: 'build_runner',
      stderr: '코드 생성이 터졌습니다',
    );
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    expect(find.textContaining('에서 실패했습니다'), findsOneWidget);
    expect(find.textContaining('코드 생성이 터졌습니다'), findsOneWidget);
    // 프로젝트는 남아 있으니 경로도 보여야 한다.
    expect(find.text(p.join(outputParent.path, 'my_app')), findsOneWidget);
    expect(
      Directory(p.join(outputParent.path, 'my_app')).existsSync(),
      isTrue,
    );
  });

  testWidgets('폴더 열기 버튼이 파일 관리자를 호출한다', (tester) async {
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    // 로그 창과 결과 배너가 붙으면서 버튼이 접힌 아래쪽에 있을 수 있다.
    await tester.ensureVisible(find.text('폴더 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('폴더 열기'));
    await tester.pumpAndSettle();

    final opened = runner.invocations.last;
    expect(opened.executable, isIn(['open', 'explorer', 'xdg-open']));
    expect(opened.arguments.single, p.join(outputParent.path, 'my_app'));
  });

  testWidgets('flutter create 가 실패하면 그 사실이 화면에 남는다', (tester) async {
    runner = FakeProcessRunner(
      failingCommand: 'create',
      stderr: '디스크가 가득 찼습니다',
    );
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    expect(find.textContaining('디스크가 가득 찼습니다'), findsOneWidget);
    expect(find.text('만들었습니다'), findsNothing);
  });
}
