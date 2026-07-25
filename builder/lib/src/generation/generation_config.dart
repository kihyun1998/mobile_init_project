import 'dart:io' show Directory;

import 'organization.dart';
import 'package_name.dart';

/// 한 번의 생성에 필요한 입력.
///
/// 이름과 org 는 값 타입이라, 이 객체가 만들어졌다는 것 자체가 형식 검증을
/// 통과했다는 뜻이다. 남은 검증(템플릿이 있는가, 대상 폴더가 비었는가)은
/// 파일시스템에 의존하므로 생성기 몫이다.
///
/// 옵션(플랫폼·언어·예제·테마)은 아직 없다. 뒤따르는 티켓에서 늘어난다.
class GenerationConfig {
  const GenerationConfig({
    required this.projectName,
    required this.organization,
    required this.outputParent,
    this.description = defaultDescription,
  });

  static const defaultDescription = 'A new Flutter project.';

  /// Dart 패키지 이름이자 폴더 이름.
  final PackageName projectName;

  /// 역방향 도메인.
  final Organization organization;

  /// 프로젝트가 만들어질 상위 폴더.
  final Directory outputParent;

  /// pubspec 설명. 형식 규칙이 없는 자유 문구다.
  final String description;
}
