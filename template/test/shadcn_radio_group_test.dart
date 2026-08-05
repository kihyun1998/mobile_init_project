import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_radio_group.dart';

/// `ShadcnRadioGroup` 은 `RawRadio` + `RadioGroup` 위에 앉아 있다.
///
/// **손으로 `Semantics` 를 붙이지 않은 이유가 이 파일의 절반이다.** 교체 전
/// 실측(#26, 2026-08-05)에서 항목이 `flags=[]` `actions=[tap]` 으로 나갔다 —
/// 플래그가 하나도 없었다. 그런데 손으로 붙였다면 **틀리게 붙였을 것이다**:
/// `RawRadio` (`widgets/raw_radio.dart:200-229`) 는 `selected` 와 `hint` 를
/// **플랫폼마다 다르게** 싣는다.
///
/// | 플랫폼 | `checked` | `selected` | `hint` |
/// |---|---|---|---|
/// | android · linux · windows | 값 | **null** | **null** |
/// | ios · macos | 값 | 값 | 안 골라진 것에만 `radioButtonUnselectedLabel` |
///
/// 상류 주석이 이유를 적어둔다 — iOS 는 `selected` 로 이미 알리므로 둘 다 세우면
/// 중복 안내가 된다. **이건 모바일 템플릿이라 두 분기가 다 나간다.**
///
/// 플랫폼은 `variant:` 로 바꾼다. **`ThemeData.platform` 을 바꾸는 것으로는 안
/// 된다** — `RawRadio` 는 전역 `defaultTargetPlatform` 을 보므로, 테마만 바꾸면
/// iOS 분기가 아예 안 돌면서 테스트는 초록이 된다. 실제로 그렇게 썼다가 hint 가
/// 빈 문자열로 나와서 드러났다. `debugDefaultTargetPlatformOverride` 를 직접
/// 세우는 것도 안 된다 — 프레임워크의 불변식 검사가 `addTearDown` 보다 먼저 돌아
/// "debug 변수를 되돌리지 않았다" 로 터진다.
Future<void> pump(WidgetTester tester, Widget child, {Locale? locale}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: TweakcnTheme.light,
        locale: locale,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('ko')],
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _items = [
  ShadcnRadioItem(value: 'card', label: '카드', description: '신용/체크카드로 결제합니다'),
  ShadcnRadioItem(value: 'bank', label: '계좌이체'),
];

Widget radios({String? value = 'card', ValueChanged<String>? onChanged}) =>
    ShadcnRadioGroup<String>(
      value: value,
      onChanged: onChanged ?? (_) {},
      items: _items,
    );

