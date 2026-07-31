import 'dart:io';

import 'package:path/path.dart' as p;

import '../generation/project_generator.dart';
import 'template_path_store.dart';

/// 빌더가 뿌릴 `template/` 이 어디 있는지 정한다.
///
/// 개발 중에는 옆에 있으므로 아무것도 묻지 않는다. `.app`/`.exe` 로 빌드해
/// 옮긴 경우처럼 못 찾을 때만 사용자에게 묻고, 그 답을 기억한다.
class TemplateLocator {
  TemplateLocator({required this.store, List<String>? candidates})
    : candidates = candidates ?? defaultCandidates;

  final TemplatePathStore store;

  /// 아무것도 저장돼 있지 않을 때 볼 자리. **현재 작업 폴더 기준이다.**
  ///
  /// macOS 앱 샌드박스를 켜면 작업 폴더가 `~/Library/Containers/…/Data` 가
  /// 되어 이 둘 다 해석되지 않는다. `builder/macos/Runner/*.entitlements` 에서
  /// 샌드박스를 빼둔 이유 중 하나가 이것이다.
  static final defaultCandidates = List<String>.unmodifiable([
    p.join('..', 'template'), // builder/ 에서 flutter run
    'template', // 저장소 루트에서 실행
  ]);

  final List<String> candidates;

  /// 이 폴더를 템플릿으로 인정하는 데 반드시 있어야 하는 것.
  ///
  /// [ProjectGenerator.copyEntries] 의 부분집합이다. 그쪽은 "있으면 복사할
  /// 것" 이라 `assets/` 처럼 없어도 되는 항목이 섞여 있는데, 여기서 물어보는
  /// 건 "이 폴더가 그 템플릿이 맞는가" 라서 없어도 되는 것을 요구하면
  /// 멀쩡한 폴더를 거절하게 된다.
  static const requiredEntries = ['lib', 'pubspec.yaml', 'tweakcn.css'];

  /// 쓸 수 있는 템플릿을 찾는다. 못 찾으면 null — 물어봐야 한다는 뜻이다.
  ///
  /// **저장된 경로를 먼저 본다.** 기본 위치가 이기면, 저장소 안에서 빌더를
  /// 띄웠을 때 사용자가 설정에서 바꿔둔 경로가 조용히 무시된다.
  Future<Directory?> locate() async {
    final saved = await store.read();

    for (final path in [?saved, ...candidates]) {
      final dir = Directory(path).absolute;
      if (problemWith(dir) == null) return dir;
    }
    return null;
  }

  /// 이 폴더를 템플릿으로 쓸 수 없는 이유. 쓸 수 있으면 null.
  static String? problemWith(Directory dir) {
    if (!dir.existsSync()) return '${dir.path} 가 없습니다.';

    final missing = requiredEntries.where((entry) {
      final path = p.join(dir.path, entry);
      return !File(path).existsSync() && !Directory(path).existsSync();
    }).toList();

    if (missing.isNotEmpty) {
      return '템플릿 폴더가 아닌 것 같습니다. 여기에 ${missing.join(', ')} 이(가) 없습니다.';
    }

    // 필수 항목이 있다고 이 템플릿이라는 보장은 없다. 생성기가 패키지 이름을
    // 하드코딩해 치환하므로, 다른 프로젝트를 얹으면 컴파일되지 않는 결과가
    // 나온다. 그 전에 여기서 막는다.
    final String pubspec;
    try {
      pubspec = File(p.join(dir.path, 'pubspec.yaml')).readAsStringSync();
    } on FileSystemException {
      return 'pubspec.yaml 을 읽을 수 없습니다.';
    } on FormatException {
      return 'pubspec.yaml 이 텍스트 파일이 아닙니다.';
    }

    const name = ProjectGenerator.templatePackageName;
    // 줄 전체로 본다. 부분 문자열로 보면 `name: mobile_init_project_v2` 도
    // 통과한다.
    if (!RegExp('^name:\\s*$name\\s*\$', multiLine: true).hasMatch(pubspec)) {
      return '다른 Flutter 프로젝트입니다. pubspec 의 name 이 $name 이어야 합니다.';
    }

    return null;
  }
}
