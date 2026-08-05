import 'dart:io';

import 'package:flutter/material.dart'
    show Key, Scrollable, ScrollableState, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/main.dart';
import 'package:mobile_init_builder/src/generation/app_language.dart';
import 'package:mobile_init_builder/src/generation/project_generator.dart';
import 'package:mobile_init_builder/src/generation/project_platform.dart';
import 'package:mobile_init_builder/src/preview/preview_panel.dart';
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
    String? themeCss,
  }) async {
    if (themeCss != null) {
      await tester.enterText(find.byKey(PreviewPanel.cssFieldKey), themeCss);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byKey(GenerateFormPage.nameFieldKey), name);
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
    expect(find.text(p.join(outputParent.path, 'my_app')), findsOneWidget);
    // flutter create 하나로 끝나지 않는다 — 후처리까지 돌아야 바로 실행된다.
    expect(runner.invocations.first.arguments.first, 'create');
    // create + pub get + 테마 생성 + l10n + codegen.
    expect(runner.invocations, hasLength(5));
  });

  group('미리보기 CSS 가 결과물로 간다', () {
    /// 템플릿 CSS 에 없는 값이라야 "덮어썼다" 를 구분할 수 있다.
    const pasted = ':root { --primary: #FF0000; --background: #00FF00; }';

    String themeCssOf(String name) => File(
      p.join(outputParent.path, name, ProjectGenerator.themeCssEntry),
    ).readAsStringSync();

    testWidgets('붙여넣은 CSS 가 결과물의 테마 소스가 된다', (tester) async {
      await pumpForm(tester);
      await fillAndSubmit(tester, name: 'my_app', themeCss: pasted);

      expect(find.text('만들었습니다'), findsOneWidget);
      expect(themeCssOf('my_app'), pasted);
    });

    /// 파일만 갈아끼우면 화면은 여전히 복사해온 옛 테마다. 그것을 되돌리는
    /// 것은 build_runner 가 아니라 별도 CLI 다.
    testWidgets('테마를 다시 만드는 명령이 실제로 돈다', (tester) async {
      await pumpForm(tester);
      await fillAndSubmit(tester, name: 'my_app', themeCss: pasted);

      expect(
        runner.invocations.map(
          (i) => '${i.executable} ${i.arguments.join(' ')}',
        ),
        contains('dart run flutter_tweakcn_generator'),
      );
    });

    testWidgets('붙여넣지 않으면 템플릿 CSS 가 그대로 간다', (tester) async {
      await pumpForm(tester);
      await fillAndSubmit(tester, name: 'my_app');

      expect(
        themeCssOf('my_app'),
        File(
          p.join('..', 'template', ProjectGenerator.themeCssEntry),
        ).readAsStringSync(),
      );
    });

    testWidgets('읽을 수 없는 CSS 는 오류로 보이고 flutter create 가 실행되지 않는다', (
      tester,
    ) async {
      await pumpForm(tester);
      await fillAndSubmit(tester, name: 'my_app', themeCss: '이건 CSS 가 아니다');

      // 미리보기 쪽 안내와 구분되도록 생성 오류 배너 쪽을 본다.
      expect(find.textContaining('색 토큰'), findsWidgets);
      expect(runner.invocations, isEmpty);
      expect(
        Directory(p.join(outputParent.path, 'my_app')).existsSync(),
        isFalse,
      );
    });
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
      File(
        p.join(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
      ).readAsStringSync(),
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

  testWidgets('언어 체크를 풀면 그 번역 원본이 결과물에 없다', (tester) async {
    await pumpForm(tester);
    final english = find.byKey(GenerateFormPage.languageKey(AppLanguage.en));
    await tester.ensureVisible(english);
    await tester.pumpAndSettle();
    await tester.tap(english);
    await tester.pumpAndSettle();

    await fillAndSubmit(tester, name: 'my_app');

    final l10n = p.join(
      outputParent.path,
      'my_app',
      p.joinAll(ProjectGenerator.arbDirSegments),
    );
    expect(File(p.join(l10n, 'intl_ko.arb')).existsSync(), isTrue);
    expect(File(p.join(l10n, 'intl_en.arb')).existsSync(), isFalse);
    expect(
      File(
        p.join(outputParent.path, 'my_app', 'pubspec.yaml'),
      ).readAsStringSync(),
      contains('main_locale: ko'),
    );
  });

  testWidgets('언어를 하나도 안 고르면 막히고 flutter create 가 실행되지 않는다', (tester) async {
    await pumpForm(tester);
    for (final language in AppLanguage.values) {
      final chip = find.byKey(GenerateFormPage.languageKey(language));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    await fillAndSubmit(tester, name: 'my_app');

    expect(find.textContaining('언어를 하나 이상'), findsOneWidget);
    expect(runner.invocations, isEmpty);
  });

  testWidgets('잘못된 이름은 오류로 보이고 flutter create 가 실행되지 않는다', (tester) async {
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'My-App');

    expect(find.text('만들었습니다'), findsNothing);
    expect(find.textContaining('Dart 패키지 이름으로 쓸 수 없습니다'), findsOneWidget);
    expect(runner.invocations, isEmpty);
  });

  testWidgets('진행 중 단계와 명령 출력이 화면에 흐른다', (tester) async {
    runner = FakeProcessRunner(outputLines: ['Resolving dependencies...']);
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    // 끝난 뒤에도 로그가 남아 있어야 무엇이 있었는지 볼 수 있다.
    expect(find.byKey(const Key('generate.log')), findsOneWidget);
    expect(find.textContaining('Resolving dependencies...'), findsWidgets);

    // 마지막 단계는 로그 창 높이를 넘어가서 끝까지 내려야 보인다. 진짜 앱에서는
    // LogView 가 줄이 늘 때마다 자동으로 내려가지만, 가짜 러너로는 생성이
    // 프레임 하나 없이 끝나 LogView 가 붙기 전에 모든 줄이 쌓인다. 그래서
    // 여기서는 사용자가 내리는 것을 대신 해준다.
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('generate.log')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

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
    expect(Directory(p.join(outputParent.path, 'my_app')).existsSync(), isTrue);
  });

  /// **덜 된 것은 실패와 다른 칸에 뜬다.**
  ///
  /// 테마 CLI 의 `2` 는 "테마는 썼는데 그것이 필요로 하는 것이 빠졌다" 다.
  /// 결과물은 `flutter run` 이 되므로 실패 배너는 거짓말이고, 그렇다고 삼키면
  /// 사용자는 폰트가 빠진 것을 영영 모른다 — Flutter 는 런타임에 아무 말 없이
  /// 기본 폰트로 떨어진다. 그래서 성공 배너 안에서 따로 말해야 한다.
  testWidgets('테마가 덜 만들어지면 성공 배너에 경고가 함께 뜬다', (tester) async {
    runner = FakeProcessRunner(
      failingCommand: 'flutter_tweakcn_generator',
      failureExitCode: 2,
      stderr:
          'Error: the generated theme names 1 font family(ies) that '
          'pubspec.yaml does not declare',
    );
    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    expect(find.textContaining('에서 실패했습니다'), findsNothing);
    expect(find.textContaining('덜 된 것이 있습니다'), findsOneWidget);
    expect(
      find.textContaining('pubspec.yaml does not declare'),
      findsOneWidget,
    );
    // 쓸 수 있다고 말했으면 경로도 그대로 보여야 한다.
    expect(find.text(p.join(outputParent.path, 'my_app')), findsOneWidget);
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

  testWidgets('종료 코드 1 을 실패로 볼지가 OS 마다 갈린다', (tester) async {
    // **Windows 의 explorer 는 성공해도 1 을 돌려준다** (실측 2026-08-05,
    // Windows 11 — #32 의 릴리스 왕복에서 나왔다). 그래서 같은 종료 코드가
    // Windows 에서는 실패가 아니고 macOS·linux 에서는 실패다.
    //
    // 판정 자체는 `file_manager_test.dart` 가 세 OS 분을 전부 본다. 여기서
    // 보는 것은 **호출부가 그 판정을 거치는가** 다 — `result.succeeded` 로
    // 되돌리면 저쪽은 초록인 채로 이 테스트만 Windows 에서 빨개진다.
    //
    // 여는 명령만 실패시킨다. 프로젝트 경로가 인자로 들어가는 명령은 이것
    // 하나뿐이라(`flutter create` 는 이름만 받고 폴더는 workingDirectory 다)
    // 다른 단계를 건드리지 않는다.
    final projectPath = p.join(outputParent.path, 'my_app');
    runner = FakeProcessRunner(failingCommand: projectPath);

    await pumpForm(tester);
    await fillAndSubmit(tester, name: 'my_app');

    await tester.ensureVisible(find.text('폴더 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('폴더 열기'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('폴더를 열지 못했습니다'),
      Platform.isWindows ? findsNothing : findsOneWidget,
      reason: Platform.isWindows
          ? 'explorer 의 1 은 성공이다 — 실패 배너가 뜨면 안 된다'
          : 'open/xdg-open 의 1 은 진짜 실패다 — 배너가 떠야 한다',
    );
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
