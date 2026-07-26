import 'package:shared_preferences/shared_preferences.dart';

/// 사용자가 고른 템플릿 경로를 어디에 적어두는가.
///
/// 인터페이스로 갈라둔 이유는 [ProcessRunner] 와 같다 — 테스트가 진짜 저장소를
/// 건드리지 않게 하려는 것이다. 한 테스트가 남긴 값이 다음 테스트로 새면
/// 실패가 순서에 따라 달라진다.
abstract class TemplatePathStore {
  Future<String?> read();
  Future<void> write(String path);
}

class PrefsTemplatePathStore implements TemplatePathStore {
  const PrefsTemplatePathStore();

  static const key = 'template.path';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String path) async =>
      (await SharedPreferences.getInstance()).setString(key, path);
}
