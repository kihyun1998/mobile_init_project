import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnSelect<T> extends StatelessWidget {
  const ShadcnSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.label,
    this.placeholder,
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final List<ShadcnSelectItem<T>> items;
  final String? label;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final selectedItem = items.cast<ShadcnSelectItem<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => null,
    );

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
        PopupMenuButton<T>(
          onSelected: onChanged,
          color: colors.popover,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.md.r),
            side: BorderSide(color: colors.border),
          ),
          offset: Offset(0, 4.h),
          itemBuilder: (context) => items
              .map(
                (item) => PopupMenuItem<T>(
                  value: item.value,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colors.popoverForeground,
                    ),
                  ),
                ),
              )
              .toList(),
          child: Container(
            height: 36.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius.md.r),
              border: Border.all(color: colors.border),
              color: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedItem?.label ?? placeholder ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: selectedItem != null
                        ? colors.foreground
                        : colors.mutedForeground,
                  ),
                ),
                Icon(
                  Icons.unfold_more,
                  size: 16.r,
                  color: colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ShadcnSelectItem<T> {
  final T value;
  final String label;

  const ShadcnSelectItem({required this.value, required this.label});
}
