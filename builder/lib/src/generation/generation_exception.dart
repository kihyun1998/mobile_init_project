/// 생성을 시작할 수 없거나 도중에 실패했을 때 던진다.
///
/// [message] 는 사용자에게 그대로 보여줄 수 있는 문장이어야 한다.
class GenerationException implements Exception {
  const GenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
