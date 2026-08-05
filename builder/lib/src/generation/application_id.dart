import 'generation_exception.dart';
import 'organization.dart';
import 'package_name.dart';

/// 결과물의 안드로이드 applicationId.
///
/// **우리가 정하는 값이 아니라 `flutter create` 가 정하는 값을 미러링한
/// 것이다.** 우리 파이프라인은 이 문자열을 어디에도 쓰지 않는다 —
/// `--org` 와 `--project-name` 을 넘기면 상류가 만들어 `build.gradle.kts` 에
/// 박는다. 그래서 이 타입의 유일한 쓸모는 **폼이 그 결과를 미리 말해주는
/// 것**이고, 상류와 갈리는 순간 폼은 거짓말을 시작한다.
///
/// ## 왜 그냥 이어붙이기인가
///
/// 상류(`create_base.dart:557`, `CreateBase.createAndroidIdentifier`)는
/// `'$organization.$name'` 을 만든 뒤 네 가지를 더 한다.
///
/// 1. `[^\w\.]` 를 지운다
/// 2. 빈 세그먼트를 버린다
/// 3. 세그먼트가 둘 미만이면 `untitled` 를 채운다
/// 4. `^[a-zA-Z][\w]*$` 가 아닌 세그먼트 앞에 `u` 를 붙인다
///
/// **넷 다 [Organization] 과 [PackageName] 위에서는 무동작이다.** 두 값
/// 타입의 패턴이 상류의 정규화보다 좁아서, 손댈 것이 남아 있는 문자열은
/// 애초에 값 타입이 되지 못한다. 그래서 이어붙이기가 곧 상류의 결과다.
///
/// **이것이 이 클래스가 서 있는 전제이고, 조건부다** — 두 값 타입의 패턴을
/// 넓히면(대문자를 허용한다든가, 숫자로 시작하는 세그먼트를 허용한다든가)
/// 이어붙이기는 그날부터 상류와 다른 값을 내놓는다. 증상은 컴파일 오류가
/// 아니라 **폼에 적힌 applicationId 와 실제로 만들어진 applicationId 가
/// 다른 것**이고, 그건 정확히 #36 이 없애려던 사고다. `application_id_test`
/// 의 "상류가 정규화할 입력은 값 타입이 애초에 거부한다" 가 이 전제를
/// 못박고 있다.
///
/// ## iOS 번들 ID 는 이 값이 아니다
///
/// 상류는 애플 쪽에 `createUTIIdentifier` 라는 **다른 규칙**을 쓴다 —
/// 이름을 camelCase 로 바꾸고 `[^a-zA-Z0-9\-\.]` 를 지운다. 실측
/// (2026-08-05, Flutter 3.44.8): org `com.exampl.mib_gen_test` + 이름
/// `mib_gen_test` 는 applicationId 로 `com.exampl.mib_gen_test.mib_gen_test`
/// 가 되지만 `PRODUCT_BUNDLE_IDENTIFIER` 로는
/// `com.exampl.mibgentest.mibGenTest` 가 된다. 이 타입을 iOS 자리에 갖다
/// 쓰지 말 것.
class ApplicationId {
  const ApplicationId._(this.value);

  /// 값 타입 둘이 갖춰졌을 때 만들어질 applicationId.
  factory ApplicationId.of(
    Organization organization,
    PackageName projectName,
  ) => ApplicationId._('${organization.value}.${projectName.value}');

  /// 아직 값 타입이 되지 못한 입력에서 만든다. **하나라도 형식이 아니면
  /// null** 이다.
  ///
  /// 폼이 타이핑 도중에 부르는 자리라 던지지 않는다. 비어 있는 것과 형식이
  /// 틀린 것을 가르지도 않는다 — 둘 다 "아직 보여줄 것이 없다" 이고,
  /// 무엇이 잘못됐는지는 생성 버튼을 누를 때 값 타입이 말한다. 여기서
  /// 따로 말하면 **막는 자리가 화면 곳곳으로 흩어진다.**
  static ApplicationId? tryParse({
    required String organization,
    required String projectName,
  }) {
    try {
      return ApplicationId.of(
        Organization.parse(organization),
        PackageName.parse(projectName),
      );
    } on GenerationException {
      return null;
    }
  }

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is ApplicationId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
