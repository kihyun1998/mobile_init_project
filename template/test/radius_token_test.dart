import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_calendar.dart';
import 'package:mobile_init_project/ui/components/shadcn_card.dart';
import 'package:mobile_init_project/ui/components/shadcn_checkbox.dart';
import 'package:mobile_init_project/ui/components/shadcn_switch.dart';

/// 붙여넣은 CSS 의 `--radius` 가 컴포넌트 모서리까지 실제로 도달하는지 본다.
///
/// **기본값으로는 이걸 볼 수 없다.** 템플릿 CSS 의 `--radius: 0.625rem` 에서 나오는
/// sm/md/lg/xl = 6/8/10/14 는 예전 하드코딩 값과 여러 개가 우연히 같다. 그래서
/// 일부러 기본과 겹치지 않는 값을 넣는다 — 자기 자신을 오독할 수 있는 측정을
/// 피하는 것과 같은 이유다.
final _wide = TweakcnRadius.fromRadius(20); // sm 16 / md 18 / lg 20 / xl 24

ThemeData _themeWith(TweakcnRadius radius) => ThemeData(
  brightness: Brightness.light,
  extensions: [TweakcnColors.light, radius, TweakcnShadows.light],
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en')],
        theme: _themeWith(_wide),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _cornerOf(WidgetTester tester, Finder inside) {
  final container = tester.widget<Container>(
    find.descendant(of: inside, matching: find.byType(Container)).first,
  );
  final shape = (container.decoration! as BoxDecoration).borderRadius!;
  return (shape as BorderRadius).topLeft.x;
}

void main() {
  group('--radius 를 따라가는 컴포넌트', () {
    testWidgets('카드는 lg 를 쓴다', (tester) async {
      await _pump(tester, const ShadcnCard(title: 'Card'));
      expect(_cornerOf(tester, find.byType(ShadcnCard)), _wide.lg.r);
    });

    testWidgets('달력 날짜 칸은 md 를 쓴다', (tester) async {
      await _pump(
        tester,
        ShadcnCalendar(month: DateTime(2025, 6), today: DateTime(2025, 6, 3)),
      );

      final cell = tester.widget<Container>(
        find
            .ancestor(of: find.text('20'), matching: find.byType(Container))
            .first,
      );
      final corner =
          ((cell.decoration! as BoxDecoration).borderRadius! as BorderRadius)
              .topLeft
              .x;
      expect(corner, _wide.md.r);
    });
  });

  group('--radius 를 일부러 안 따라가는 컴포넌트', () {
    // shadcn 원본이 그렇게 정해둔 것이다. 실제 소스에서 확인:
    // registry/new-york-v4/ui/checkbox.tsx 는 `rounded-[4px]` 로 고정,
    // switch.tsx 는 `rounded-full` 이다. 둘 다 --radius 를 참조하지 않는다.
    // 여기가 초록인데 화면이 이상해 보인다면, 고칠 곳은 이 테스트가 아니라
    // 그 판단이다.

    testWidgets('체크박스는 --radius 가 커져도 그대로다', (tester) async {
      await _pump(tester, ShadcnCheckbox(value: true, onChanged: (_) {}));
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final corner =
          ((box.decoration! as BoxDecoration).borderRadius! as BorderRadius)
              .topLeft
              .x;
      expect(corner, 3.r);
      expect(corner, isNot(_wide.sm.r));
    });

    testWidgets('스위치는 --radius 가 작아져도 캡슐이다', (tester) async {
      await _pump(tester, ShadcnSwitch(value: true, onChanged: (_) {}));
      expect(_cornerOf(tester, find.byType(ShadcnSwitch)), 12.r);
    });
  });
}
