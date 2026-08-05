import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_calendar.dart';
import 'package:mobile_init_project/ui/components/shadcn_date_picker.dart';

/// 2025년 6월. 일요일 시작 그리드에서 6/1~6/30 다음에 7/1~7/12 가 채워지므로
/// **13 이상의 날짜만 그리드에 한 번 등장한다.** 12 이하를 쓰면 `find.text` 가
/// 두 칸을 잡아 테스트가 엉뚱한 칸을 본다.
final _june = DateTime(2025, 6);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        locale: locale,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('ko'),
          Locale('en'),
          Locale('en', 'GB'),
        ],
        theme: TweakcnTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 요일 헤더를 화면에 그려진 순서대로.
List<String> _weekdayHeaders(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(weekdayHeaderKey),
        matching: find.byType(Text),
      ),
    )
    .map((t) => t.data!)
    .toList();

/// 날짜 칸 글자에 실제로 실린 색.
Color? _dayTextColor(WidgetTester tester, String day) =>
    tester.widget<Text>(find.text(day)).style?.color;

/// 날짜 칸에 실제로 칠해진 배경색. 테마를 다시 읽는 것이 아니라 렌더 트리에서 꺼낸다.
Color? _cellColor(WidgetTester tester, String day) {
  final container = tester.widget<Container>(
    find.ancestor(of: find.text(day), matching: find.byType(Container)).first,
  );
  return (container.decoration! as BoxDecoration).color;
}

