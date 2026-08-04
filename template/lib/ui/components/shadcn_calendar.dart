import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

/// 달력 그리드의 칸 하나.
class ShadcnCalendarDay {
  const ShadcnCalendarDay({required this.date, required this.inMonth});

  /// 자정으로 맞춰진 날짜.
  final DateTime date;

  /// 표시 중인 달에 속하는가. 앞뒤로 채워진 이웃 달 칸은 `false`.
  final bool inMonth;
}

/// 한 칸이 기간 안에서 차지하는 자리.
enum ShadcnRangeSpot { none, only, start, middle, end }

/// 요일 헤더 줄. 순서가 로케일을 따라가는지 테스트가 이 줄만 집어서 본다.
const weekdayHeaderKey = ValueKey<String>('shadcn_calendar_weekdays');

/// 한 주의 요일 인덱스를 로케일 시작 요일부터 돌려준다.
///
/// `MaterialLocalizations.narrowWeekdays` 는 **일요일 시작 고정 배열**이라 그대로
/// 쓰면 월요일 시작 로케일에서 요일 헤더가 하루씩 밀린다 — 컴파일도 되고 테스트도
/// 통과하므로 조용하다. 실제 소스는
/// `flutter/lib/src/material/calendar_date_picker.dart` 의 `_dayHeaders`.
List<int> shadcnWeekdayOrder(int firstDayOfWeekIndex) => [
  for (var i = 0; i < DateTime.daysPerWeek; i++)
    (firstDayOfWeekIndex + i) % DateTime.daysPerWeek,
];

/// 표시할 달의 6주 × 7일 = 42칸을 만든다.
///
/// **주 수를 고정하는 이유:** 달마다 5주/6주로 달라지면 달을 넘길 때 달력 높이가
/// 튄다. 미리보기 캔버스에서 이게 특히 눈에 거슬린다. 최대치는 선행 6칸 + 31일 =
/// 37칸이라 42는 항상 충분하다.
List<ShadcnCalendarDay> shadcnCalendarGrid({
  required DateTime month,
  required int firstDayOfWeekIndex,
}) {
  final offset = _firstDayOffset(month.year, month.month, firstDayOfWeekIndex);
  final lastDay = _daysInMonth(month.year, month.month);

  return [
    for (var i = 0; i < DateTime.daysPerWeek * 6; i++)
      () {
        final dayNumber = i - offset + 1;
        return ShadcnCalendarDay(
          // 날짜 산술을 생성자로 한다. `add(Duration(days: 1))` 은 서머타임 경계에서
          // 23/25시간을 더해 하루를 건너뛰거나 되돌아간다.
          date: DateTime(month.year, month.month, dayNumber),
          inMonth: dayNumber >= 1 && dayNumber <= lastDay,
        );
      }(),
  ];
}

/// 한 칸이 기간 안에서 어디인지 판정한다.
///
/// 시각은 버린다 — 호출자가 `DateTime.now()` 를 그대로 넘기는 경우가 실제로 있다.
/// 시작/끝이 뒤집혀 들어와도 순서대로 해석한다 (두 번 탭하는 흐름에서 나온다).
ShadcnRangeSpot shadcnRangeSpot({
  required DateTime day,
  required DateTime? start,
  required DateTime? end,
}) {
  if (start == null) return ShadcnRangeSpot.none;

  final d = _dateOnly(day);
  var s = _dateOnly(start);

  if (end == null) {
    return d == s ? ShadcnRangeSpot.only : ShadcnRangeSpot.none;
  }

  var e = _dateOnly(end);
  if (e.isBefore(s)) (s, e) = (e, s);

  if (s == e) return d == s ? ShadcnRangeSpot.only : ShadcnRangeSpot.none;
  if (d == s) return ShadcnRangeSpot.start;
  if (d == e) return ShadcnRangeSpot.end;
  if (d.isAfter(s) && d.isBefore(e)) return ShadcnRangeSpot.middle;
  return ShadcnRangeSpot.none;
}

