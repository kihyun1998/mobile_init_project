import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_switch.dart';

/// `ShadcnSwitch` 는 `ToggleableStateMixin` 위에 앉아 있다.
///
/// 교체 전 실측(#26, 2026-08-05):
///
/// ```
/// ShadcnSwitch           #4 label=""  flags=()  actions=(tap)
/// ShadcnSwitchWithLabel  #4 label="알림 / 푸시…"  flags=()  actions=(tap)
///                          #5 label=""           flags=()  actions=(tap)
/// ```
///
/// 플래그가 빈 배열이었고, 라벨 붙은 쪽은 `GestureDetector` 가 이중으로 겹쳐서
/// **라벨 없는 탭 가능한 노드가 하나 더** 나갔다 — 스크린 리더가 정체불명의
/// 버튼을 하나 더 읽는다.
///
/// **스위치는 `checked` 가 아니라 `toggled` 다.** Material 과 Cupertino 둘 다
/// `Semantics(toggled: value)` 를 쓴다 (`material/switch.dart:1074`,
/// `cupertino/switch.dart:753`). 라디오(#26 의 형제 작업)에서 유추했으면 틀렸을
/// 자리다. 그리고 라디오와 달리 **플랫폼 분기가 없다** — Cupertino 의
/// `defaultTargetPlatform` 분기는 햅틱용이고 시맨틱과 무관하다.
Future<void> pump(WidgetTester tester, Widget child) async {
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
  group('ShadcnSwitch — 공개 API 는 그대로다', () {
    testWidgets('누르면 반대 값이 온다', (tester) async {
      final calls = <bool>[];
      await pump(tester, ShadcnSwitch(value: false, onChanged: calls.add));

      await tester.tap(find.byType(ShadcnSwitch));
      await tester.pumpAndSettle();

      expect(calls, [true]);
    });

    testWidgets('켜져 있으면 끄는 값이 온다', (tester) async {
      final calls = <bool>[];
      await pump(tester, ShadcnSwitch(value: true, onChanged: calls.add));

      await tester.tap(find.byType(ShadcnSwitch));
      await tester.pumpAndSettle();

      expect(calls, [false]);
    });

    testWidgets('disabled 면 눌러도 콜백이 오지 않는다', (tester) async {
      final calls = <bool>[];
      await pump(
        tester,
        ShadcnSwitch(value: false, onChanged: calls.add, disabled: true),
      );

      await tester.tap(find.byType(ShadcnSwitch));
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });

    testWidgets('onChanged 가 null 이어도 터지지 않는다', (tester) async {
      await pump(tester, const ShadcnSwitch(value: true, onChanged: null));

      await tester.tap(find.byType(ShadcnSwitch));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ShadcnSwitch — 스크린 리더', () {
    testWidgets('켜진 스위치가 toggled 를 싣는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ShadcnSwitch(value: true, onChanged: (_) {}));

      expect(
        tester.getSemantics(find.byType(ShadcnSwitch)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('꺼진 스위치는 toggled 가 내려간 채로 나간다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ShadcnSwitch(value: false, onChanged: (_) {}));

      expect(
        tester.getSemantics(find.byType(ShadcnSwitch)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('disabled 면 enabled 가 내려가고 탭·포커스가 사라진다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        ShadcnSwitch(value: true, onChanged: (_) {}, disabled: true),
      );

      expect(
        tester.getSemantics(find.byType(ShadcnSwitch)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('ShadcnSwitchWithLabel', () {
    Widget tile({
      bool value = true,
      ValueChanged<bool>? onChanged,
      bool disabled = false,
    }) => ShadcnSwitchWithLabel(
      value: value,
      onChanged: onChanged ?? (_) {},
      label: '알림',
      description: '푸시 알림을 받습니다',
      disabled: disabled,
    );

    testWidgets('라벨을 눌러도 토글된다', (tester) async {
      final calls = <bool>[];
      await pump(tester, tile(value: false, onChanged: calls.add));

      await tester.tap(find.text('알림'));
      await tester.pumpAndSettle();

      expect(calls, [true]);
    });

    testWidgets('스위치 자리를 눌러도 한 번만 토글된다', (tester) async {
      // 교체 전에는 안쪽 `ShadcnSwitch` 와 바깥 타일이 `GestureDetector` 를
      // 각각 들고 겹쳐 있었다. 안쪽을 [ShadcnSwitchVisual] 로 바꿔 제스처를
      // 없앴으니 두 번 불릴 자리가 없어야 한다.
      final calls = <bool>[];
      await pump(tester, tile(value: false, onChanged: calls.add));

      await tester.tap(find.byType(ShadcnSwitchVisual));
      await tester.pumpAndSettle();

      expect(calls, [true]);
    });

    testWidgets('안쪽에 또 하나의 컨트롤이 들어 있지 않다', (tester) async {
      // 위 테스트가 "두 번 안 불린다" 를 보는 것과 짝이다. 이쪽은 애초에
      // 겹칠 것이 트리에 없다는 것을 본다 — 나중에 누가 편의로 안쪽을
      // `ShadcnSwitch` 로 되돌리면 여기가 먼저 빨개진다.
      await pump(tester, tile());

      expect(find.byType(ShadcnSwitch), findsNothing);
      expect(find.byType(ShadcnSwitchVisual), findsOneWidget);
    });

    testWidgets('라벨·상태가 한 노드로 나가고, 빈 노드가 딸려오지 않는다', (tester) async {
      // 교체 전 실측: 타일 노드(#4) 밑에 `label=""` `actions=(tap)` 인 노드(#5)가
      // 하나 더 있었다. 스크린 리더가 정체불명의 버튼을 하나 더 읽는다.
      final handle = tester.ensureSemantics();
      await pump(tester, tile());

      final node = tester.getSemantics(find.byType(ShadcnSwitchWithLabel));
      expect(
        node,
        matchesSemantics(
          label: '알림\n푸시 알림을 받습니다',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // **`matchesSemantics` 만으로는 부족하다.** 그것은 이 노드 하나만 보므로
      // 밑에 자식 노드가 하나 더 붙어도 통과한다 — 실제로 그렇게 썼다가
      // "안쪽을 ShadcnSwitch 로 되돌리는" 변이에 안 걸려서 드러났다.
      expect(node.childrenCount, 0, reason: '타일 밑에 또 다른 컨트롤 노드가 있다');
      handle.dispose();
    });

    testWidgets('disabled 면 enabled 가 내려간다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, tile(disabled: true));

      expect(
        tester.getSemantics(find.byType(ShadcnSwitchWithLabel)),
        matchesSemantics(
          label: '알림\n푸시 알림을 받습니다',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('색과 모양이 그대로다', () {
    BoxDecoration trackOf(WidgetTester tester, Finder inside) =>
        tester
                .widget<Container>(
                  find
                      .descendant(of: inside, matching: find.byType(Container))
                      .first,
                )
                .decoration!
            as BoxDecoration;

    testWidgets('켜지면 트랙이 primary, 꺼지면 border 다', (tester) async {
      const colors = TweakcnColors.light;

      await pump(tester, ShadcnSwitch(value: true, onChanged: (_) {}));
      expect(trackOf(tester, find.byType(ShadcnSwitch)).color, colors.primary);

      await pump(tester, ShadcnSwitch(value: false, onChanged: (_) {}));
      expect(trackOf(tester, find.byType(ShadcnSwitch)).color, colors.border);

      expect(colors.primary, isNot(colors.border));
    });

    testWidgets('disabled 면 트랙이 mutedForeground 다', (tester) async {
      await pump(
        tester,
        ShadcnSwitch(value: true, onChanged: (_) {}, disabled: true),
      );

      expect(
        trackOf(tester, find.byType(ShadcnSwitch)).color,
        TweakcnColors.light.mutedForeground,
      );
    });
  });
}
