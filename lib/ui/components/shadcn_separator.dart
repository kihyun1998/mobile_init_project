import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnSeparator extends StatelessWidget {
  const ShadcnSeparator({
    super.key,
    this.vertical = false,
    this.height,
    this.margin,
  });

  final bool vertical;
  final double? height;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    if (vertical) {
      return Container(
        width: 1,
        height: height ?? double.infinity,
        margin: margin,
        color: colors.border,
      );
    }

    return Container(
      height: 1,
      margin: margin ?? EdgeInsets.symmetric(vertical: 16.h),
      color: colors.border,
    );
  }
}
