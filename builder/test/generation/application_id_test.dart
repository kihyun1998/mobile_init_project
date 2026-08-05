import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/application_id.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';

void main() {
  group('ApplicationId', () {
    /// 실측값이다. Flutter 3.44.8 에서
    /// `flutter create --org com.exampl.mib_gen_test --project-name
    /// mib_gen_test` 를 실제로 돌려 `android/app/build.gradle.kts` 를 읽은 것이고
    /// (2026-08-05), #36 이 티켓 본문에 적어둔 값과도 같다. 여기 적힌 문자열을
    /// 계산으로 다시 만들지 않는 이유는 그러면 이 테스트가 구현을 두 번 적은
    /// 것이 되기 때문이다.
    test('org 뒤에 프로젝트 이름이 한 번 더 붙는다', () {
      expect(
        ApplicationId.of(
          Organization.parse('com.exampl.mib_gen_test'),
          PackageName.parse('mib_gen_test'),
        ).value,
        'com.exampl.mib_gen_test.mib_gen_test',
      );
    });

    test('평범한 입력도 같은 규칙이다', () {
      expect(
        ApplicationId.of(
          Organization.parse('com.example'),
          PackageName.parse('my_app'),
        ).value,
        'com.example.my_app',
      );
    });

    group('tryParse', () {
      test('둘 다 형식에 맞으면 만들어진다', () {
        expect(
          ApplicationId.tryParse(
            organization: 'io.github.kihyun1998',
            projectName: 'my_app',
          )?.value,
          'io.github.kihyun1998.my_app',
        );
      });

      test('앞뒤 공백은 값 타입이 다듬은 뒤에 이어붙인다', () {
        expect(
          ApplicationId.tryParse(
            organization: '  com.example  ',
            projectName: '  my_app  ',
          )?.value,
          'com.example.my_app',
        );
      });

      /// **비어 있는 것과 형식이 틀린 것을 가르지 않는다.** 폼은 타이핑
      /// 중에 이것을 부르므로, 두 경우 모두 "아직 보여줄 것이 없다" 이고
      /// 무엇이 잘못됐는지는 생성 버튼을 누를 때 값 타입이 말한다.
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
            ApplicationId.tryParse(organization: org, projectName: name),
            isNull,
            reason: '("$org", "$name") 이 통과했다',
          );
        }
      });
    });

    /// [ApplicationId] 가 그냥 이어붙이기인 것은 **상류가 그렇게 하기
    /// 때문이 아니라, 상류의 정규화가 우리 값 타입 위에서 전부 무동작이기
    /// 때문이다.** 그 전제가 깨지는 순간 이어붙이기는 조용히 갈린다 —
    /// 근거는 [ApplicationId] 의 doc-comment 에 있고, 이 테스트는 그 전제
    /// 자체를 못박는다.
    ///
    /// 상류(`create_base.dart:557`)가 손대는 입력은 넷이다. 넷 다 값 타입에
    /// 도달할 수 없어야 한다.
    group('상류가 정규화할 입력은 값 타입이 애초에 거부한다', () {
      test('`[A-Za-z0-9_.]` 밖의 문자 — 상류는 지운다', () {
        for (final org in ['com.exam-ple', 'com.exam ple', 'com.exam!ple']) {
          expect(
            () => Organization.parse(org),
            throwsA(anything),
            reason: '"$org" 이 통과했다',
          );
        }
        for (final name in ['my-app', 'my app', 'my!app']) {
          expect(
            () => PackageName.parse(name),
            throwsA(anything),
            reason: '"$name" 이 통과했다',
          );
        }
      });

      test('빈 세그먼트 — 상류는 접어버린다', () {
        for (final org in ['com..example', '.com.example', 'com.example.']) {
          expect(
            () => Organization.parse(org),
            throwsA(anything),
            reason: '"$org" 이 통과했다',
          );
        }
      });

      test('세그먼트가 둘 미만 — 상류는 untitled 를 채워 넣는다', () {
        expect(() => Organization.parse('com'), throwsA(anything));
      });

      test('글자로 시작하지 않는 세그먼트 — 상류는 u 를 앞에 붙인다', () {
        for (final org in ['com.2fast', '2fast.com', 'com._x']) {
          expect(
            () => Organization.parse(org),
            throwsA(anything),
            reason: '"$org" 이 통과했다',
          );
        }
        for (final name in ['2fast', '_leading']) {
          expect(
            () => PackageName.parse(name),
            throwsA(anything),
            reason: '"$name" 이 통과했다',
          );
        }
      });
    });
  });
}
