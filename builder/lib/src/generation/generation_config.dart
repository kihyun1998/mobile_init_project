import 'dart:io' show Directory;

import 'app_language.dart';
import 'organization.dart';
import 'package_name.dart';
import 'project_platform.dart';

/// 한 번의 생성에 필요한 입력.
///
/// 이름·org·플랫폼은 값 타입이라, 이 객체가 만들어졌다는 것 자체가 형식 검증을
/// 통과했다는 뜻이다. 남은 검증(템플릿이 있는가, 대상 폴더가 비었는가)은
/// 파일시스템에 의존하므로 생성기 몫이다.
///
/// 형식 규칙이 없는 자유 문구(설명·표시 이름)는 **빈 값을 여기서 기본값으로
/// 바꾼다.** 화면과 생성기가 각자 `isEmpty ? ... : ...` 를 들고 있으면 둘이
/// 어긋나는 날이 온다.
///
/// 붙여넣은 테마를 반영하는 것은 아직 없다. 뒤따르는 티켓에서 붙는다.
class GenerationConfig {
  GenerationConfig({
    required this.projectName,
    required this.organization,
    required this.outputParent,
    this.platforms = PlatformSelection.mobile,
    this.languages = LanguageSelection.all,
    this.includeExample = true,
    String description = '',
    String displayName = '',
  })  : description = _or(description, defaultDescription),
        displayName = _or(displayName, projectName.value);

  static const defaultDescription = 'A new Flutter project.';

  /// Dart 패키지 이름이자 폴더 이름.
  final PackageName projectName;

  /// 역방향 도메인.
  final Organization organization;

  /// 프로젝트가 만들어질 상위 폴더.
  final Directory outputParent;

  /// 만들 플랫폼. 고르지 않은 것은 폴더조차 생기지 않는다.
  final PlatformSelection platforms;

  /// 결과물이 지원할 언어. 고르지 않은 언어의 arb 는 지우고 l10n 을
  /// 재생성한다 — 생성 파일을 손으로 고치지 않는다.
  final LanguageSelection languages;

  /// 컴포넌트 쇼케이스를 결과물에 남길지. 끄면 홈 화면이 빈 스텁이 되고
  /// 예제에서만 쓰던 의존성도 빠진다. shadcn 컴포넌트는 끄든 켜든 남는다.
  final bool includeExample;

  /// pubspec 설명. 비워서 넣으면 기본 문구가 들어온다.
  final String description;

  /// 사람이 보는 앱 이름. 홈 화면 아이콘 밑과 앱 타이틀에 들어간다.
  /// 비워서 넣으면 프로젝트 이름이 들어온다.
  final String displayName;

  static String _or(String raw, String fallback) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
