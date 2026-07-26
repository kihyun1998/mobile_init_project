import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/localization/generated/l10n.dart';
import 'package:mobile_init_project/core/localization/provider/locale_state_provider.dart';

/// 지원 언어가 하나로 줄어든 프로젝트에서도 앱이 성립하는지 본다.
///
/// 빌더가 안 쓰는 arb 를 지우고 l10n 을 재생성하면 [S] 가 지원하는 언어가
/// 줄어든다. 그때 기본값·전환이 목록 밖으로 나가면, 번역이 없는 화면이 뜨거나
/// 눌러도 아무 일이 없는 버튼이 남는다.
void main() {
  const ko = Locale('ko');
  const en = Locale('en');

  group('기본 언어 고르기', () {
    test('한국어가 있으면 한국어다', () {
      expect(LocaleState.defaultAmong([en, ko]), ko);
      expect(LocaleState.defaultAmong([ko, en]), ko);
    });

    test('한국어가 없으면 남은 것 중 첫 번째다', () {
      expect(LocaleState.defaultAmong([en]), en);
    });
  });

  group('다음 언어로 넘어가기', () {
    test('둘이면 서로를 오간다', () {
      expect(LocaleState.nextAmong([ko, en], ko), en);
      expect(LocaleState.nextAmong([ko, en], en), ko);
    });

    test('셋이면 순환한다', () {
      const ja = Locale('ja');
      expect(LocaleState.nextAmong([ko, en, ja], en), ja);
      expect(LocaleState.nextAmong([ko, en, ja], ja), ko);
    });

    test('하나뿐이면 갈 곳이 없다', () {
      // 이 경우 예제 화면은 언어 버튼 자체를 감춘다.
      expect(LocaleState.nextAmong([ko], ko), isNull);
    });

    test('지원하지 않는 언어에서 출발하면 갈 곳이 없다', () {
      // 0번으로 슬쩍 되돌리면 버튼이 어디로 갈지 설명할 수 없게 된다.
      expect(LocaleState.nextAmong([ko, en], const Locale('ja')), isNull);
    });
  });

  test('지원 언어는 생성된 delegate 가 정한다', () {
    // 목록을 손으로 들고 있으면 arb 를 빼고 재생성했을 때 조용히 어긋난다.
    expect(LocaleState.supportedLocales, S.delegate.supportedLocales);
    expect(LocaleState.isSupported(ko), isTrue);
    expect(LocaleState.isSupported(const Locale('ja')), isFalse);
  });
}
