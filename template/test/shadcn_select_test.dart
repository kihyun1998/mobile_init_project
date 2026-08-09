import 'package:flutter/material.dart';
import 'package:flutter_dropdown_button/flutter_dropdown_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_select.dart';
import 'package:mobile_init_project/ui/components/shadcn_shadow.dart';

/// `ShadcnSelect` 는 `flutter_dropdown_button` 위에 앉아 있다.
///
/// **이 파일의 핵심은 "색이 하나도 비어 있지 않은가" 다.** `flutter_checkbox`
/// 와 달리 이 패키지는 안 넘긴 색을 `ThemeData` 의 레거시 필드에서 가져오는데
/// (`DropdownAmbientColors.of`), `TweakcnTheme` 는 `colorScheme` 과 `extensions`
/// 만 채운다. 실측(#31, 2026-08-05):
///
/// | 필드 | light | dark |
/// |---|---|---|
/// | `cardColor` | `cs.surface` (= card = background = popover, **우연히 같다**) | `cs.surface` = background — card 아님 |
/// | `primaryColor` | `cs.primary` | **`cs.surface`** — 액센트가 배경색이 된다 |
/// | splash·highlight·hover·disabled·hint·icon | 전부 Material 기본 검정 계열 | 전부 Material 기본 흰색 계열 |
///
/// 빠뜨린 색은 **컴파일도 되고 테스트도 통과하며 화면만 미묘하게 다르다.**
/// 그래서 값 비교보다 먼저 `비어 있는 색 슬롯이 없다` 를 본다.
///
/// 위젯이 **실제로 패키지에 넘긴** 테마. 같은 계산을 다시 돌려 비교하면 동어반복이라
/// 무엇도 잡지 못한다 — #27 에서 그렇게 썼다가 색을 형광초록으로 바꾸는 변이에도
/// 12개가 전부 초록이어서 드러났다. 렌더 트리에서 꺼낸다.
DropdownStyleTheme _passedTheme(WidgetTester tester) => tester
    .widget<FlutterDropdownButton<ShadcnSelectItem<String>>>(
      find.byType(FlutterDropdownButton<ShadcnSelectItem<String>>),
    )
    .theme!;

/// 트리거/항목에 실제로 그려진 글자의 색. 커스텀 모드라 글자 위젯을 우리가
/// 만들므로, 넘긴 스타일이 아니라 **렌더된 `Text`** 를 본다.
Color? _textColor(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data).last).style?.color;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: theme ?? TweakcnTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<ShadcnSelectItem<String>> _items() => const [
  ShadcnSelectItem(value: 'owner', label: 'Owner'),
  ShadcnSelectItem(value: 'member', label: 'Member'),
  ShadcnSelectItem(value: 'viewer', label: 'Viewer'),
];

