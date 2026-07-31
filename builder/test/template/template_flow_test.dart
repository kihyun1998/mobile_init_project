import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/main.dart';
import 'package:mobile_init_builder/src/template/template_locator.dart';
import 'package:mobile_init_builder/src/ui/builder_home_page.dart';
import 'package:mobile_init_builder/src/ui/generate_form_page.dart';
import 'package:mobile_init_builder/src/ui/template_picker_page.dart';
import 'package:path/path.dart' as p;

import '../support/fake_process_runner.dart';
import '../support/fake_template_path_store.dart';

void main() {
  late Directory scratch;
  late FakeTemplatePathStore store;

  final realTemplate = Directory(p.join('..', 'template'));

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('template_flow_');
    store = FakeTemplatePathStore();
  });

  tearDown(() => scratch.deleteSync(recursive: true));

  Future<void> pumpApp(
    WidgetTester tester, {
    Directory? initialTemplateDir,
    String? chosen,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BuilderApp(
        locator: TemplateLocator(store: store),
        processRunner: FakeProcessRunner(),
        initialTemplateDir: initialTemplateDir,
        chooseDirectory: () async => chosen,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapBrowse(WidgetTester tester) async {
    await tester.tap(find.byKey(TemplatePickerPage.browseKey));
    await tester.pumpAndSettle();
  }

  /// 앱을 껐다 켠 것과 같다: 같은 저장소로 다시 찾아서 다시 띄운다.
  ///
  /// 기본 위치는 비워둔다. 저장소에 적힌 것만으로 무엇이 달라지는지 보려는
  /// 것인데, `../template` 이 늘 잡히면 그게 가려진다.
  Future<void> restart(WidgetTester tester) async {
    // 먼저 트리에서 앱을 걷어낸다. 같은 타입을 같은 자리에 다시 꽂으면
    // State 가 재사용돼서 initState 가 돌지 않는다 — 그러면 저장소가 아니라
    // 살아남은 상태 덕에 통과하는 가짜 테스트가 된다.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final locator = TemplateLocator(store: store, candidates: const []);
    await pumpApp(tester, initialTemplateDir: await locator.locate());
  }

  testWidgets('템플릿을 찾았으면 아무것도 묻지 않는다', (tester) async {
    await pumpApp(tester, initialTemplateDir: realTemplate);

    expect(find.byType(TemplatePickerPage), findsNothing);
    expect(find.byKey(GenerateFormPage.nameFieldKey), findsOneWidget);
  });

  testWidgets('못 찾았으면 폴더를 묻는다', (tester) async {
    await pumpApp(tester);

    expect(find.byType(TemplatePickerPage), findsOneWidget);
    expect(find.byKey(GenerateFormPage.nameFieldKey), findsNothing);
  });

  testWidgets('고른 폴더가 템플릿이면 폼으로 넘어가고 기억한다', (tester) async {
    await pumpApp(tester, chosen: realTemplate.path);
    await tapBrowse(tester);

    expect(find.byKey(GenerateFormPage.nameFieldKey), findsOneWidget);
    expect(store.written, isNotNull);
    // 다음 실행의 작업 폴더가 어디일지 모른다.
    expect(p.isAbsolute(store.written!), isTrue);
  });

  testWidgets('고른 경로가 다음 실행에 그대로 쓰인다', (tester) async {
    await pumpApp(tester, chosen: realTemplate.path);
    await tapBrowse(tester);

    await restart(tester);

    // 다시 물어보지 않아야 한다.
    expect(find.byType(TemplatePickerPage), findsNothing);
    expect(find.byKey(GenerateFormPage.nameFieldKey), findsOneWidget);
  });

  testWidgets('기억해둔 폴더가 사라졌으면 다시 묻는다', (tester) async {
    final copy = Directory(p.join(scratch.path, 'template_copy'))
      ..createSync(recursive: true);
    Directory(p.join(copy.path, 'lib')).createSync();
    File(p.join(copy.path, 'tweakcn.css')).writeAsStringSync(':root {}');
    File(
      p.join(copy.path, 'pubspec.yaml'),
    ).writeAsStringSync('name: mobile_init_project\n');

    await pumpApp(tester, chosen: copy.path);
    await tapBrowse(tester);
    expect(find.byKey(GenerateFormPage.nameFieldKey), findsOneWidget);

    copy.deleteSync(recursive: true);
    await restart(tester);

    expect(find.byType(TemplatePickerPage), findsOneWidget);
  });

  testWidgets('고른 폴더가 템플릿이 아니면 이유를 알리고 저장하지 않는다', (tester) async {
    final notATemplate = Directory(p.join(scratch.path, 'empty'))..createSync();

    await pumpApp(tester, chosen: notATemplate.path);
    await tapBrowse(tester);

    expect(find.textContaining('템플릿 폴더가 아닌 것 같습니다'), findsOneWidget);
    expect(find.byKey(GenerateFormPage.nameFieldKey), findsNothing);
    expect(store.written, isNull, reason: '저장해두면 다음 실행에도 같은 이유로 실패한다');
  });

  testWidgets('취소하면 묻는 화면에 그대로 남는다', (tester) async {
    await pumpApp(tester);
    await tapBrowse(tester);

    expect(find.byType(TemplatePickerPage), findsOneWidget);
    expect(store.written, isNull);
  });

  testWidgets('쓰고 있는 템플릿 경로가 화면에 보인다', (tester) async {
    await pumpApp(tester, initialTemplateDir: realTemplate);

    expect(find.text(realTemplate.path), findsOneWidget);
    expect(find.byKey(BuilderHomePage.changeTemplateKey), findsOneWidget);
  });

  testWidgets('바꾸기로 고른 템플릿이 반영되고 저장된다', (tester) async {
    // 같은 템플릿이지만 절대 경로다. 고르면 바가 그 경로로 바뀌어야 한다.
    final absolute = realTemplate.absolute.path;
    await pumpApp(tester, initialTemplateDir: realTemplate, chosen: absolute);

    expect(find.text(absolute), findsNothing);

    await tester.tap(find.byKey(BuilderHomePage.changeTemplateKey));
    await tester.pumpAndSettle();

    expect(find.text(absolute), findsOneWidget);
    expect(store.written, absolute);
  });

  testWidgets('바꾸려던 폴더가 템플릿이 아니면 쓰던 것을 그대로 둔다', (tester) async {
    final notATemplate = Directory(p.join(scratch.path, 'empty'))..createSync();
    await pumpApp(
      tester,
      initialTemplateDir: realTemplate,
      chosen: notATemplate.path,
    );

    await tester.tap(find.byKey(BuilderHomePage.changeTemplateKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('템플릿 폴더가 아닌 것 같습니다'), findsOneWidget);
    expect(find.text(realTemplate.path), findsOneWidget);
    expect(store.written, isNull);
  });
}
