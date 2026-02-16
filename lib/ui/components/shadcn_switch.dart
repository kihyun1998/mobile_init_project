import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnSwitch extends StatelessWidget {
  const ShadcnSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return GestureDetector(
      onTap: disabled || onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44.w,
        height: 24.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: disabled
              ? colors.mutedForeground
              : value
                  ? colors.primary
                  : colors.border,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.r,
            height: 20.r,
            margin: EdgeInsets.all(2.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disabled
                  ? colors.mutedForeground
                  : value
                      ? colors.primaryForeground
                      : colors.foreground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2.r,
                  offset: Offset(0, 1.r),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShadcnSwitchWithLabel extends StatelessWidget {
  const ShadcnSwitchWithLabel({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? description;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return GestureDetector(
      onTap: disabled || onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: disabled ? colors.mutedForeground : colors.foreground,
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: disabled
                          ? colors.mutedForeground
                          : colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          ShadcnSwitch(
            value: value,
            onChanged: onChanged,
            disabled: disabled,
          ),
        ],
      ),
    );
  }
}
