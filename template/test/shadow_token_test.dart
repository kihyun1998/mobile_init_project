import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_button.dart';
import 'package:mobile_init_project/ui/components/shadcn_card.dart';
import 'package:mobile_init_project/ui/components/shadcn_checkbox.dart';
import 'package:mobile_init_project/ui/components/shadcn_date_picker.dart';
import 'package:mobile_init_project/ui/components/shadcn_input.dart';
import 'package:mobile_init_project/ui/components/shadcn_radio_group.dart';
import 'package:mobile_init_project/ui/components/shadcn_shadow.dart';
import 'package:mobile_init_project/ui/components/shadcn_switch.dart';

/// 붙여넣은 CSS 의 `--shadow-*` 가 컴포넌트까지 실제로 도달하는지 본다.
///
/// **템플릿 CSS 로는 이걸 볼 수 없다.** 거기서는 `--shadow-sm` 과 `--shadow`
/// 가 값이 같고 light 와 dark 도 서로 같다 (`tweakcn.css:44-51, 99-106`).
/// 단계를 잘못 골라도 티가 안 난다 — 자기 자신을 오독할 수 있는 측정이다.
/// 그래서 단계마다 서로 다른 값을 넣는다. `radius_token_test.dart` 가
/// `fromRadius(20)` 을 쓰는 것과 같은 이유다.
///
/// 어느 컴포넌트가 어느 단계를 쓰는지는 우리가 정한 것이 아니라 shadcn 원본을
/// 실측한 것이다 (#25). 출처는 각 테스트에 `file:line` 으로 적어 둔다.
TweakcnShadowLayer _layer(double y, double blur) => (
  offsetX: 0,
  offsetY: y,
  blurRadius: blur,
  spreadRadius: 0,
  color: 0x33000000,
);

final _distinct = TweakcnShadows.fromShadowMap({
  'shadow-xs': [_layer(11, 21)],
  'shadow-sm': [_layer(12, 22)],
  'shadow-md': [_layer(13, 23)],
  'shadow-lg': [_layer(14, 24)],
});

ThemeData get _theme => ThemeData(
  brightness: Brightness.light,
  extensions: [TweakcnColors.light, TweakcnRadius.standard, _distinct],
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en')],
        theme: _theme,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// [inside] 밑의 상자마다 그 상자가 그리는 `BoxShadow` 들. 바깥→안 순서.
///
/// `Container` 만 보지 않고 `DecoratedBox` 를 본다 — `Container` 도
/// `AnimatedContainer` 도 결국 이걸로 그리므로 셋을 한 번에 덮는다.
///
/// **평평하게 합치지 않는 이유:** 합치면 "이 컴포넌트 어딘가에 그림자가
/// 하나 있다" 까지만 말하고 **어느 상자에** 있는지는 말하지 않는다. 스위치는
/// 그게 정확히 결정의 내용이라(트랙이냐 엄지냐) 구별 못 하면 테스트 이름이
/// 주장하는 것과 재는 것이 갈린다 — 실제로 변이로 확인했다: 그림자를 트랙에서
/// 엄지로 되돌려도 합친 버전은 **초록이었다.** `matchesSemantics` 가 자식
/// 노드를 안 봐서 `childrenCount` 를 함께 보게 된 것(#26)과 같은 모양이다.
List<List<BoxShadow>> _shadowsPerBox(WidgetTester tester, Finder inside) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(of: inside, matching: find.byType(DecoratedBox)),
  ))
    (box.decoration as BoxDecoration).boxShadow ?? const <BoxShadow>[],
];

/// [inside] 밑에서 그려지는 모든 `BoxShadow`, 그린 순서대로.
///
/// 상자가 하나뿐이거나 "아무 데도 없다" 를 말할 때만 쓴다. 어느 상자인지가
/// 결정의 일부이면 [_shadowsPerBox] 를 쓴다.
List<BoxShadow> _shadowsIn(WidgetTester tester, Finder inside) =>
    _shadowsPerBox(tester, inside).expand((e) => e).toList();

