import 'generation_exception.dart';

/// Dart 패키지 이름. 생성될 프로젝트의 폴더 이름이기도 하다.
///
/// 값 타입으로 두는 이유는 **잘못된 이름으로는 만들어질 수조차 없게** 하기
/// 위해서다. 검증을 어딘가에서 호출해주기를 기대하는 대신, 타입이 존재한다는
/// 사실 자체가 규칙을 통과했다는 증거가 된다.
class PackageName {
  const PackageName._(this.value);

  /// 형식이 틀리면 [GenerationException] 을 던진다.
  factory PackageName.parse(String raw) {
    final value = raw.trim();

    if (!_pattern.hasMatch(value)) {
      throw GenerationException(
        '"$value" 은 Dart 패키지 이름으로 쓸 수 없습니다. '
        '소문자로 시작하고 소문자·숫자·밑줄만 쓸 수 있습니다.',
      );
    }
    if (_reserved.contains(value)) {
      throw GenerationException('"$value" 은 예약된 이름이라 쓸 수 없습니다.');
    }
    return PackageName._(value);
  }

  final String value;

  static final _pattern = RegExp(r'^[a-z][a-z0-9_]*$');

  /// Dart 예약어와, 패키지 이름으로 쓰면 도구가 헷갈리는 것들.
  static const _reserved = {
    'assert',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'extends',
    'false',
    'final',
    'finally',
    'for',
    'if',
    'in',
    'is',
    'new',
    'null',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'var',
    'void',
    'while',
    'with',
    'flutter',
    'test',
  };

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is PackageName && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
