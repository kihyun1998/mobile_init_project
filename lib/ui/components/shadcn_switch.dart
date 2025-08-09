import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/provider/theme_provider.dart';

class ShadcnSwitch extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.color;
    
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
              ? colors.disabled
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
                      ? colors.onPrimary
                      : colors.onSurface,
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

class ShadcnSwitchWithLabel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.color;
    final font = ref.font;

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
                  style: font.responsive(context, font.mediumText14).copyWith(
                    color: disabled ? colors.disabled : colors.onSurface,
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    description!,
                    style: font.responsive(context, font.regularText12).copyWith(
                      color: disabled ? colors.disabled : colors.mutedForeground,
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