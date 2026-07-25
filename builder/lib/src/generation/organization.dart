import 'generation_exception.dart';

/// 역방향 도메인. 안드로이드 applicationId 와 iOS 번들 ID 의 앞부분이 된다.
///
/// [PackageName] 과 같은 이유로 값 타입이다 — 통과하지 못한 문자열은
/// 이 타입으로 존재할 수 없다.
class Organization {
  const Organization._(this.value);

  /// 형식이 틀리면 [GenerationException] 을 던진다.
  factory Organization.parse(String raw) {
    final value = raw.trim();

    if (!_pattern.hasMatch(value)) {
      throw GenerationException(
        '"$value" 은 org 형식이 아닙니다. '
        'com.example 처럼 점으로 구분된 역방향 도메인이어야 합니다.',
      );
    }
    return Organization._(value);
  }

  final String value;

  static final _pattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is Organization && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
