import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnCheckbox extends StatelessWidget {
  const ShadcnCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return GestureDetector(
      onTap: disabled || onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16.r,
            height: 16.r,
            decoration: BoxDecoration(
              color: value ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(3.r),
              border: Border.all(
                color: value
                    ? colors.primary
                    : disabled
                    ? colors.mutedForeground
                    : colors.primary,
                width: 1.r,
              ),
            ),
            child: value
                ? Icon(Icons.check, size: 12.r, color: colors.primaryForeground)
                : null,
          ),
          if (label != null) ...[
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: disabled ? colors.mutedForeground : colors.foreground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
