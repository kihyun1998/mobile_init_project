import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/src/preview/preview_canvas.dart';
import 'package:mobile_init_builder/src/preview/preview_theme.dart';
import 'package:mobile_init_project/ui/components/shadcn_select.dart';

/// `ShadcnSelect` 가 `flutter_dropdown_button` 으로 옮겨간 뒤에도 **붙여넣은 CSS
/// 가 실제 픽셀까지 닿는지**를 본다 (#31).
///
/// 넘긴 값을 확인하는 것은 `template/test/shadcn_select_test.dart` 가 한다.
/// 여기서 보는 것은 그 다음 칸이다 — 패키지가 그 값으로 **정말 그리는가**.
/// 이 패키지는 안 넘긴 색을 `ThemeData` 레거시 필드에서 가져오므로, 매핑이
/// 하나라도 새면 여기서 Material 기본 회색이 나온다.
///
/// **토큰 쌍을 일부러 전부 다른 값으로 준다.** 템플릿 기본 CSS 는
/// `background`/`card`/`popover` 가 같은 값이라, 그걸로 재면 매핑을 틀려도
/// 통과한다 — 자기 자신을 오독할 수 있는 측정이다.
const _css = '''
:root {
  --background: #FFFFFF;
  --card: #00FF00;
  --popover: #FF00FF;
  --popover-foreground: #123456;
  --foreground: #111111;
  --muted-foreground: #888888;
  --border: #FF0000;
  --accent: #00FFFF;
  --accent-foreground: #654321;
  --primary: #0000FF;
  --radius: 0.5rem;
}
''';

/// 트리거 상자에 실제로 그려진 `BoxDecoration`.
///
/// 패키지가 `dropdown_menu_shell.dart:360-363` 에서 `Container` 하나로 그린다.
BoxDecoration _renderedTriggerBox(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(ShadcnSelect<String>),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

Color _renderedTextColor(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data).last).style!.color!;

Future<void> _pump(WidgetTester tester, {String? value}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PreviewCanvas(
          theme: PreviewTheme.fromCss(_css).light,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                child: ShadcnSelect<String>(
                  value: value,
                  onChanged: (_) {},
                  placeholder: '고르세요',
                  items: const [
                    ShadcnSelectItem(value: 'owner', label: 'Owner'),
                    ShadcnSelectItem(value: 'member', label: 'Member'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('트리거 테두리가 붙여넣은 --border 로 그려진다', (tester) async {
    await _pump(tester);

    final box = _renderedTriggerBox(tester);
    expect((box.border! as Border).top.color, const Color(0xFFFF0000));
    expect(box.color, Colors.transparent);
  });

  testWidgets('트리거 글자가 --foreground, placeholder 가 --muted-foreground 다', (
    tester,
  ) async {
    await _pump(tester);
    expect(_renderedTextColor(tester, '고르세요'), const Color(0xFF888888));

    await _pump(tester, value: 'member');
    expect(_renderedTextColor(tester, 'Member'), const Color(0xFF111111));
  });

  testWidgets('열린 메뉴가 --popover 로 그려진다 — --card 도 --background 도 아니다', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byType(ShadcnSelect<String>));
    await tester.pumpAndSettle();

    // 메뉴는 루트 Overlay 에 그려지므로 ShadcnSelect 의 자손이 아니다.
    // 붙여넣은 세 값이 전부 다르니 색으로 찾는 것이 곧 매핑 확인이다.
    final decorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .toList();

    expect(
      decorations.map((d) => d.color),
      contains(const Color(0xFFFF00FF)),
      reason: '--card(#00FF00) 나 --background(#FFFFFF) 가 나오면 매핑이 샌 것이다',
    );
    expect(
      decorations.map((d) => d.color),
      isNot(contains(const Color(0xFF00FF00))),
    );
  });

  testWidgets('메뉴 항목 글자가 --popover-foreground, 선택된 것이 --accent-foreground 다', (
    tester,
  ) async {
    await _pump(tester, value: 'member');
    await tester.tap(find.byType(ShadcnSelect<String>));
    await tester.pumpAndSettle();

    expect(_renderedTextColor(tester, 'Owner'), const Color(0xFF123456));
    expect(_renderedTextColor(tester, 'Member'), const Color(0xFF654321));
  });
}
