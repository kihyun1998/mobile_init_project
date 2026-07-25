import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/generation/generation_exception.dart';
import 'package:mobile_init_builder/src/generation/organization.dart';
import 'package:mobile_init_builder/src/generation/package_name.dart';

void main() {
  group('PackageName', () {
    test('올바른 이름은 통과한다', () {
      for (final good in ['my_app', 'a', 'app2', 'my_app_2']) {
        expect(PackageName.parse(good).value, good);
      }
    });

    test('앞뒤 공백은 다듬는다', () {
      expect(PackageName.parse('  my_app  ').value, 'my_app');
    });

    test('형식이 틀리면 만들어지지 않는다', () {
      for (final bad in ['My-App', '2fast', 'my app', '', '_leading', 'a-b']) {
        expect(
          () => PackageName.parse(bad),
          throwsA(isA<GenerationException>()),
          reason: '"$bad" 이 통과했다',
        );
      }
    });

    test('예약된 이름은 거부한다', () {
      for (final reserved in ['class', 'for', 'flutter', 'test']) {
        expect(
          () => PackageName.parse(reserved),
          throwsA(isA<GenerationException>()),
          reason: '"$reserved" 가 통과했다',
        );
      }
    });

    test('오류 문구가 무엇이 잘못됐는지 말해준다', () {
      expect(
        () => PackageName.parse('My-App'),
        throwsA(
          isA<GenerationException>().having(
            (e) => e.message,
            'message',
            allOf(contains('My-App'), contains('소문자')),
          ),
        ),
      );
    });
  });

  group('Organization', () {
    test('점으로 구분된 역방향 도메인은 통과한다', () {
      for (final good in ['com.example', 'io.github.kihyun1998', 'a.b.c.d']) {
        expect(Organization.parse(good).value, good);
      }
    });

    test('점이 없거나 형식이 틀리면 거부한다', () {
      for (final bad in ['nodots', 'Com.Example', 'com.', '.com', '', 'a..b']) {
        expect(
          () => Organization.parse(bad),
          throwsA(isA<GenerationException>()),
          reason: '"$bad" 이 통과했다',
        );
      }
    });
  });
}
