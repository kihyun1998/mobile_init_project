import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/template/template_chooser.dart';
import 'package:mobile_init_builder/src/template/template_locator.dart';
import 'package:path/path.dart' as p;

import '../support/fake_template_path_store.dart';

void main() {
  late Directory scratch;
  late FakeTemplatePathStore store;

  // 진짜 template/ 을 기준으로 본다. 합성 픽스처만 쓰면 "이게 그 템플릿인가"
  // 라는 물음 자체가 무의미해진다.
  final realTemplate = Directory(p.join('..', 'template')).absolute;

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('locator_test_');
    store = FakeTemplatePathStore();
  });

  tearDown(() => scratch.deleteSync(recursive: true));

  /// 템플릿처럼 생겼지만 다른 프로젝트인 폴더.
  Directory otherProject() {
    final dir = Directory(p.join(scratch.path, 'other'))
      ..createSync(recursive: true);
    Directory(p.join(dir.path, 'lib')).createSync();
    File(p.join(dir.path, 'tweakcn.css')).writeAsStringSync(':root {}');
    File(p.join(dir.path, 'pubspec.yaml'))
        .writeAsStringSync('name: someone_elses_app\n');
    return dir;
  }

  TemplateLocator locator({List<String>? candidates}) =>
      TemplateLocator(store: store, candidates: candidates ?? const []);

  group('폴더가 템플릿인지 보기', () {
    test('진짜 템플릿은 통과한다', () {
      expect(TemplateLocator.problemWith(realTemplate), isNull);
    });

    test('없는 폴더는 그렇다고 말한다', () {
      final problem = TemplateLocator.problemWith(
        Directory(p.join(scratch.path, 'nope')),
      );
      expect(problem, contains('없습니다'));
    });

    test('필수 항목이 빠지면 무엇이 없는지 말한다', () {
      final dir = Directory(p.join(scratch.path, 'half'))..createSync();
      Directory(p.join(dir.path, 'lib')).createSync();

      final problem = TemplateLocator.problemWith(dir);
      expect(problem, contains('pubspec.yaml'));
      expect(problem, contains('tweakcn.css'));
      expect(problem, isNot(contains('lib,')));
    });

    test('모양은 같지만 다른 프로젝트면 거절한다', () {
      // 생성기가 package:mobile_init_project/ 를 하드코딩해 치환한다.
      // 다른 프로젝트를 얹으면 컴파일되지 않는 결과가 나온다.
      expect(
        TemplateLocator.problemWith(otherProject()),
        contains('다른 Flutter 프로젝트'),
      );
    });
  });

  group('찾기', () {
    test('기본 위치에 있으면 저장된 것 없이도 찾는다', () async {
      final found = await locator(
        candidates: [realTemplate.path],
      ).locate();

      expect(found?.path, realTemplate.path);
      expect(store.written, isNull, reason: '찾기만 했는데 저장하면 안 된다');
    });

    test('저장된 경로가 기본 위치보다 우선한다', () async {
      // 설정에서 바꿔둔 것을 기본 위치가 덮어쓰면 바꾼 의미가 없다.
      store.value = realTemplate.path;

      final found = await locator(candidates: [p.join('어딘가', '다른곳')]).locate();

      expect(found?.path, realTemplate.path);
    });

    test('저장된 경로가 사라졌으면 기본 위치로 떨어진다', () async {
      store.value = p.join(scratch.path, '지워진곳');

      final found = await locator(candidates: [realTemplate.path]).locate();

      expect(found?.path, realTemplate.path);
    });

    test('저장된 것이 다른 프로젝트여도 기본 위치로 떨어진다', () async {
      store.value = otherProject().path;

      final found = await locator(candidates: [realTemplate.path]).locate();

      expect(found?.path, realTemplate.path);
    });

    test('아무 데도 없으면 null 이다 — 물어봐야 한다', () async {
      expect(await locator().locate(), isNull);
    });

    test('저장된 것도 사라지고 기본 위치에도 없으면 다시 묻는다', () async {
      // 저장된 경로가 살아 있는 동안은 아무 일도 없다가, 그 폴더가 사라지는
      // 순간 물어봐야 한다. 기본 위치까지 없는 이 경우가 진짜 그 상황이다.
      store.value = p.join(scratch.path, '지워진곳');

      expect(await locator(candidates: [p.join(scratch.path, '여기도없음')]).locate(), isNull);
    });

    test('기본 위치 목록이 개발 중 실제로 맞는다', () async {
      // main() 이 쓰는 건 이 목록이다. 테스트는 builder/ 에서 도는데,
      // 앱도 (샌드박스를 끈 덕분에) 같은 자리에서 돈다.
      final found = await TemplateLocator(store: store).locate();

      expect(
        found,
        isNotNull,
        reason: 'defaultCandidates 가 틀렸거나 작업 폴더 가정이 깨졌다',
      );
      expect(p.canonicalize(found!.path), p.canonicalize(realTemplate.path));
    });

    test('상대 경로로 찾아도 절대 경로를 돌려준다', () async {
      // 다음 실행의 작업 폴더가 어디일지 알 수 없다.
      final found = await locator(
        candidates: [p.join('..', 'template')],
      ).locate();

      expect(found, isNotNull);
      expect(p.isAbsolute(found!.path), isTrue);
    });
  });

  group('고르기', () {
    test('템플릿이면 기억한다', () async {
      final result = await chooseTemplate(
        store,
        () async => realTemplate.path,
      );

      expect(result.problem, isNull);
      expect(result.directory?.path, realTemplate.path);
      expect(store.written, realTemplate.path);
    });

    test('템플릿이 아니면 이유를 주고 저장하지 않는다', () async {
      final result = await chooseTemplate(
        store,
        () async => otherProject().path,
      );

      expect(result.directory, isNull);
      expect(result.problem, contains('다른 Flutter 프로젝트'));
      expect(
        store.written,
        isNull,
        reason: '엉뚱한 폴더를 저장하면 다음 실행에도 같은 이유로 실패한다',
      );
    });

    test('취소하면 아무 일도 없다', () async {
      final result = await chooseTemplate(store, () async => null);

      expect(result.directory, isNull);
      expect(result.problem, isNull);
      expect(store.written, isNull);
    });

    test('상대 경로를 골라도 절대 경로로 저장한다', () async {
      await chooseTemplate(store, () async => p.join('..', 'template'));

      expect(store.written, isNotNull);
      expect(p.isAbsolute(store.written!), isTrue);
    });
  });
}
