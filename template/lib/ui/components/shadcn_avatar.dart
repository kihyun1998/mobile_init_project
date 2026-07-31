import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnAvatar extends StatelessWidget {
  const ShadcnAvatar({super.key, this.initial, this.size = 40, this.imageUrl});

  final String? initial;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.muted,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Center(
        child: Text(
          initial ?? '',
          style: TextStyle(
            fontSize: (size * 0.4).sp,
            fontWeight: FontWeight.w500,
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}
