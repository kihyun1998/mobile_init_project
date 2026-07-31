import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnRadioGroup<T> extends StatelessWidget {
  const ShadcnRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final List<ShadcnRadioItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => _RadioTile(
              item: item,
              selected: value == item.value,
              onTap: () => onChanged?.call(item.value),
            ),
          )
          .toList(),
    );
  }
}

class ShadcnRadioItem<T> {
  final T value;
  final String label;
  final String? description;

  const ShadcnRadioItem({
    required this.value,
    required this.label,
    this.description,
  });
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ShadcnRadioItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? colors.ring : colors.border,
            width: 1,
          ),
          color: selected
              ? colors.input.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 16.r,
              height: 16.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 1.r),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: colors.foreground,
                    ),
                  ),
                  if (item.description != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      item.description!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