void main() {
  group('그림자 토큰을 읽는 컴포넌트', () {
    testWidgets('카드는 shadow-sm 을 쓴다', (tester) async {
      // card.tsx:10 — `shadow-sm`.
      await _pump(tester, const ShadcnCard(title: 'Card'));
      expect(_shadowsIn(tester, find.byType(ShadcnCard)), _distinct.shadowSm.r);
    });

    testWidgets('입력은 shadow-xs 를 쓴다', (tester) async {
      // input.tsx:11 — `shadow-xs`.
      await _pump(tester, const ShadcnInput());
      expect(
        _shadowsIn(tester, find.byType(ShadcnInput)),
        _distinct.shadowXs.r,
      );
    });

    testWidgets('outline 버튼은 shadow-xs 를 쓴다', (tester) async {
      // button.tsx:16 — `outline` 변형에만 `shadow-xs` 가 붙는다.
      await _pump(
        tester,
        ShadcnButton(
          variant: ShadcnButtonVariant.outline,
          onPressed: () {},
          child: const Text('Save'),
        ),
      );
      expect(
        _shadowsIn(tester, find.byType(ShadcnButton)),
        _distinct.shadowXs.r,
      );
    });

    testWidgets('라디오 표시기는 shadow-xs 를 쓴다', (tester) async {
      // radio-group.tsx:30 — 동그라미 표시기에 붙는다. 우리 타일은 원본에
      // 없는 것이라 그림자를 받지 않는다.
      await _pump(
        tester,
        ShadcnRadioGroup<String>(
          value: 'a',
          onChanged: (_) {},
          items: const [
            ShadcnRadioItem(value: 'a', label: 'A'),
            ShadcnRadioItem(value: 'b', label: 'B'),
          ],
        ),
      );
      // 항목마다 타일 상자 → 표시기 상자 순이다. 스위치와 같은 이유로
      // 상자별로 본다 — 합치면 타일에 잘못 붙여도 통과한다.
      final boxes = _shadowsPerBox(
        tester,
        find.byType(ShadcnRadioGroup<String>),
      );
      expect(boxes.first, isEmpty, reason: '타일은 원본에 없는 우리 것이다');
      expect(boxes[1], _distinct.shadowXs.r);
      expect(
        boxes.where((s) => s.isNotEmpty).length,
        2,
        reason: '항목이 둘이므로 그림자 있는 상자도 둘이다',
      );
    });

    testWidgets('스위치는 트랙에만 shadow-xs 를 쓴다', (tester) async {
      // switch.tsx:20 은 트랙(`SwitchPrimitive.Root`)에 `shadow-xs` 를 붙이고,
      // :28 의 엄지(`SwitchPrimitive.Thumb`)에는 아무 그림자도 없다. 예전
      // 우리 코드는 정확히 반대였다 — 엄지에 손으로 고른 검정 10% 를 그리고
      // 트랙은 비워 뒀다 (#25).
      await _pump(tester, ShadcnSwitch(value: true, onChanged: (_) {}));

      // 바깥이 트랙, 안쪽이 엄지다. 합쳐서 보면 둘을 구별하지 못한다.
      expect(_shadowsPerBox(tester, find.byType(ShadcnSwitch)), [
        _distinct.shadowXs.r,
        isEmpty,
      ]);
    });

    testWidgets('날짜 선택 트리거는 shadow-xs 를 쓴다', (tester) async {
      // 트리거는 outline 버튼 자리다 — button.tsx:16 과 같은 `shadow-xs`.
      await _pump(
        tester,
        ShadcnDatePicker.single(value: null, onChanged: (_) {}),
      );
      expect(
        _shadowsIn(tester, find.byType(ShadcnDatePicker)),
        _distinct.shadowXs.r,
      );
    });

    testWidgets('날짜 다이얼로그는 shadow-lg 를 쓴다', (tester) async {
      // dialog.tsx:64 — `shadow-lg`. 팝오버(popover.tsx:33, `shadow-md`)가
      // 아니라 다이얼로그인 것은 우리가 `Dialog` 로 띄우기 때문이다.
      await _pump(
        tester,
        ShadcnDatePicker.single(value: null, onChanged: (_) {}),
      );
      await tester.tap(find.byType(ShadcnDatePicker));
      await tester.pumpAndSettle();

      expect(_shadowsIn(tester, find.byType(Dialog)), _distinct.shadowLg.r);
    });
  });

  group('그림자를 일부러 안 그리는 컴포넌트', () {
    // shadcn 원본이 그렇게 정해둔 것이다. 여기가 초록인데 화면이 허전해
    // 보인다면, 고칠 곳은 이 테스트가 아니라 그 판단이다.

    testWidgets('기본 버튼은 그림자가 없다', (tester) async {
      // button.tsx:11-24 — `shadow-xs` 는 `outline` 에만 있다.
      await _pump(
        tester,
        ShadcnButton(onPressed: () {}, child: const Text('Save')),
      );
      expect(_shadowsIn(tester, find.byType(ShadcnButton)), isEmpty);
    });

    testWidgets('체크박스는 그림자를 못 받는다 — 상류에 슬롯이 없다', (tester) async {
      // checkbox.tsx:17 은 `shadow-xs` 다. 우리는 그리지 못한다:
      // `flutter_checkbox` 의 `CheckboxStyle` 에 그림자 슬롯이 아예 없고,
      // 상자를 그리는 것은 그 패키지의 `CustomPaint` 라 하류에서 덧씌우면
      // 라벨까지 함께 그림자를 얻는다. #27 · #26 과 같은 판단이다 —
      // 상류에 올리고(`kihyun1998/flutter_checkbox#8`), 없는 것을 없다고
      // 적는다.
      //
      // **이 테스트는 상류가 고쳐져도 저절로 빨개지지 않는다.** 패키지가
      // 슬롯을 만들어도 우리가 값을 넘기기 전까지는 여전히 초록이다.
      // 되살아나는 방아쇠는 이 테스트가 아니라 상류 이슈가 닫히는 것이다.
      await _pump(tester, ShadcnCheckbox(value: true, onChanged: (_) {}));
      expect(_shadowsIn(tester, find.byType(ShadcnCheckbox)), isEmpty);
    });
  });

  group('그림자도 화면 배율을 탄다', () {
    // 모서리가 `radius.md.r` 로 배율을 타므로(#23) 그림자도 타야 한다.
    // 위 테스트들은 기대값에도 `.r` 을 걸어서 배율 자체는 증명하지 못한다 —
    // 375 폭에서는 `.r` 이 1.0 이라 곱해도 티가 안 난다. 그래서 여기서만
    // 배율을 실제로 움직여 본다.
    testWidgets('폭이 두 배면 흐림도 두 배다', (tester) async {
      await _pump(
        tester,
        const ShadcnCard(title: 'Card'),
        size: const Size(750, 1624),
      );

      final drawn = _shadowsIn(tester, find.byType(ShadcnCard)).single;
      expect(drawn.blurRadius, 44); // shadow-sm 의 22 × 2
      expect(drawn.offset.dy, 24); // 12 × 2
    });
  });
}
