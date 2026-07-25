import 'dart:io' show Directory;

/// 한 번의 생성에 필요한 입력.
///
/// 옵션(플랫폼·언어·예제·테마)은 아직 없다. 뒤따르는 티켓에서 늘어난다.
class GenerationConfig {
  const GenerationConfig({
    required this.projectName,
    required this.organization,
    required this.outputParent,
    this.description = 'A new Flutter project.',
  });

  /// Dart 패키지 이름이자 폴더 이름.
  final String projectName;

  /// 역방향 도메인. 안드로이드 applicationId 와 iOS 번들 ID 의 앞부분이 된다.
  final String organization;

  /// 프로젝트가 만들어질 상위 폴더.
  final Directory outputParent;

  /// pubspec 설명. 비워두면 flutter create 의 기본 문구를 쓴다.
  final String description;
}
