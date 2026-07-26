import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/template/template_chooser.dart';
import 'package:mobile_init_builder/src/template/template_locator.dart';
import 'package:mobile_init_builder/src/template/template_path_store.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// 진짜 저장소를 쓰는 유일한 테스트.
///
/// 나머지는 전부 가짜를 꽂는다. 그래서 [PrefsTemplatePathStore] 가 아무것도
/// 하지 않는 껍데기가 되어도 다른 테스트는 전부 통과한다 — "다음 실행에
/// 재사용된다" 는 약속이 여기서만 지켜진다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = PrefsTemplatePathStore();
  final realTemplate = Directory(p.join('..', 'template')).absolute;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('적은 것을 다시 읽어낸다', () async {
    expect(await store.read(), isNull);

    await store.write(realTemplate.path);

    expect(await store.read(), realTemplate.path);
  });

  test('고른 폴더가 다음 실행의 locate 에 그대로 쓰인다', () async {
    // 앱을 껐다 켜는 것과 같은 순서다: 고르고 → 저장되고 → 다음 실행이 찾는다.
    final pick = await chooseTemplate(store, () async => realTemplate.path);
    expect(pick.directory, isNotNull);

    // 기본 위치는 일부러 막아둔다. 저장된 것이 아니면 찾을 수 없어야 한다.
    final next = await TemplateLocator(store: store, candidates: const [])
        .locate();

    expect(next?.path, realTemplate.path);
  });

  test('저장된 폴더가 사라지면 다음 실행은 다시 묻는다', () async {
    final gone = Directory.systemTemp.createTempSync('store_test_');
    await store.write(gone.path);
    gone.deleteSync();

    final next = await TemplateLocator(store: store, candidates: const [])
        .locate();

    expect(next, isNull);
  });
}
