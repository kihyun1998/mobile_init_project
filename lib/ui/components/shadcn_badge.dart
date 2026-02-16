import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

enum ShadcnBadgeVariant { defaultStyle, secondary, outline, destructive }

class ShadcnBadge extends StatelessWidget {
  const ShadcnBadge({
    super.key,
    required this.label,
    this.variant = ShadcnBadgeVariant.defaultStyle,
  });

  final String label;
  final ShadcnBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    Color bg;
    Color fg;
    Color? borderColor;

    switch (variant) {
      case ShadcnBadgeVariant.defaultStyle:
        bg = colors.primary;
        fg = colors.primaryForeground;
        break;
      case ShadcnBadgeVariant.secondary:
        bg = colors.secondary;
        fg = colors.secondaryForeground;
        break;
      case ShadcnBadgeVariant.outline:
        bg = Colors.transparent;
        fg = colors.foreground;
        borderColor = colors.border;
        break;
      case ShadcnBadgeVariant.destructive:
        bg = colors.destructive;
        fg = colors.destructiveForeground;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}