void main() {
  group('ShadcnCalendar — 로케일', () {
    testWidgets('ko 에서 요일과 월 제목이 한국어로 나온다', (tester) async {
      await _pump(
        tester,
        ShadcnCalendar(month: _june, today: DateTime(2025, 6, 3)),
        locale: const Locale('ko'),
      );

      expect(_weekdayHeaders(tester), ['일', '월', '화', '수', '목', '금', '토']);
      expect(find.text('2025년 6월'), findsOneWidget);
    });

    testWidgets('en 에서는 영어로 나온다', (tester) async {
      await _pump(
        tester,
        ShadcnCalendar(month: _june, today: DateTime(2025, 6, 3)),
      );

      expect(_weekdayHeaders(tester), ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
      expect(find.text('June 2025'), findsOneWidget);
    });

    testWidgets('월요일 시작 로케일에서는 요일 순서가 회전한다', (tester) async {
      // ko 와 en 은 둘 다 일요일 시작(firstDayOfWeekIndex=0)이라 이 경로를 밟지
      // 못한다. 실제로 회전이 일어나는 로케일로 확인한다.
      await _pump(
        tester,
        ShadcnCalendar(month: _june, today: DateTime(2025, 6, 3)),
        locale: const Locale('en', 'GB'),
      );

      expect(_weekdayHeaders(tester), ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    });
  });

  group('ShadcnCalendar — 색이 테마에서 온다', () {
    testWidgets('선택된 날은 primary 로 칠해진다', (tester) async {
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          selected: DateTime(2025, 6, 20),
          today: DateTime(2025, 6, 3),
        ),
      );

      expect(_cellColor(tester, '20'), TweakcnColors.light.primary);
      expect(
        _cellColor(tester, '19'),
        Colors.transparent,
        reason: '고르지 않은 날까지 칠해지면 안 된다',
      );
    });

    testWidgets('기간은 양 끝이 primary, 사이가 accent 다', (tester) async {
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          rangeStart: DateTime(2025, 6, 15),
          rangeEnd: DateTime(2025, 6, 20),
          today: DateTime(2025, 6, 3),
        ),
      );

      expect(_cellColor(tester, '15'), TweakcnColors.light.primary);
      expect(_cellColor(tester, '20'), TweakcnColors.light.primary);
      expect(_cellColor(tester, '17'), TweakcnColors.light.accent);
      expect(_cellColor(tester, '21'), Colors.transparent);
      expect(_cellColor(tester, '14'), Colors.transparent);
    });
  });

  group('ShadcnCalendar — 비활성', () {
    testWidgets('경계 밖의 날은 흐리고 눌러도 콜백이 오지 않는다', (tester) async {
      final tapped = <DateTime>[];

      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 3),
          firstDate: DateTime(2025, 6, 15),
          lastDate: DateTime(2025, 6, 20),
          onDaySelected: tapped.add,
        ),
      );

      final muted = TweakcnColors.light.mutedForeground;

      // 눌러서 아무 일도 안 일어나는 것만 보면, 콜백을 통째로 잊었을 때도 통과한다.
      // 되는 날이 실제로 오는 것까지 같이 본다.
      await tester.tap(find.text('14'));
      await tester.tap(find.text('21'));
      await tester.pumpAndSettle();
      expect(tapped, isEmpty);

      await tester.tap(find.text('17'));
      await tester.pumpAndSettle();
      expect(tapped, [DateTime(2025, 6, 17)]);

      expect(_dayTextColor(tester, '14'), muted.withValues(alpha: 0.4));
      expect(_dayTextColor(tester, '17'), isNot(muted.withValues(alpha: 0.4)));
    });

    testWidgets('비활성 날에는 오늘 테두리도 붙지 않는다', (tester) async {
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 14),
          firstDate: DateTime(2025, 6, 15),
        ),
      );

      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text('14'), matching: find.byType(Container))
            .first,
      );
      expect((container.decoration! as BoxDecoration).border, isNull);
    });
  });

  group('ShadcnCalendar — 큰 글자 배율', () {
    testWidgets('배율 3.0 에서도 넘치지 않는다', (tester) async {
      // 실측으로 잡은 회귀다. 제목을 Flexible 로 감싸기 전에는 여기서
      // "A RenderFlex overflowed by 61 pixels on the right." 가 났다.
      // 형제 컴포넌트(Card·Select·SwitchWithLabel)는 같은 배율에서 멀쩡했으므로
      // 템플릿 전체의 관례 문제가 아니라 이 컴포넌트의 결함이었다.
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
            theme: TweakcnTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(3)),
              child: child!,
            ),
            home: Scaffold(
              body: ShadcnCalendar(month: _june, today: DateTime(2025, 6, 3)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ShadcnDatePicker', () {
    testWidgets('트리거를 누르면 달력이 뜨고, 날짜를 고르면 콜백이 온다', (tester) async {
      DateTime? picked;

      await _pump(
        tester,
        ShadcnDatePicker.single(
          value: null,
          today: DateTime(2025, 6, 3),
          placeholder: '날짜 선택',
          onChanged: (d) => picked = d,
        ),
      );

      expect(find.byType(ShadcnCalendar), findsNothing);
      expect(find.text('날짜 선택'), findsOneWidget);

      await tester.tap(find.text('날짜 선택'));
      await tester.pumpAndSettle();
      expect(find.byType(ShadcnCalendar), findsOneWidget);

      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2025, 6, 20));
      expect(find.byType(ShadcnCalendar), findsNothing, reason: '고르면 닫힌다');
    });

    testWidgets('기간 모드는 두 번 눌러야 확정된다', (tester) async {
      DateTimeRange? picked;

      await _pump(
        tester,
        ShadcnDatePicker.range(
          value: null,
          today: DateTime(2025, 6, 3),
          placeholder: '기간 선택',
          onChanged: (r) => picked = r,
        ),
      );

      await tester.tap(find.text('기간 선택'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(picked, isNull, reason: '한 번만 눌러서는 확정되지 않는다');
      expect(find.byType(ShadcnCalendar), findsOneWidget, reason: '열려 있어야 한다');

      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      expect(picked?.start, DateTime(2025, 6, 15));
      expect(picked?.end, DateTime(2025, 6, 20));
    });

    testWidgets('거꾸로 골라도 시작이 앞선다', (tester) async {
      DateTimeRange? picked;

      await _pump(
        tester,
        ShadcnDatePicker.range(
          value: null,
          today: DateTime(2025, 6, 3),
          placeholder: '기간 선택',
          onChanged: (r) => picked = r,
        ),
      );

      await tester.tap(find.text('기간 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(picked?.start, DateTime(2025, 6, 15));
      expect(picked?.end, DateTime(2025, 6, 20));
    });
  });

  group('날짜 셀이 스크린 리더에 역할과 상태를 싣는다', () {
    // 교체 전 실측(#26): 선택된 20일이 label="20" button=false selected=false
    // enabled=false 로 나갔다. 어느 날을 골랐는지 알 방법이 없었다.
    //
    // Material 의 `CalendarDatePicker` 가 같은 자리에 무엇을 싣는지를 목표로
    // 잡는다 (`material/calendar_date_picker.dart:1288-1302`). 라벨 형태까지
    // 그대로 따라간다 — **날짜 숫자를 전체 날짜 앞에 붙인다.** 상류 주석이
    // 이유를 적어둔다: 보조기술 사용자는 몇 일인지를 먼저 찾는다.
    testWidgets('고른 날이 button·selected 와 전체 날짜를 싣는다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 3),
          selected: DateTime(2025, 6, 20),
          onDaySelected: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.text('20')),
        matchesSemantics(
          label: '20, Friday, June 20, 2025',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('안 고른 날은 selected 가 내려간 채로 나간다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 3),
          selected: DateTime(2025, 6, 20),
          onDaySelected: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.text('21')),
        matchesSemantics(
          label: '21, Saturday, June 21, 2025',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('오늘은 라벨 끝에 currentDateLabel 이 붙는다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 17),
          onDaySelected: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.text('17')).label,
        '17, Tuesday, June 17, 2025, Today',
      );
      handle.dispose();
    });

    testWidgets('숫자가 두 번 읽히지 않는다', (tester) async {
      // 안쪽 `Text('20')` 이 제 노드를 만들면 "20, 20, Friday…" 가 된다.
      // `excludeSemantics: true` 가 그것을 막는다.
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 3),
          onDaySelected: (_) {},
        ),
      );

      final node = tester.getSemantics(find.text('20'));
      expect(node.label, '20, Friday, June 20, 2025');
      expect(node.childrenCount, 0);
      handle.dispose();
    });

    testWidgets('고를 수 없는 날은 enabled 가 내려가고 탭이 사라진다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 3),
          firstDate: DateTime(2025, 6, 18),
          onDaySelected: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.text('15')),
        matchesSemantics(
          label: '15, Sunday, June 15, 2025',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('기간 가운데 날도 selected 로 나간다', (tester) async {
      // 상류에 선례가 없다(Material 달력에는 기간이 없다). 범위 **전체**를
      // selected 로 알린다 — 시작/끝/가운데를 구분하려면 우리 문구가 필요한데,
      // shadcn 컴포넌트는 l10n 을 물지 않는다는 규칙과 어긋난다.
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ShadcnCalendar(
          month: _june,
          today: DateTime(2025, 6, 3),
          rangeStart: DateTime(2025, 6, 15),
          rangeEnd: DateTime(2025, 6, 20),
          onDaySelected: (_) {},
        ),
      );

      const inRange = {
        '15': '15, Sunday, June 15, 2025',
        '17': '17, Tuesday, June 17, 2025',
        '20': '20, Friday, June 20, 2025',
      };
      inRange.forEach((day, label) {
        expect(
          tester.getSemantics(find.text(day)),
          matchesSemantics(
            label: label,
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
          reason: '$day 일이 범위 안인데 selected 가 아니다',
        );
      });
      handle.dispose();
    });
  });
}
