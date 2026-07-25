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
  });

  final Directory projectRoot;

  /// 실패한 단계. 전부 성공했으면 null.
  final GenerationStep? failedStep;

  /// 사용자에게 그대로 보여줄 실패 원인.
  final String? failureMessage;

  bool get succeeded => failedStep == null;
}
