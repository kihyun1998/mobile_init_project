import 'dart:io';

import 'package:flutter/material.dart' show Key, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/main.dart';
import 'package:mobile_init_builder/src/generation/project_platform.dart';
import 'package:mobile_init_builder/src/template/template_locator.dart';
import 'package:mobile_init_builder/src/ui/generate_form_page.dart';
import 'package:path/path.dart' as p;

import 'support/fake_process_runner.dart';
import 'support/fake_template_path_store.dart';

void main() {
  late Directory outputParent;
  late FakeProcessRunner runner;

  setUp(() {
    outputParent = Directory.systemTemp.createTempSync('form_test_');
    runner = FakeProcessRunner();
  });

  tearDown(() => outputParent.deleteSync(recursive: true));

  Future<void> pumpForm(WidgetTester tester) async {
    // 폼 전체가 스크롤 없이 들어가는 크기로 잡는다. 실제 창에서는 스크롤이
    // 되지만, 테스트에서 스크롤에 기대면 위젯이 하나 늘 때마다 tap 이
    // 화면 밖을 찍어 엉뚱한 이유로 빨개진다.
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BuilderApp(
        locator: TemplateLocator(store: FakeTemplatePathStore()),
        processRunner: runner,
        initialTemplateDir: Directory(p.join('..', 'template')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester, ProjectPlatform platform) async {
    final chip = find.byKey(GenerateFormPage.platformKey(platform));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String name,
    String org = 'io.github.kihyun1998',
    String? description,
    String? displayName,
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
    if (displayName != null) {
      await tester.enterText(
        find.byKey(GenerateFormPage.displayNameFieldKey),
        displayName,
      );
    }
    final submit = find.text('생성');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
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

  testWidgets('폼에 적은 표시 이름이 안드로이드 라벨과 iOS 표시 이름까지 간다', (tester) async {
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app', displayName: '내 가계부');

    final root = p.join(outputParent.path, 'my_app');
    expect(
      File(p.join(root, 'lib', 'main.dart')).readAsStringSync(),
      contains("'내 가계부'"),
    );
    expect(
      File(p.join(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'))
          .readAsStringSync(),
      contains('android:label="내 가계부"'),
    );
    expect(
      File(p.join(root, 'ios', 'Runner', 'Info.plist')).readAsStringSync(),
      contains('<string>내 가계부</string>'),
    );
  });

  testWidgets('체크를 푼 플랫폼은 만들어지지 않는다', (tester) async {
    await pumpForm(tester);
    await toggle(tester, ProjectPlatform.ios);
    await toggle(tester, ProjectPlatform.macos);
    await fillAndSubmit(tester, name: 'my_app');

    expect(
      runner.invocations.first.arguments,
      contains('--platforms=android,macos'),
    );
    final root = p.join(outputParent.path, 'my_app');
    expect(Directory(p.join(root, 'ios')).existsSync(), isFalse);
    expect(Directory(p.join(root, 'macos')).existsSync(), isTrue);
  });

  testWidgets('플랫폼을 하나도 안 고르면 막히고 flutter create 가 실행되지 않는다', (tester) async {
    await pumpForm(tester);
    await toggle(tester, ProjectPlatform.android);
    await toggle(tester, ProjectPlatform.ios);
    await fillAndSubmit(tester, name: 'my_app');

    expect(find.textContaining('플랫폼을 하나 이상'), findsOneWidget);
    expect(find.text('만들었습니다'), findsNothing);
    expect(runner.invocations, isEmpty);
  });

  testWidgets('예제 스위치를 끄면 결과물에서 예제와 차트 의존성이 빠진다', (tester) async {
    await pumpForm(tester);
    final switchTile = find.byKey(GenerateFormPage.includeExampleKey);
    await tester.ensureVisible(switchTile);
    await tester.pumpAndSettle();
    await tester.tap(switchTile);
    await tester.pumpAndSettle();

    await fillAndSubmit(tester, name: 'my_app');

    final root = p.join(outputParent.path, 'my_app');
    expect(Directory(p.join(root, 'lib', 'example')).existsSync(), isFalse);
    expect(
      File(p.join(root, 'pubspec.yaml')).readAsStringSync(),
      isNot(contains('fl_chart')),
    );
    // 예제를 걷어낸 뒤에도 생성 자체는 끝까지 가야 한다.
    expect(find.text('만들었습니다'), findsOneWidget);
  });

  testWidgets('예제 스위치를 그대로 두면 예제가 남는다', (tester) async {
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    final root = p.join(outputParent.path, 'my_app');
    expect(Directory(p.join(root, 'lib', 'example')).existsSync(), isTrue);
    expect(
      File(p.join(root, 'pubspec.yaml')).readAsStringSync(),
      contains('fl_chart'),
    );
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
