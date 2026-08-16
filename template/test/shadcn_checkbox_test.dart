import 'package:flutter/material.dart';
import 'package:flutter_checkbox/flutter_checkbox.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_checkbox.dart';

/// `ShadcnCheckbox` 는 `flutter_checkbox` 패키지 위에 앉아 있다.
///
/// 여기서 보는 것은 두 가지다. **공개 API 가 그대로인가**(호출자가 안 바뀐다)와
/// **패키지에게 넘긴 값이 실제로 화면과 시맨틱 트리에 도달하는가**. 후자를 안
/// 보면 색을 안 넘겨도, 라벨을 안 넘겨도 초록으로 통과한다.
/// 위젯이 **실제로 패키지에 넘긴** 스타일.
///
/// 같은 계산을 다시 돌려 비교하면 동어반복이라 무엇도 잡지 못한다 — 처음에
/// 그렇게 썼다가 색을 초록으로 바꾸는 변이에도 초록이어서 드러났다. 렌더 트리에서
/// 꺼낸다.
CheckboxStyle _passedStyle(WidgetTester tester) => tester
    .widget<FlutterCheckboxTile>(find.byType(FlutterCheckboxTile))
    .checkboxStyle;

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: TweakcnTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('공개 API 는 그대로다', () {
    testWidgets('체크하면 반대 값이 콜백으로 온다', (tester) async {
      final calls = <bool>[];
      await _pump(
        tester,
        ShadcnCheckbox(value: false, onChanged: calls.add, label: '동의'),
      );

      await tester.tap(find.byType(ShadcnCheckbox));
      await tester.pumpAndSettle();

      expect(calls, [true]);
    });

    testWidgets('이미 켜져 있으면 끄는 값이 온다', (tester) async {
      final calls = <bool>[];
      await _pump(
        tester,
        ShadcnCheckbox(value: true, onChanged: calls.add, label: '동의'),
      );

      await tester.tap(find.byType(ShadcnCheckbox));
      await tester.pumpAndSettle();

      expect(calls, [false]);
    });

    testWidgets('disabled 면 눌러도 콜백이 오지 않는다', (tester) async {
      final calls = <bool>[];
      await _pump(
        tester,
        ShadcnCheckbox(
          value: false,
          onChanged: calls.add,
          label: '동의',
          disabled: true,
        ),
      );

      await tester.tap(find.byType(ShadcnCheckbox));
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });

    testWidgets('onChanged 가 null 이어도 터지지 않는다', (tester) async {
      await _pump(
        tester,
        const ShadcnCheckbox(value: true, onChanged: null, label: '읽기 전용'),
      );

      await tester.tap(find.byType(ShadcnCheckbox));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('라벨이 없어도 그려진다', (tester) async {
      await _pump(tester, ShadcnCheckbox(value: true, onChanged: (_) {}));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShadcnCheckbox), findsOneWidget);
    });
  });

  group('색이 테마에서 온다', () {
    testWidgets('켜진 상자는 primary, 체크는 primaryForeground 다', (tester) async {
      await _pump(tester, ShadcnCheckbox(value: true, onChanged: (_) {}));

      final style = _passedStyle(tester);

      expect(style.activeColor, TweakcnColors.light.primary);
      expect(style.checkColor, TweakcnColors.light.primaryForeground);
    });

    testWidgets('disabled 면 테두리가 mutedForeground 로 내려간다', (tester) async {
      await _pump(
        tester,
        ShadcnCheckbox(value: false, onChanged: (_) {}, disabled: true),
      );

      final style = _passedStyle(tester);

      expect(style.borderColor, TweakcnColors.light.mutedForeground);
      // 두 토큰이 실제로 다른 값이어야 이 assert 가 의미를 갖는다.
      expect(
        TweakcnColors.light.mutedForeground,
        isNot(TweakcnColors.light.primary),
      );
    });

    testWidgets('모서리는 --radius 를 따라가지 않는다', (tester) async {
      // shadcn 원본이 `rounded-[4px]` 로 고정이다 (#23 에서 실측하고 정한 것).
      // radius_token_test.dart 가 렌더 결과로 이미 못박고 있고, 여기서는 패키지에
      // 넘기는 값 자체가 토큰이 아님을 본다.
      await _pump(tester, ShadcnCheckbox(value: true, onChanged: (_) {}));

      final style = _passedStyle(tester);

      expect(style.borderRadius, 3.r);
    });
  });

  group('스크린 리더에 상태가 나간다', () {
    // 교체 전에는 체크된 체크박스가 `selected=false` 로 나갔다 (#26 의 실측).
    // 패키지의 CheckboxInteraction 이 `checked` 를 싣는지를 여기서 확인한다.
    testWidgets('체크 상태와 라벨이 한 노드에 실린다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCheckbox(value: true, onChanged: (_) {}, label: '동의'),
      );

      expect(
        tester.getSemantics(find.byType(ShadcnCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          isEnabled: true,
          hasEnabledState: true,
          label: '동의',
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('라벨이 있든 없든 focusable 이 나간다', (tester) async {
      // **이 테스트는 한때 상류 결함을 기대값으로 못박고 있었다.**
      //
      // 0.3.1 까지는 라벨이 있을 때만 `isFocusable` 과 `focus` 액션이 빠졌다.
      // 패키지가 라벨이 있으면 `excludeChildSemantics` 로 노드를 하나로
      // 합치는데(스크린 리더가 컨트롤 하나로 보게 하려는 것), 그 과정에서
      // 안쪽 `FocusableActionDetector` 의 기여까지 같이 빠졌기 때문이다.
      // 키보드 활성화 자체는 실제 Focus 위젯에 걸려 있어 멀쩡했으므로
      // 아무도 눈치채지 못했다 — 잃은 것은 보조기술이 이 노드를 포커스
      // 가능한 것으로 인식하는 부분뿐이었다.
      //
      // `flutter_checkbox` 0.3.2 가 고쳤다(`kihyun1998/flutter_checkbox#7`).
      // 그래서 이제 두 경우가 같고, 이 테스트는 그 수정을 잠그는 자리다 —
      // 상류가 되돌아가면 여기가 빨개진다.
      final handle = tester.ensureSemantics();

      await _pump(tester, ShadcnCheckbox(value: true, onChanged: (_) {}));
      expect(
        tester.getSemantics(find.byType(ShadcnCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
        reason: '라벨 없음',
      );

      await _pump(
        tester,
        ShadcnCheckbox(value: true, onChanged: (_) {}, label: '동의'),
      );
      expect(
        tester.getSemantics(find.byType(ShadcnCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          label: '동의',
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
        reason: '라벨 있음 — 0.3.1 에서는 여기서 focusable 이 빠졌다',
      );

      handle.dispose();
    });

    testWidgets('안 켜진 상태도 구분되어 나간다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCheckbox(value: false, onChanged: (_) {}, label: '동의'),
      );

      expect(
        tester.getSemantics(find.byType(ShadcnCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: false,
          isEnabled: true,
          hasEnabledState: true,
          label: '동의',
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('disabled 면 enabled 가 내려가고 탭 동작이 사라진다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCheckbox(
          value: true,
          onChanged: (_) {},
          label: '동의',
          disabled: true,
        ),
      );

      expect(
        tester.getSemantics(find.byType(ShadcnCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: false,
          label: '동의',
        ),
      );
      handle.dispose();
    });
  });
}
