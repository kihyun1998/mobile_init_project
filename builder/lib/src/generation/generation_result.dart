import 'dart:io';

import 'generation_event.dart';

/// 생성이 끝난 뒤의 상태.
///
/// 예외와 결과를 나누는 기준이 있다. **쓸 프로젝트가 아예 없으면 예외**
/// (입력이 틀렸거나 `flutter create` 자체가 실패한 경우), **프로젝트는
/// 있는데 덜 됐으면 결과** 다. 후처리가 실패해도 만들어진 것을 지우지 않고
/// 사용자가 남은 명령을 직접 이어 돌릴 수 있어야 하기 때문이다.
class GenerationResult {
  const GenerationResult({
    required this.projectRoot,
    this.failedStep,
    this.failureMessage,
    this.warnings = const [],
  });

  final Directory projectRoot;

  /// 실패한 단계. 전부 성공했으면 null.
  final GenerationStep? failedStep;

  /// 사용자에게 그대로 보여줄 실패 원인.
  final String? failureMessage;

  /// **덜 됐지만 실패는 아닌 것.** 성공과 실패 사이가 실제로 존재한다.
  ///
  /// 테마 CLI 는 0.5.0 부터 "테마는 정상적으로 썼는데 그것이 필요로 하는
  /// 무언가를 못 놓았다" 를 `2` 로 답한다 (대개 내려받지 못한 폰트). 결과물은
  /// `flutter run` 이 되므로 실패로 띄우면 거짓말이지만, Flutter 가 런타임에
  /// 조용히 기본 폰트로 떨어지므로 삼켜도 거짓말이다. 그래서 성공으로 두고
  /// 무엇이 빠졌는지를 여기에 담아 화면에 남긴다.
  final List<String> warnings;

  bool get succeeded => failedStep == null;
}