final _android = TargetPlatformVariant.only(TargetPlatform.android);
final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  group('공개 API 는 그대로다', () {
    testWidgets('안 골라진 것을 누르면 그 값이 콜백으로 온다', (tester) async {
      final picked = <String>[];
      await pump(tester, radios(onChanged: picked.add));

      await tester.tap(find.text('계좌이체'));
      await tester.pumpAndSettle();

      expect(picked, ['bank']);
    });

    testWidgets('타일 전체가 눌린다 — 동그라미만이 아니라', (tester) async {
      // 교체 전에는 `GestureDetector` 가 타일 전체를 감싸고 있었다. 설명 문구를
      // 눌러도 골라지던 것이 그대로여야 한다.
      final picked = <String>[];
      await pump(tester, radios(value: 'bank', onChanged: picked.add));

      await tester.tap(find.text('신용/체크카드로 결제합니다'));
      await tester.pumpAndSettle();

      expect(picked, ['card']);
    });

    testWidgets('이미 골라진 것을 다시 눌러도 선택이 지워지지 않는다', (tester) async {
      // `toggleable: false`. 지워지면 `RadioGroup` 이 null 을 올려보내는데 우리
      // 표면은 `ValueChanged<T>` 라 받을 자리가 없다.
      final picked = <String>[];
      await pump(tester, radios(onChanged: picked.add));

      await tester.tap(find.text('카드'));
      await tester.pumpAndSettle();

      expect(picked, isEmpty);
    });

    testWidgets('onChanged 가 null 이면 눌러도 아무 일도 없다', (tester) async {
      await pump(
        tester,
        const ShadcnRadioGroup<String>(
          value: 'card',
          onChanged: null,
          items: _items,
        ),
      );

      await tester.tap(find.text('계좌이체'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('아무것도 안 골라진 상태로도 그려진다', (tester) async {
      await pump(tester, radios(value: null));

      expect(tester.takeException(), isNull);
      expect(find.text('카드'), findsOneWidget);
    });
  });

  group('스크린 리더에 역할과 상태가 나간다', () {
    // 교체 전 실측(#26): `flags=[]` `actions=[tap]`. 플래그가 하나도 없었다.
    testWidgets('골라진 항목이 checked 와 배타 그룹을 싣는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, radios());

      expect(
        tester.getSemantics(find.text('카드')),
        matchesSemantics(
          label: '카드\n신용/체크카드로 결제합니다',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    }, variant: _android);

    testWidgets('안 골라진 항목은 checked 가 내려간 채로 나간다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, radios());

      expect(
        tester.getSemantics(find.text('계좌이체')),
        matchesSemantics(
          label: '계좌이체',
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    }, variant: _android);

    testWidgets('라벨과 설명이 한 노드로 합쳐진다', (tester) async {
      // Material 의 `RadioListTile` 이 같은 자리에 싣는 것과 글자까지 같다
      // (#26 의 대조 측정). 스크린 리더가 항목 하나로 읽는다.
      final handle = tester.ensureSemantics();
      await pump(tester, radios());

      expect(tester.getSemantics(find.text('카드')).label, '카드\n신용/체크카드로 결제합니다');
      handle.dispose();
    }, variant: _android);

    testWidgets('onChanged 가 null 이면 enabled 가 내려가고 탭·포커스가 사라진다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const ShadcnRadioGroup<String>(
          value: 'card',
          onChanged: null,
          items: _items,
        ),
      );

      expect(
        tester.getSemantics(find.text('계좌이체')),
        matchesSemantics(
          label: '계좌이체',
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    }, variant: _android);
  });

  group('플랫폼마다 다르게 나간다 — 손으로 붙였으면 틀렸을 자리', () {
    // `matchesSemantics` 는 적지 않은 플래그를 전부 false 로, hint 를 빈
    // 문자열로 본다. 그래서 아래 두 테스트는 **없는 것까지** 못박는다.
    testWidgets('android 는 selected 도 hint 도 안 싣는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, radios());

      expect(
        tester.getSemantics(find.text('계좌이체')),
        matchesSemantics(
          label: '계좌이체',
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    }, variant: _android);

    testWidgets('ios 는 selected 를 싣고 안 골라진 것에만 hint 를 붙인다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, radios());

      expect(
        tester.getSemantics(find.text('계좌이체')),
        matchesSemantics(
          label: '계좌이체',
          // 상류가 들고 있는 문구다. 우리 arb 에는 없다 — 손으로 붙였으면
          // 이것을 직접 만들고 언어마다 관리해야 했다.
          hint: 'Not selected',
          hasCheckedState: true,
          isChecked: false,
          hasSelectedState: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          // `isFocusable` 은 있는데 **`focus` 액션은 없다.** 우리 것도
          // 라디오 것도 아니고 Flutter 가 iOS 에서 통째로 빼는 것이다:
          //   `widgets/focus_scope.dart:721-723`
          //   onFocus: defaultTargetPlatform != TargetPlatform.iOS && …
          // (상류에 TODO 가 달려 있다.) 실측으로 확인했고, 안드로이드에서는
          // 위 테스트가 `hasFocusAction: true` 를 요구한다.
          isFocusable: true,
          hasTapAction: true,
        ),
      );

      // 골라진 것에는 hint 가 없다 — `selected` 가 이미 알리므로 중복이다.
      expect(tester.getSemantics(find.text('카드')).hint, isEmpty);
      handle.dispose();
    }, variant: _ios);

    testWidgets('그 hint 는 한국어로도 나온다 — 우리가 번역하지 않았는데', (tester) async {
      // `flutter_localizations` 가 이미 들고 있다
      // (`l10n/widgets_ko.arb` 의 `radioButtonUnselectedLabel`).
      // 프레임워크 기본형 위에 앉는 것의 값이 여기서 보인다.
      final handle = tester.ensureSemantics();
      await pump(tester, radios(), locale: const Locale('ko'));

      expect(tester.getSemantics(find.text('계좌이체')).hint, '선택되지 않음');
      handle.dispose();
    }, variant: _ios);
  });

  group('색과 모양이 그대로다', () {
    BoxDecoration tileBox(WidgetTester tester, String label) =>
        tester
                .widgetList<Container>(
                  find.ancestor(
                    of: find.text(label),
                    matching: find.byType(Container),
                  ),
                )
                .last
                .decoration!
            as BoxDecoration;

    testWidgets('골라진 타일은 ring 테두리, 아니면 border 다', (tester) async {
      await pump(tester, radios());
      const colors = TweakcnColors.light;

      expect((tileBox(tester, '카드').border! as Border).top.color, colors.ring);
      expect(
        (tileBox(tester, '계좌이체').border! as Border).top.color,
        colors.border,
      );
      // 두 토큰이 실제로 달라야 위 두 assert 가 서로를 구분한다.
      expect(colors.ring, isNot(colors.border));
    });
  });
}
