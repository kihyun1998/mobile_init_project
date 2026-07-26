import 'generation_exception.dart';

/// `flutter create --platforms` 가 받는 플랫폼.
///
/// [flag] 는 인자에 들어가는 값이자 만들어지는 폴더 이름이다. 둘이 같기 때문에
/// "고르지 않은 플랫폼 폴더가 없다" 를 폴더 이름으로 바로 확인할 수 있다.
enum ProjectPlatform {
  android('android', '안드로이드'),
  ios('ios', 'iOS'),
  macos('macos', 'macOS'),
  windows('windows', 'Windows'),
  linux('linux', 'Linux'),
  web('web', '웹');

  const ProjectPlatform(this.flag, this.label);

  final String flag;
  final String label;
}

/// 고른 플랫폼. **비어 있는 선택은 만들 수 없다.**
///
/// `--platforms=` 를 빈 값으로 넘기면 flutter 가 한참 뒤에야 알아듣기 힘든
/// 소리를 하므로, 그 전에 여기서 막는다. [PackageName] 과 같은 규칙이다 —
/// 이 객체가 있다는 것 자체가 최소 하나를 골랐다는 뜻이다.
class PlatformSelection {
  const PlatformSelection._(this.platforms);

  factory PlatformSelection.of(Iterable<ProjectPlatform> platforms) {
    final chosen = platforms.toSet();
    // 선언 순서로 정렬한다. 체크박스를 누른 순서에 따라 명령줄이 달라지면
    // 같은 선택인데 매번 다른 명령으로 보인다.
    final ordered = ProjectPlatform.values
        .where(chosen.contains)
        .toList(growable: false);

    if (ordered.isEmpty) {
      throw const GenerationException('플랫폼을 하나 이상 골라야 합니다.');
    }
    return PlatformSelection._(ordered);
  }

  /// 템플릿이 모바일 앱이므로 기본값도 모바일이다.
  static const mobile = PlatformSelection._([
    ProjectPlatform.android,
    ProjectPlatform.ios,
  ]);

  final List<ProjectPlatform> platforms;

  /// `--platforms` 에 넘길 값.
  String get flags => platforms.map((p) => p.flag).join(',');
}
