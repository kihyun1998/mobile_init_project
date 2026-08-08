import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/bundle_identifier.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';

void main() {
  group('BundleIdentifier', () {
    /// **전부 실측값이다.** 2026-08-08, Flutter 3.44.8 에서 각 줄마다
    /// `flutter create --org <org> --project-name <name> --platforms=ios` 를
    /// 임시 폴더에 진짜 돌리고 `ios/Runner.xcodeproj/project.pbxproj` 의
    /// `PRODUCT_BUNDLE_IDENTIFIER` 를 읽은 것이다.
    ///
    /// 여기 적힌 문자열을 규칙으로 다시 계산하지 않는 이유는 그러면 이 테스트가
    /// 구현을 두 번 적은 것이 되기 때문이다 (`application_id_test.dart` 와
    /// 같은 이유).
    group('상류가 만드는 값과 같다', () {
      const measured = <(String org, String name, String bundleId)>[
        ('com.example', 'my_app', 'com.example.myApp'),
        ('com.example', 'mib_gen_test', 'com.example.mibGenTest'),
        ('com.example', 'my__app', 'com.example.myApp'),
        ('com.example', 'my_app_', 'com.example.myApp'),
        ('com.example', 'ab_c', 'com.example.abc'),
        ('com.example', 'ab_cd', 'com.example.abCd'),
        (
          'com.exampl.mib_gen_test',
          'mib_gen_test',
          'com.exampl.mibgentest.mibGenTest',
        ),
      ];

      for (final (org, name, bundleId) in measured) {
        test('$org + $name → $bundleId', () {
          expect(
            BundleIdentifier.of(
              Organization.parse(org),
              PackageName.parse(name),
            ).value,
            bundleId,
          );
        });
      }
    });

    /// 이 둘이 갈리는 것이 `camelCase` 를 요약해서 옮기면 안 되는 이유다.
    /// 상류 루프의 `index < str.length - 2` 때문에 **밑줄 뒤에 글자가 하나뿐이면
    /// 대문자가 되지 못하고** 그냥 지워진다.
    ///
    /// "밑줄을 지우고 다음 글자를 대문자로" 라고 요약해 옮겼다면 `ab_c` 가
    /// `abC` 가 됐을 것이고, 그 경우를 안 적었을 테니 초록으로 지나갔을 것이다.
    test('밑줄 뒤 글자가 하나뿐이면 대문자가 되지 않는다', () {
      String bundleIdOf(String name) => BundleIdentifier.of(
        Organization.parse('com.example'),
        PackageName.parse(name),
      ).value;

      expect(bundleIdOf('ab_c'), 'com.example.abc');
      expect(bundleIdOf('ab_cd'), 'com.example.abCd');
    });

    /// org 는 `camelCase` 를 타지 않는다 — 상류가 이름에만 건다. 그래서 org 의
    /// 밑줄은 대문자가 되지 못하고 사라지기만 한다.
    test('org 의 밑줄은 대문자가 되지 않고 사라진다', () {
      expect(
        BundleIdentifier.of(
          Organization.parse('com.exampl.mib_gen_test'),
          PackageName.parse('app'),
        ).value,
        'com.exampl.mibgentest.app',
      );
    });

    test('밑줄이 없으면 applicationId 와 같아진다', () {
      expect(
        BundleIdentifier.of(
          Organization.parse('io.github.kihyun'),
          PackageName.parse('myapp'),
        ).value,
        'io.github.kihyun.myapp',
      );
    });

    group('tryParse', () {
      test('둘 다 형식에 맞으면 만들어진다', () {
        expect(
          BundleIdentifier.tryParse(
            organization: 'io.github.kihyun1998',
            projectName: 'my_app',
          )?.value,
          'io.github.kihyun1998.myApp',
        );
      });

      test('앞뒤 공백은 값 타입이 다듬은 뒤에 계산한다', () {
        expect(
          BundleIdentifier.tryParse(
            organization: '  com.example  ',
            projectName: '  my_app  ',
          )?.value,
          'com.example.myApp',
        );
      });

      /// `ApplicationId.tryParse` 와 같은 계약이다 — 비어 있는 것과 형식이
      /// 틀린 것을 가르지 않는다. 둘 다 "아직 보여줄 것이 없다" 이다.
      test('둘 중 하나라도 값 타입이 못 되면 null 이다', () {
        const cases = <(String org, String name)>[
          ('', 'my_app'),
          ('com.example', ''),
          ('', ''),
          ('nodots', 'my_app'),
          ('com.example', 'My-App'),
          ('Com.Example', 'my_app'),
          ('com.example', 'flutter'),
        ];

        for (final (org, name) in cases) {
          expect(
            BundleIdentifier.tryParse(organization: org, projectName: name),
            isNull,
            reason: '("$org", "$name") 이 통과했다',
          );
        }
      });
    });

    /// [BundleIdentifier] 의 미러링은 **"우리 값 타입이 만들 수 있는 문자 중
    /// 상류가 지우는 것은 밑줄뿐"** 이라는 전제 위에 서 있다. 그 전제가
    /// 깨지면 `_stripUnderscores` 가 조용히 모자라진다 — 증상은 컴파일 오류가
    /// 아니라 **폼에 적힌 번들 ID 와 실제로 만들어진 번들 ID 가 다른 것**이다.
    ///
    /// 상류가 남기는 집합은 `[a-zA-Z0-9\-\.]` 와 비ASCII 다. 두 값 타입이
    /// 낼 수 있는 문자는 `[a-z0-9_.]` 뿐이므로, 겹치지 않는 것은 밑줄 하나다.
    test('값 타입이 만들 수 있는 문자 중 상류가 지우는 것은 밑줄뿐이다', () {
      const survives = r'abcdefghijklmnopqrstuvwxyz0123456789.';

      for (final char in survives.split('')) {
        expect(
          RegExp(r'[a-zA-Z0-9\-\.]').hasMatch(char),
          isTrue,
          reason: '"$char" 은 값 타입이 낼 수 있는데 상류가 지운다',
        );
      }

      expect(RegExp(r'[a-zA-Z0-9\-\.]').hasMatch('_'), isFalse);
    });
  });
}
