import 'application_id.dart';
import 'generation_exception.dart';
import 'organization.dart';
import 'package_name.dart';

/// 결과물의 iOS 번들 ID — `ios/Runner.xcodeproj/project.pbxproj` 의
/// `PRODUCT_BUNDLE_IDENTIFIER`.
///
/// [ApplicationId] 와 같은 이유로 존재한다. **우리가 정하는 값이 아니라
/// `flutter create` 가 정하는 값을 미러링한 것이고**, 우리 파이프라인은 이
/// 문자열을 어디에도 쓰지 않는다. 유일한 쓸모는 폼이 그 결과를 미리
/// 말해주는 것이고, 상류와 갈리는 순간 폼은 거짓말을 시작한다.
///
/// ## [ApplicationId] 와 달리, 이어붙이기가 아니다
///
/// 저쪽은 상류의 정규화가 우리 값 타입 위에서 **전부 무동작**이라 그냥
/// 이어붙이면 됐다. 이쪽은 아니다. 상류(`create_base.dart:595`,
/// `CreateBase.createUTIIdentifier`)가 하는 네 가지 중 **둘이 실제로
/// 동작한다.**
///
/// 1. **이름을 `camelCase` 로 바꾼다** — 동작한다. [PackageName] 이 밑줄을
///    허용하기 때문이다
/// 2. **`[^a-zA-Z0-9\-\.]+` 를 지운다** (정확히는 비ASCII 도 남긴다) —
///    동작한다. 우리 두 값 타입이 만들 수 있는 문자 중 이 집합 밖은
///    **밑줄뿐**이므로, 이 단계는 "남은 밑줄을 지운다" 와 같다
/// 3. 빈 세그먼트를 버린다 — 무동작. 두 값 타입의 세그먼트는 전부 글자로
///    시작하므로 밑줄을 지워도 비지 않는다
/// 4. 세그먼트가 둘 미만이면 `untitled` 를 채운다 — 무동작. [Organization]
///    이 이미 둘 이상을 강제한다
///
/// 그래서 미러링은 `밑줄 지운 org` + `.` + `밑줄 지운 camelCase(이름)` 이다.
/// 1·2 를 org 와 이름에 따로 적용해도 상류가 이어붙인 뒤에 적용한 것과 같다
/// — 밑줄을 지우는 것은 점을 만들지도 없애지도 않기 때문이다.
///
/// **org 는 `camelCase` 를 타지 않는다.** 상류가 이름에만 걸기 때문이고,
/// 그래서 org 의 밑줄은 대문자가 되지 못하고 그냥 사라진다.
///
/// ## 실측 (2026-08-08, Flutter 3.44.8, 임시 폴더에 진짜 생성)
///
/// | org | 이름 | `PRODUCT_BUNDLE_IDENTIFIER` |
/// |---|---|---|
/// | `com.example` | `my_app` | `com.example.myApp` |
/// | `com.example` | `mib_gen_test` | `com.example.mibGenTest` |
/// | `com.example` | `my__app` | `com.example.myApp` |
/// | `com.example` | `my_app_` | `com.example.myApp` |
/// | `com.example` | `ab_c` | `com.example.abc` |
/// | `com.example` | `ab_cd` | `com.example.abCd` |
/// | `com.exampl.mib_gen_test` | `mib_gen_test` | `com.exampl.mibgentest.mibGenTest` |
///
/// **마지막 두 줄이 서로 다른 것이 이 타입의 핵심이다.** `ab_c` 는 `abC` 가
/// 아니라 `abc` 다 — 뒤 글자가 대문자가 되지 못하고 밑줄만 사라진다.
/// 자세한 것은 [_camelCase] 의 doc-comment.
class BundleIdentifier {
  const BundleIdentifier._(this.value);

  /// 값 타입 둘이 갖춰졌을 때 만들어질 번들 ID.
  factory BundleIdentifier.of(
    Organization organization,
    PackageName projectName,
  ) => BundleIdentifier._(
    '${_stripUnderscores(organization.value)}'
    '.'
    '${_stripUnderscores(_camelCase(projectName.value))}',
  );

  /// 아직 값 타입이 되지 못한 입력에서 만든다. **하나라도 형식이 아니면
  /// null** 이다.
  ///
  /// [ApplicationId.tryParse] 와 같은 계약이다 — 폼이 타이핑 도중에 부르는
  /// 자리라 던지지 않고, 비어 있는 것과 형식이 틀린 것을 가르지도 않는다.
  static BundleIdentifier? tryParse({
    required String organization,
    required String projectName,
  }) {
    try {
      return BundleIdentifier.of(
        Organization.parse(organization),
        PackageName.parse(projectName),
      );
    } on GenerationException {
      return null;
    }
  }

  final String value;

  /// 상류 `camelCase` (`flutter_tools/lib/src/base/utils.dart:24`) 를 **줄
  /// 단위로 옮긴 것**이다. "밑줄을 지우고 다음 글자를 대문자로" 라고 요약해서
  /// 다시 적지 않은 이유는, 그 요약이 **틀리기 때문**이다.
  ///
  /// 루프 조건의 `index < str.length - 2` 가 그 자리다. 밑줄 **뒤에 글자가
  /// 둘 이상 남아 있을 때만** 대문자로 올린다. 하나뿐이면 루프가 그냥
  /// 끝나고, 그 밑줄은 대문자를 만들지 못한 채 다음 단계에서 지워진다.
  ///
  /// 실측이 이 갈림을 잡았다 (2026-08-08):
  ///
  /// - `ab_c` → `ab_c` (루프 무동작) → 밑줄 제거 → **`abc`**
  /// - `ab_cd` → **`abCd`**
  ///
  /// 한 글자 차이로 결과가 갈린다. 요약해서 옮겼으면 `abC` 를 내놓았을 것이고
  /// 컴파일도 테스트도 통과했을 것이다 — 그 경우를 안 적었을 테니까.
  ///
  /// 연속된 밑줄도 이 루프가 알아서 처리한다. `my__app` 에서는 밑줄 다음
  /// 글자가 또 밑줄이라 `toUpperCase()` 가 무동작이고, 그 결과 `my_app` 이
  /// 되어 다음 회차에 `myApp` 이 된다.
  static String _camelCase(String raw) {
    var str = raw;
    var index = str.indexOf('_');
    while (index != -1 && index < str.length - 2) {
      str =
          str.substring(0, index) +
          str.substring(index + 1, index + 2).toUpperCase() +
          str.substring(index + 2);
      index = str.indexOf('_');
    }
    return str;
  }

  /// 상류의 `[^a-zA-Z0-9\-\.]+` 제거를 우리 값 타입 위에서만 다시 적은
  /// 것이다. 두 값 타입이 만들 수 있는 문자 중 그 집합 밖은
  /// 밑줄뿐이라 이것으로 충분하고, **그 전제는 클래스 doc-comment 의 2번**
  /// 이자 `bundle_identifier_test.dart` 가 못박고 있는 것이다.
  static String _stripUnderscores(String value) => value.replaceAll('_', '');

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is BundleIdentifier && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
