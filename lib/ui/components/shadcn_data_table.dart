import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnDataTable<T> extends StatelessWidget {
  const ShadcnDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.selectedRows = const {},
    this.onSelectRow,
    this.onSelectAll,
    this.showCheckboxes = true,
  });

  final List<ShadcnDataColumn> columns;
  final List<ShadcnDataRow<T>> rows;
  final Set<int> selectedRows;
  final ValueChanged<int>? onSelectRow;
  final ValueChanged<bool>? onSelectAll;
  final bool showCheckboxes;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final allSelected =
        rows.isNotEmpty && selectedRows.length == rows.length;

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              if (showCheckboxes) ...[
                _Checkbox(
                  value: allSelected,
                  onChanged: (v) => onSelectAll?.call(v),
                ),
                SizedBox(width: 12.w),
              ],
              ...columns.map(
                (col) => Expanded(
                  flex: col.flex,
                  child: Text(
                    col.label,
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
        ),
        // Rows
        ...rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          final selected = selectedRows.contains(idx);

          return Container(
            decoration: BoxDecoration(
              color: selected
                  ? colors.muted.withValues(alpha: 0.5)
                  : Colors.transparent,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                if (showCheckboxes) ...[
                  _Checkbox(
                    value: selected,
                    onChanged: (_) => onSelectRow?.call(idx),
                  ),
                  SizedBox(width: 12.w),
                ],
                ...row.cells.asMap().entries.map(
                      (cellEntry) => Expanded(
                        flex: columns[cellEntry.key].flex,
                        child: cellEntry.value,
                      ),
                    ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 16.r,
        height: 16.r,
        decoration: BoxDecoration(
          color: value ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(3.r),
          border: Border.all(
            color: value ? colors.primary : colors.mutedForeground,
            width: 1.r,
          ),
        ),
        child: value
            ? Icon(Icons.check, size: 12.r, color: colors.primaryForeground)
            : null,
      ),
    );
  }
}

class ShadcnDataColumn {
  final String label;
  final int flex;

  const ShadcnDataColumn({required this.label, this.flex = 1});
}

class ShadcnDataRow<T> {
  final T data;
  final List<Widget> cells;

  const ShadcnDataRow({required this.data, required this.cells});
}