void main() {
  group('공개 API 는 그대로다', () {
    testWidgets('placeholder 가 값이 없을 때 보인다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: null,
          onChanged: (_) {},
          items: _items(),
          placeholder: '역할 선택',
        ),
      );

      expect(find.text('역할 선택'), findsOneWidget);
    });

    testWidgets('선택된 값의 label 이 트리거에 보인다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
          placeholder: '역할 선택',
        ),
      );

      expect(find.text('Member'), findsOneWidget);
      expect(find.text('역할 선택'), findsNothing);
    });

    testWidgets('label 이 트리거 위에 그려진다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: null,
          onChanged: (_) {},
          items: _items(),
          label: '역할',
        ),
      );

      expect(find.text('역할'), findsOneWidget);
    });

    testWidgets('항목을 고르면 T 가 콜백으로 온다 — ShadcnSelectItem 이 아니라', (tester) async {
      final picked = <String>[];
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: null,
          onChanged: picked.add,
          items: _items(),
          placeholder: '역할 선택',
        ),
      );

      await tester.tap(find.byType(ShadcnSelect<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Viewer').last);
      await tester.pumpAndSettle();

      expect(picked, ['viewer']);
    });

    testWidgets('onChanged 가 null 이면 열리지 않는다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: null,
          onChanged: null,
          items: _items(),
          placeholder: '역할 선택',
        ),
      );

      await tester.tap(find.byType(ShadcnSelect<String>));
      await tester.pumpAndSettle();

      // 메뉴가 열렸다면 항목 텍스트가 트리에 나타난다.
      expect(find.text('Viewer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('items 에 없는 value 여도 터지지 않는다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'ghost',
          onChanged: (_) {},
          items: _items(),
          placeholder: '역할 선택',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('역할 선택'), findsOneWidget);
    });
  });

  group('색 슬롯이 하나도 비어 있지 않다', () {
    // 이 그룹이 이 티켓의 수용 기준 그 자체다. 값이 맞는지보다 **비어 있지 않은지**
    // 가 먼저인 이유는, 비면 Material 기본 회색이 조용히 들어오기 때문이다.
    testWidgets('도달 가능한 색 슬롯 16개가 전부 채워져 있다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      final t = _passedTheme(tester);
      final filled = <String, Object?>{
        // button 7 — 배경은 이제 `decoration` 안에 있다. `backgroundColor`
        // 슬롯은 `_decoration` 이 `decoration` 앞에서 돌아가 도달하지 않는다
        // (#25). 그리는 값을 보려면 그리는 자리를 봐야 한다.
        'button.decoration.color': t.button.decoration?.color,
        'button.disabledDecoration.color': t.button.disabledDecoration?.color,
        'button.hoverColor': t.button.hoverColor,
        'button.splashColor': t.button.splashColor,
        'button.highlightColor': t.button.highlightColor,
        'button.iconColor': t.button.iconColor,
        'button.iconDisabledColor': t.button.iconDisabledColor,
        // overlay 2 — `backgroundColor` 는 `decoration` 과 별개로 스크롤
        // 페이드에 쓰이므로 여전히 도달한다 (`dropdown_menu_shell.dart:562`).
        'overlay.backgroundColor': t.overlay.backgroundColor,
        'overlay.shadowColor': t.overlay.shadowColor,
        // item 4
        'item.selectedColor': t.item.selectedColor,
        'item.hoverColor': t.item.hoverColor,
        'item.splashColor': t.item.splashColor,
        'item.highlightColor': t.item.highlightColor,
        // scroll 3
        'scroll.thumbColor': t.scroll.thumbColor,
        'scroll.trackColor': t.scroll.trackColor,
        'scroll.trackBorderColor': t.scroll.trackBorderColor,
      };

      expect(filled.length, 16, reason: '도달 가능한 색 슬롯의 수가 바뀌었다');
      expect(
        filled.entries.where((e) => e.value == null).map((e) => e.key),
        isEmpty,
        reason: '비워두면 Material 기본색이 조용히 들어온다',
      );
    });

    testWidgets('색을 나르는 Border 슬롯도 비어 있지 않다', (tester) async {
      // `Color?` 24개 세기로는 안 잡히는 표면이다. 테두리는 `Border?` 안에
      // 색이 들어 있는데, 비우면 `ambient.divider` 로 간다
      // (`dropdown_button_theme.dart:196`, `dropdown_overlay_theme.dart:79`).
      //
      // **이제 세 개 다 `decoration` 안에 있다** (#25). 그림자를 실으려고
      // 상자를 통째로 넘기게 됐고, 그러면 `border` 슬롯은 도달하지 않는다 —
      // 여기서 옛 슬롯을 계속 봤다면 그리지도 않는 값을 지키는 테스트가 된다.
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      final t = _passedTheme(tester);

      expect(t.button.decoration?.border, isNotNull);
      expect(t.button.disabledDecoration?.border, isNotNull);
      expect(t.overlay.decoration?.border, isNotNull);
    });

    testWidgets('도달 못 하는 슬롯 8개는 안 채운다 — 채우면 근거가 낡은 것이다', (tester) async {
      // checkbox 4개: 단일선택은 체크박스를 그리지 않는다. 패키지 안에서
      // `checkboxTheme.resolve()` 를 부르는 곳은 `MultiSelectPresentation.buildItem`
      // (item_presentation.dart:375) 하나뿐이고, 그건 `FlutterMultiSelectDropdown`
      // 만 쓴다.
      // search 2개: `searchable` 을 노출하지 않고 기본값 false 로 둔다. 검색 필드
      // 자체가 `dropdown_menu_shell.dart:593` 의 `if (widget.searchable)` 안에 있다.
      // tooltip 2개: 커스텀 모드(`itemBuilder` 를 넘긴다)라 `CustomItemPresentation`
      // 이 되고, 그것은 `tooltipTheme` 을 아예 받지 않는다
      // (`flutter_dropdown_button.dart:481-488`).
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      final t = _passedTheme(tester);
      final w = tester.widget<FlutterDropdownButton<ShadcnSelectItem<String>>>(
        find.byType(FlutterDropdownButton<ShadcnSelectItem<String>>),
      );

      expect(w.searchable, isFalse, reason: '검색을 켜면 search 색 2개가 도달 가능해진다');
      expect(
        w.itemBuilder,
        isNotNull,
        reason: '텍스트 모드로 돌아가면 tooltip 색 2개가 도달 가능해진다',
      );
      expect(t.checkbox.activeColor, isNull);
      expect(t.checkbox.checkColor, isNull);
      expect(t.search.cursorColor, isNull);
      expect(t.search.backgroundColor, isNull);
      expect(t.tooltip.backgroundColor, isNull);
      expect(t.tooltip.textColor, isNull);
    });
  });

  group('그림자가 CSS 에서 온다', () {
    // #31 은 팝오버 그림자를 **일부러 껐다** — 그리려면 매핑을 정해야 하는데
    // 그 미결을 #25 가 들고 있었기 때문이다. #25 가 정해졌으므로 되돌린다.
    // 단계는 shadcn 원본 실측이다: 트리거 `shadow-xs` (select.tsx:40),
    // 메뉴 `shadow-md` (select.tsx:65).
    //
    // 값은 CSS 에서 오는 것이므로 기본 테마가 아니라 **단계마다 다른 값**을
    // 넣은 테마로 잰다. 템플릿 CSS 는 `shadow-sm` 과 `shadow` 가 같고 light 와
    // dark 도 같아서, 단계를 잘못 골라도 통과시킨다.
    TweakcnShadowLayer layer(double y) => (
      offsetX: 0,
      offsetY: y,
      blurRadius: y * 2,
      spreadRadius: 0,
      color: 0x33000000,
    );

    final distinct = TweakcnShadows.fromShadowMap({
      'shadow-xs': [layer(11)],
      'shadow-md': [layer(13)],
    });

    ThemeData themed() => ThemeData(
      brightness: Brightness.light,
      extensions: [TweakcnColors.light, TweakcnRadius.standard, distinct],
    );

    testWidgets('트리거는 shadow-xs 를 쓴다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
        theme: themed(),
      );

      final t = _passedTheme(tester);
      expect(t.button.decoration?.boxShadow, distinct.shadowXs.r);
      // 비활성 트리거만 조용히 그림자를 잃는 것이 이 패키지에서 가능한
      // 모양이다 — `_decoration` 이 갈래를 따로 들고 있다.
      expect(t.button.disabledDecoration?.boxShadow, distinct.shadowXs.r);
    });

    testWidgets('메뉴는 shadow-md 를 쓰고 Material 그림자는 꺼져 있다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
        theme: themed(),
      );

      final t = _passedTheme(tester);
      expect(t.overlay.decoration?.boxShadow, distinct.shadowMd.r);
      // `elevation` 을 켜면 CSS 레이어 위에 Material 검정이 하나 더 겹친다.
      expect(t.overlay.elevation, 0);
      expect(t.overlay.shadowColor, Colors.transparent);
    });
  });

  group('색이 CSS 에서 온다', () {
    testWidgets('트리거는 투명 배경에 border 테두리, 글자는 foreground 다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      final t = _passedTheme(tester);
      const colors = TweakcnColors.light;

      expect(t.button.decoration?.color, Colors.transparent);
      expect(
        (t.button.decoration?.border as Border?)?.top.color,
        colors.border,
      );
      expect(t.button.iconColor, colors.mutedForeground);
      expect(_textColor(tester, 'Member'), colors.foreground);
      // 두 토큰이 실제로 다른 값이어야 위 assert 가 의미를 갖는다.
      expect(colors.foreground, isNot(colors.mutedForeground));
    });

    testWidgets('placeholder 글자는 mutedForeground 다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: null,
          onChanged: (_) {},
          items: _items(),
          placeholder: '역할 선택',
        ),
      );

      expect(_textColor(tester, '역할 선택'), TweakcnColors.light.mutedForeground);
    });

    testWidgets('메뉴는 popover 바탕에 border 테두리다', (tester) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      final t = _passedTheme(tester);
      const colors = TweakcnColors.light;

      expect(t.overlay.backgroundColor, colors.popover);
      expect(t.overlay.decoration?.color, colors.popover);
      expect(
        (t.overlay.decoration?.border as Border?)?.top.color,
        colors.border,
      );
    });

    testWidgets('메뉴 항목 글자는 popoverForeground, 선택된 것은 accentForeground 다', (
      tester,
    ) async {
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      await tester.tap(find.byType(ShadcnSelect<String>));
      await tester.pumpAndSettle();

      const colors = TweakcnColors.light;
      expect(_textColor(tester, 'Viewer'), colors.popoverForeground);
      expect(_textColor(tester, 'Member'), colors.accentForeground);
    });

    testWidgets('선택·호버는 accent 다 — 형제 컴포넌트와 같은 토큰', (tester) async {
      // shadcn 원본 select.tsx 의 항목이 `focus:bg-accent`. 달력의 선택된 날짜
      // (`shadcn_calendar.dart:300`)와 ghost 버튼의 호버(`shadcn_button.dart:182`)
      // 도 같은 토큰을 쓴다.
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      final t = _passedTheme(tester);
      const colors = TweakcnColors.light;

      expect(t.item.selectedColor, colors.accent);
      expect(t.item.hoverColor, colors.accent);
      expect(t.button.hoverColor, colors.accent);
    });

    testWidgets('dark 에서도 CSS 색이다 — ThemeData 레거시로 새지 않는다', (tester) async {
      // 이 테스트가 이 티켓의 이유다. 안 넘겼다면 dark 에서 `ambient.primary` 가
      // `cs.surface`(#0a0a0a) 라 선택된 항목의 틴트가 배경과 같아져 사라진다.
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
        theme: TweakcnTheme.dark,
      );

      final t = _passedTheme(tester);
      const colors = TweakcnColors.dark;

      expect(t.item.selectedColor, colors.accent);
      expect(t.overlay.backgroundColor, colors.popover);
      // dark 에서 popover 와 background 가 실제로 갈린다는 것을 함께 못박는다 —
      // 갈리지 않으면 위 assert 가 자기 자신을 오독할 수 있다.
      expect(colors.popover, isNot(colors.background));
    });
  });

  group('모서리가 --radius 를 따라간다', () {
    testWidgets('트리거와 메뉴는 md, 항목은 sm 이다', (tester) async {
      // shadcn 원본 select.tsx 실측(#23): 트리거·팝오버 `rounded-md`,
      // 항목 `rounded-sm`.
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      final t = _passedTheme(tester);
      const radius = TweakcnRadius.standard;

      expect(t.button.borderRadius, radius.md.r);
      expect(t.overlay.borderRadius, radius.md.r);
      expect(t.item.borderRadius, radius.sm.r);
      // md 와 sm 이 실제로 다른 값이어야 위 assert 가 서로를 구분한다.
      expect(radius.md, isNot(radius.sm));
    });
  });

  group('스크린 리더 — 나가는 것과 아직 안 나가는 것', () {
    // #26 의 대상이었다. 손으로 만든 `GestureDetector` 구현은 트리거가 역할도
    // 현재 값도 싣지 않았다. 교체 후 시맨틱 트리를 직접 열어 실측한 결과
    // (#31, 2026-08-05):
    //
    //   닫힘: label="Member"  flags=[isFocusable]  actions=[tap, focus]
    //   열림: 행마다 label="Owner"/"Member"  flags=[isFocusable]
    //                                        actions=[tap, focus]
    //
    // **절반만 해소됐다.** 값과 포커스 가능성은 생겼지만 역할(`isButton`)도
    // 선택 상태(`isSelected`)도 없다. 아래 두 테스트는 그 절반씩을 각각
    // 못박는다 — 좋아진 것을 회귀로부터 지키고, 아직 없는 것을 없다고
    // 정직하게 적는다. 없는 쪽을 우리가 `Semantics` 로 덧씌우지 않은 이유는
    // #27 과 같다: 패키지가 합쳐둔 노드를 하류에서 도로 가르게 된다.
    testWidgets('트리거가 현재 값을 싣고 포커스·탭을 받는다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      expect(
        tester.getSemantics(find.text('Member')),
        matchesSemantics(
          label: 'Member',
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('열린 메뉴의 선택된 행이 아직 selected 로 나가지 않는다', (tester) async {
      // 실패해야 할 것이 실패하는 상태를 적어둔다. 상류가 고쳐지면 이 테스트가
      // 빨개지고, 그때 #26 에서 select 항목을 뺀다.
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnSelect<String>(
          value: 'member',
          onChanged: (_) {},
          items: _items(),
        ),
      );

      await tester.tap(find.byType(ShadcnSelect<String>));
      await tester.pumpAndSettle();

      // `matchesSemantics` 는 적지 않은 플래그를 전부 false 로 본다. 그래서 이
      // 한 줄이 `isSelected` 도 `isButton` 도 안 나간다는 것을 함께 못박는다 —
      // 상류가 무엇을 더 싣기 시작하면 여기가 빨개진다.
      expect(
        tester.getSemantics(find.text('Viewer').last),
        matchesSemantics(
          label: 'Viewer',
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });
  });
}
