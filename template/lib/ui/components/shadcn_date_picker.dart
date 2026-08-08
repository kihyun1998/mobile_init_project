import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';
import 'shadcn_calendar.dart';
import 'shadcn_shadow.dart';

/// 트리거를 눌러 달력을 띄우고 날짜를 고른다.
///
/// 단일과 기간을 이름 있는 생성자로 가른다. 하나의 위젯에 콜백 둘을 달아두면
/// 호출자가 어느 쪽을 쓰는지 타입으로 드러나지 않는다.
class ShadcnDatePicker extends StatelessWidget {
  const ShadcnDatePicker.single({
    super.key,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
    this.label,
    this.placeholder,
    this.today,
    this.firstDate,
    this.lastDate,
  }) : _date = value,
       _range = null,
       _onDate = onChanged,
       _onRange = null;

  const ShadcnDatePicker.range({
    super.key,
    required DateTimeRange? value,
    required ValueChanged<DateTimeRange> onChanged,
    this.label,
    this.placeholder,
    this.today,
    this.firstDate,
    this.lastDate,
  }) : _date = null,
       _range = value,
       _onDate = null,
       _onRange = onChanged;

  final DateTime? _date;
  final DateTimeRange? _range;
  final ValueChanged<DateTime>? _onDate;
  final ValueChanged<DateTimeRange>? _onRange;

  final String? label;
  final String? placeholder;

  /// 오늘. 테스트가 고정하기 위한 구멍이다. [ShadcnCalendar.today] 로 내려간다.
  final DateTime? today;

  /// 고를 수 있는 범위. 그대로 [ShadcnCalendar] 로 내려간다.
  final DateTime? firstDate;
  final DateTime? lastDate;

  bool get _isRange => _onRange != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final l10n = MaterialLocalizations.of(context);
    final text = _triggerText(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colors.foreground,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        GestureDetector(
          onTap: () => _open(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 36.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius.md.r),
              border: Border.all(color: colors.border),
              // 트리거는 outline 버튼 자리다 — button.tsx:16 과 같은
              // `shadow-xs`.
              boxShadow: context.tweakcnShadows.shadowXs.r,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14.r,
                  color: colors.mutedForeground,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    text ?? placeholder ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: text != null
                          ? colors.foreground
                          : colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _triggerText(MaterialLocalizations l10n) {
    if (_isRange) {
      final range = _range;
      if (range == null) return null;
      return '${l10n.formatMediumDate(range.start)} – '
          '${l10n.formatMediumDate(range.end)}';
    }
    final date = _date;
    return date == null ? null : l10n.formatMediumDate(date);
  }

  Future<void> _open(BuildContext context) async {
    final initial = _isRange ? _range?.start : _date;

    final picked = await showDialog<Object>(
      context: context,
      builder: (_) => _CalendarDialog(
        initialMonth: initial ?? today ?? DateTime.now(),
        isRange: _isRange,
        selected: _date,
        range: _range,
        today: today,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );

    if (picked is DateTime) _onDate?.call(picked);
    if (picked is DateTimeRange) _onRange?.call(picked);
  }
}

/// 달력을 담은 다이얼로그. 열려 있는 동안의 상태(보고 있는 달, 고르는 중인 기간)를
/// 여기서만 들고 있다가 확정된 값만 돌려준다.
class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog({
    required this.initialMonth,
    required this.isRange,
    required this.selected,
    required this.range,
    required this.today,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialMonth;
  final bool isRange;
  final DateTime? selected;
  final DateTimeRange? range;
  final DateTime? today;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime _month = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );
  late DateTime? _start = widget.range?.start;
  late DateTime? _end = widget.range?.end;

  void _onDay(DateTime day) {
    if (!widget.isRange) {
      Navigator.of(context).pop(day);
      return;
    }

    setState(() {
      // 시작만 있는 상태에서 두 번째를 찍으면 기간이 확정된다. 그 외에는 항상
      // 새 시작으로 다시 시작한다 — 확정된 기간 위에 또 찍었을 때 어느 끝을
      // 옮길지 추측하는 것보다 예측 가능하다.
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else {
        _end = day;
      }
    });

    final start = _start;
    final end = _end;
    if (start != null && end != null) {
      final ordered = end.isBefore(start)
          ? DateTimeRange(start: end, end: start)
          : DateTimeRange(start: start, end: end);
      Navigator.of(context).pop(ordered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: colors.popover,
          borderRadius: BorderRadius.circular(radius.lg.r),
          border: Border.all(color: colors.border),
          // 팝오버(popover.tsx:33 의 `shadow-md`)가 아니라 다이얼로그다 —
          // 우리는 `Dialog` 로 띄우므로 dialog.tsx:64 의 `shadow-lg` 를 쓴다.
          boxShadow: context.tweakcnShadows.shadowLg.r,
        ),
        child: ShadcnCalendar(
          month: _month,
          selected: widget.isRange ? null : widget.selected,
          rangeStart: widget.isRange ? _start : null,
          rangeEnd: widget.isRange ? _end : null,
          today: widget.today,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDaySelected: _onDay,
          onMonthChanged: (m) => setState(() => _month = m),
        ),
      ),
    );
  }
}
