import 'package:mobile_init_builder/src/template/template_path_store.dart';

/// 저장된 값을 메모리에만 들고 있는 저장소.
///
/// [written] 을 따로 두는 이유는 "읽어보니 값이 있다" 와 "이번에 우리가
/// 썼다" 를 구분하기 위해서다. 저장하면 안 되는 상황을 검사하려면 이 구분이
/// 필요하다.
class FakeTemplatePathStore implements TemplatePathStore {
  String? value;
  String? written;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String path) async {
    value = path;
    written = path;
  }
}
