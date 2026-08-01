/// 생성이 거치는 단계.
///
/// 사용자가 "지금 멈춘 건가 도는 건가" 를 알 수 있어야 한다 — 특히 코드
/// 생성은 새 프로젝트에서 처음 돌 때 몇 분이 걸린다.
enum GenerationStep {
  scaffold('flutter create 로 뼈대 만드는 중'),
  applyTemplate('템플릿 얹는 중'),
  dependencies('의존성 받는 중'),
  localization('번역 파일 생성 중'),
  codegen('코드 생성 중 (처음이라 몇 분 걸립니다)'),
  theme('테마 생성 중');

  const GenerationStep(this.label);

  /// 화면에 그대로 띄울 수 있는 문구.
  final String label;
}

/// 생성 중에 일어난 일. UI 가 이걸 받아서 진행 상황과 로그를 보여준다.
sealed class GenerationEvent {
  const GenerationEvent();
}

/// 새 단계에 들어섰다.
final class GenerationStepStarted extends GenerationEvent {
  const GenerationStepStarted(this.step);

  final GenerationStep step;
}

/// 실행 중인 명령이 뱉은 한 줄.
final class GenerationOutput extends GenerationEvent {
  const GenerationOutput(this.line);

  final String line;
}
