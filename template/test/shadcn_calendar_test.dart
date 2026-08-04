import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/ui/components/shadcn_calendar.dart';

/// 날짜 그리드의 순수 로직만 본다. 렌더는 위젯 테스트가 따로 잡는다.
///
/// 여기 박힌 요일·일수는 전부 실제로 확인한 값이다 (`date -d <날짜> +%A`).
/// 기억으로 적으면 틀린 값을 고정하는 테스트가 된다.
void main() {
  group('shadcnCalendarGrid — 시작 요일', () {
    test('2025-06-01 이 일요일이라, 일요일 시작 로케일에서는 첫 칸이 6/1 이다', () {
      final grid = shadcnCalendarGrid(
        month: DateTime(2025, 6),
        firstDayOfWeekIndex: 0,
      );

      expect(grid.first.date, DateTime(2025, 6, 1));
      expect(grid.first.inMonth, isTrue, reason: '선행 칸이 없어야 한다');
    });

    test('같은 달이라도 월요일 시작 로케일에서는 첫 칸이 5/26 로 밀린다', () {
      final grid = shadcnCalendarGrid(
        month: DateTime(2025, 6),
        firstDayOfWeekIndex: 1,
      );

      expect(grid.first.date, DateTime(2025, 5, 26));
      expect(grid.first.inMonth, isFalse, reason: '이전 달 칸이다');
    });

    test('2026-08-01 은 토요일 — 일요일 시작이면 6칸, 월요일 시작이면 5칸 선행한다', () {
      final sundayFirst = shadcnCalendarGrid(
        month: DateTime(2026, 8),
        firstDayOfWeekIndex: 0,
      );
      final mondayFirst = shadcnCalendarGrid(
        month: DateTime(2026, 8),
        firstDayOfWeekIndex: 1,
      );

      expect(sundayFirst.first.date, DateTime(2026, 7, 26));
      expect(mondayFirst.first.date, DateTime(2026, 7, 27));

      // 방향이 반대로 뒤집혀도 첫 칸만 보면 통과할 수 있으니 개수도 못박는다.
      expect(sundayFirst.where((d) => !d.inMonth).length, greaterThan(0));
      expect(
        sundayFirst.takeWhile((d) => !d.inMonth).length,
        6,
        reason: '토요일은 일요일 기준 6번째',
      );
      expect(
        mondayFirst.takeWhile((d) => !d.inMonth).length,
        5,
        reason: '토요일은 월요일 기준 5번째',
      );
    });
  });

  group('shadcnCalendarGrid — 칸 수와 연속성', () {
    test('항상 6주 × 7일 = 42칸이다', () {
      // 5주로 끝나는 달과 6주가 필요한 달을 둘 다 본다.
      for (final month in [
        DateTime(2025, 6),
        DateTime(2026, 8),
        DateTime(2024, 2),
        DateTime(2025, 2),
      ]) {
        expect(
          shadcnCalendarGrid(month: month, firstDayOfWeekIndex: 0).length,
          42,
          reason: '$month 이 42칸이 아니다',
        );
      }
    });

    test('칸이 하루씩 빠짐없이 이어진다', () {
      final grid = shadcnCalendarGrid(
        month: DateTime(2025, 6),
        firstDayOfWeekIndex: 1,
      );

      for (var i = 1; i < grid.length; i++) {
        final prev = grid[i - 1].date;
        // Duration 으로 재지 않는다. 서머타임이 있는 타임존에서 자정 사이 간격이
        // 23/25시간이 되어 inDays 가 0 이나 1 로 갈리고, 테스트가 머신을 탄다.
        expect(
          grid[i].date,
          DateTime(prev.year, prev.month, prev.day + 1),
          reason: '$i 번째 칸에서 하루가 아니다',
        );
      }
    });
  });

  group('shadcnCalendarGrid — 윤년', () {
    test('2024-02 는 29일까지 있고 2/29 가 이번 달 칸이다', () {
      final grid = shadcnCalendarGrid(
        month: DateTime(2024, 2),
        firstDayOfWeekIndex: 0,
      );
      final inMonth = grid.where((d) => d.inMonth).toList();

      expect(inMonth.length, 29);
      expect(inMonth.last.date, DateTime(2024, 2, 29));
    });

    test('2100-02 는 세기 비윤년이라 28일이다', () {
      final inMonth = shadcnCalendarGrid(
        month: DateTime(2100, 2),
        firstDayOfWeekIndex: 0,
      ).where((d) => d.inMonth).toList();

      expect(inMonth.length, 28);
      expect(inMonth.last.date, DateTime(2100, 2, 28));
    });

    test('2000-02 는 400년 규칙으로 윤년이라 29일이다', () {
      final inMonth = shadcnCalendarGrid(
        month: DateTime(2000, 2),
        firstDayOfWeekIndex: 0,
      ).where((d) => d.inMonth).toList();

      expect(inMonth.length, 29);
    });
  });

  group('shadcnWeekdayOrder', () {
    test('일요일 시작이면 narrowWeekdays 를 그대로 쓴다', () {
      expect(shadcnWeekdayOrder(0), [0, 1, 2, 3, 4, 5, 6]);
    });

    test('월요일 시작이면 일요일이 맨 뒤로 간다', () {
      expect(shadcnWeekdayOrder(1), [1, 2, 3, 4, 5, 6, 0]);
    });

    test('토요일 시작도 한 바퀴 돈다', () {
      expect(shadcnWeekdayOrder(6), [6, 0, 1, 2, 3, 4, 5]);
    });
  });

  group('shadcnDayEnabled', () {
    final first = DateTime(2025, 6, 10);
    final last = DateTime(2025, 6, 20);

    test('경계를 안 주면 어떤 날도 고를 수 있다', () {
      expect(
        shadcnDayEnabled(
          day: DateTime(1999, 1, 1),
          firstDate: null,
          lastDate: null,
        ),
        isTrue,
      );
    });

    test('경계 자체는 포함이다', () {
      expect(
        shadcnDayEnabled(day: first, firstDate: first, lastDate: last),
        isTrue,
      );
      expect(
        shadcnDayEnabled(day: last, firstDate: first, lastDate: last),
        isTrue,
      );
    });

    test('경계 밖은 막힌다', () {
      expect(
        shadcnDayEnabled(
          day: DateTime(2025, 6, 9),
          firstDate: first,
          lastDate: last,
        ),
        isFalse,
      );
      expect(
        shadcnDayEnabled(
          day: DateTime(2025, 6, 21),
          firstDate: first,
          lastDate: last,
        ),
        isFalse,
      );
    });

    test('한쪽만 줘도 그쪽만 막는다', () {
      expect(
        shadcnDayEnabled(
          day: DateTime(2025, 6, 9),
          firstDate: first,
          lastDate: null,
        ),
        isFalse,
      );
      expect(
        shadcnDayEnabled(
          day: DateTime(2030, 1, 1),
          firstDate: first,
          lastDate: null,
        ),
        isTrue,
      );
    });

    test('시각이 섞여 있어도 경계일은 살아 있다', () {
      // 경계를 DateTime.now() 로 주는 호출자가 있다. 시각을 안 버리면 그날
      // 하루가 통째로 막힌다.
      expect(
        shadcnDayEnabled(
          day: DateTime(2025, 6, 10),
          firstDate: DateTime(2025, 6, 10, 15, 30),
          lastDate: null,
        ),
        isTrue,
      );
    });
  });

  group('shadcnRangeSpot', () {
    final start = DateTime(2025, 6, 10);
    final end = DateTime(2025, 6, 14);

    test('기간이 없으면 어떤 날도 none 이다', () {
      expect(
        shadcnRangeSpot(day: DateTime(2025, 6, 12), start: null, end: null),
        ShadcnRangeSpot.none,
      );
    });

    test('시작만 있으면 그 날만 only 다', () {
      expect(
        shadcnRangeSpot(day: start, start: start, end: null),
        ShadcnRangeSpot.only,
      );
      expect(
        shadcnRangeSpot(day: DateTime(2025, 6, 12), start: start, end: null),
        ShadcnRangeSpot.none,
        reason: '끝이 정해지기 전에는 사이가 칠해지면 안 된다',
      );
    });

    test('시작·중간·끝을 구분한다', () {
      expect(
        shadcnRangeSpot(day: start, start: start, end: end),
        ShadcnRangeSpot.start,
      );
      expect(
        shadcnRangeSpot(day: DateTime(2025, 6, 12), start: start, end: end),
        ShadcnRangeSpot.middle,
      );
      expect(
        shadcnRangeSpot(day: end, start: start, end: end),
        ShadcnRangeSpot.end,
      );
    });

    test('기간 밖은 양쪽 다 none 이다', () {
      expect(
        shadcnRangeSpot(day: DateTime(2025, 6, 9), start: start, end: end),
        ShadcnRangeSpot.none,
      );
      expect(
        shadcnRangeSpot(day: DateTime(2025, 6, 15), start: start, end: end),
        ShadcnRangeSpot.none,
      );
    });

    test('시작과 끝이 같은 날이면 only 다', () {
      expect(
        shadcnRangeSpot(day: start, start: start, end: start),
        ShadcnRangeSpot.only,
      );
    });

    test('시각이 섞여 있어도 날짜만 본다', () {
      // DateTime.now() 를 그대로 넘기는 호출자가 있으므로 시각 오염은 실제로 온다.
      expect(
        shadcnRangeSpot(
          day: DateTime(2025, 6, 10, 23, 59),
          start: DateTime(2025, 6, 10, 0, 1),
          end: DateTime(2025, 6, 14, 8),
        ),
        ShadcnRangeSpot.start,
      );
    });
  });
}