/// 그 날을 고를 수 있는가. 경계는 **포함**이고, 시각은 버린다.
///
/// 시각을 안 버리면 `firstDate: DateTime.now()` 를 준 호출자가 오늘 하루를 통째로
/// 잃는다 — 오늘 자정은 지금 시각보다 앞서기 때문이다.
bool shadcnDayEnabled({
  required DateTime day,
  required DateTime? firstDate,
  required DateTime? lastDate,
}) {
  final d = _dateOnly(day);
  if (firstDate != null && d.isBefore(_dateOnly(firstDate))) return false;
  if (lastDate != null && d.isAfter(_dateOnly(lastDate))) return false;
  return true;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 그 달 1일이 주의 시작에서 몇 칸 떨어져 있는가.
///
/// `flutter/lib/src/material/date.dart` 의 `DateUtils.firstDayOffset` 과 같은 식이다.
/// Dart 의 `%` 가 음수 피연산자에서도 비음수를 돌려주는 데 기대고 있다.
int _firstDayOffset(int year, int month, int firstDayOfWeekIndex) {
  final weekdayFromMonday = DateTime(year, month).weekday - 1;
  final startFromMonday = (firstDayOfWeekIndex - 1) % DateTime.daysPerWeek;
  return (weekdayFromMonday - startFromMonday) % DateTime.daysPerWeek;
}

/// `DateUtils.getDaysInMonth` 과 같은 규칙 (그레고리력 100/400년 예외 포함).
int _daysInMonth(int year, int month) {
  if (month == DateTime.february) {
    final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    return isLeap ? 29 : 28;
  }
  const lengths = <int>[31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return lengths[month - 1];
}

/// tweakcn 테마를 따르는 달력.
///
/// 선택 상태를 스스로 들고 있지 않는다 — 형제 컴포넌트와 같이 호출자가 값을 주고
/// 콜백을 받는다.
class ShadcnCalendar extends StatelessWidget {
  const ShadcnCalendar({
    super.key,
    required this.month,
    this.selected,
    this.rangeStart,
    this.rangeEnd,
    this.today,
    this.firstDate,
    this.lastDate,
    this.onDaySelected,
    this.onMonthChanged,
  });

  /// 표시할 달. 일(day)은 무시한다.
  final DateTime month;

  /// 고를 수 있는 범위. 경계는 포함이고, 밖은 흐리게 그려지고 눌러도 반응하지 않는다.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// 단일 선택 값. 기간 모드에서는 `rangeStart`/`rangeEnd` 를 쓴다.
  final DateTime? selected;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  /// 오늘. 넘기지 않으면 `DateTime.now()`. 테스트가 고정하기 위한 구멍이다.
  final DateTime? today;

  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final l10n = MaterialLocalizations.of(context);
    final order = shadcnWeekdayOrder(l10n.firstDayOfWeekIndex);
    final grid = shadcnCalendarGrid(
      month: month,
      firstDayOfWeekIndex: l10n.firstDayOfWeekIndex,
    );
    final now = _dateOnly(today ?? DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(colors, radius, l10n),
        SizedBox(height: 8.h),
        Row(
          key: weekdayHeaderKey,
          children: [
            for (final index in order)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.narrowWeekdays[index],
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var slot = 0; slot < DateTime.daysPerWeek; slot++)
                Expanded(
                  child: _cell(
                    colors,
                    radius,
                    grid[week * DateTime.daysPerWeek + slot],
                    now,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _header(
    TweakcnColors colors,
    TweakcnRadius radius,
    MaterialLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _arrow(colors, radius, Icons.chevron_left, -1),
        // Flexible 이 없으면 글자 배율을 크게 쓰는 사용자에게서 이 줄이 넘친다.
        // 실측: textScaler 3.0 에서 오른쪽으로 61px 초과 (2.5 까지는 멀쩡).
        Flexible(
          child: Text(
            l10n.formatMonthYear(DateTime(month.year, month.month)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
        ),
        _arrow(colors, radius, Icons.chevron_right, 1),
      ],
    );
  }

  Widget _arrow(
    TweakcnColors colors,
    TweakcnRadius radius,
    IconData icon,
    int delta,
  ) {
    return GestureDetector(
      onTap: onMonthChanged == null
          ? null
          : () => onMonthChanged!(DateTime(month.year, month.month + delta)),
      child: Container(
        width: 28.r,
        height: 28.r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius.md.r),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 16.r, color: colors.foreground),
      ),
    );
  }

  Widget _cell(
    TweakcnColors colors,
    TweakcnRadius radius,
    ShadcnCalendarDay day,
    DateTime now,
  ) {
    final spot = shadcnRangeSpot(
      day: day.date,
      start: rangeStart,
      end: rangeEnd,
    );
    final isSelected =
        (selected != null && _dateOnly(selected!) == day.date) ||
        spot == ShadcnRangeSpot.only ||
        spot == ShadcnRangeSpot.start ||
        spot == ShadcnRangeSpot.end;
    final isMiddle = spot == ShadcnRangeSpot.middle;
    final isToday = day.date == now;
    final enabled = shadcnDayEnabled(
      day: day.date,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    final Color background;
    final Color foreground;
    if (!enabled) {
      // 고를 수 없는 날은 선택/기간 칠보다 우선한다. 칠해두고 안 눌리면
      // 눌러도 되는 것처럼 보인다.
      background = Colors.transparent;
      foreground = colors.mutedForeground.withValues(alpha: 0.4);
    } else if (isSelected) {
      background = colors.primary;
      foreground = colors.primaryForeground;
    } else if (isMiddle) {
      background = colors.accent;
      foreground = colors.accentForeground;
    } else {
      background = Colors.transparent;
      foreground = day.inMonth ? colors.foreground : colors.mutedForeground;
    }

    return GestureDetector(
      onTap: onDaySelected == null || !enabled
          ? null
          : () => onDaySelected!(day.date),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34.h,
        margin: EdgeInsets.all(1.r),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius.md.r),
          border: isToday && !isSelected && enabled
              ? Border.all(color: colors.primary)
              : null,
        ),
        child: Center(
          child: Text(
            '${day.date.day}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isSelected || (isToday && enabled)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
