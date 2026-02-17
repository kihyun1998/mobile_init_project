import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/generated/l10n.dart';
import '../../../core/theme/tweakcn_theme.g.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).tabProfile),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64.r,
              color: colors.mutedForeground,
            ),
            SizedBox(height: 16.h),
            Text(
              S.of(context).tabProfile,
              style: TextStyle(
                fontSize: 18.sp,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
