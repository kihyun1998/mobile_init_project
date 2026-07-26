import 'generation_exception.dart';

/// 열거형에서 고른 것을 선언 순서로 정렬하고, 비어 있으면 던진다.
///
/// 플랫폼과 언어가 같은 규칙을 쓴다. 순서를 정규화하는 이유는 체크박스를 누른
/// 순서에 따라 결과물이 달라지지 않게 하려는 것이다 — `--platforms` 인자도
/// `main_locale` 도 목록의 순서에서 나온다.
List<T> orderedNonEmpty<T>(
  Iterable<T> chosen,
  List<T> declarationOrder,
  String emptyMessage,
) {
  final picked = chosen.toSet();
  final ordered =
      declarationOrder.where(picked.contains).toList(growable: false);

  if (ordered.isEmpty) throw GenerationException(emptyMessage);
  return ordered;
}
