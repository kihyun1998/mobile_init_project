import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';
import 'shadcn_shadow.dart';

class ShadcnCard extends StatelessWidget {
  const ShadcnCard({
    super.key,
    this.title,
    this.description,
    this.titleWidget,
    this.content,
    this.footer,
    this.padding,
  });

  final String? title;
  final String? description;
  final Widget? titleWidget;
  final Widget? content;
  final Widget? footer;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(radius.lg.r),
        border: Border.all(color: colors.border, width: 1),
        // shadcn 원본이 카드에 `shadow-sm` 을 건다 (card.tsx:10). 예전에는
        // 손으로 고른 검정 3% 를 그렸고 어떤 토큰과도 대응하지 않았다 (#25).
        boxShadow: context.tweakcnShadows.shadowSm.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || titleWidget != null)
            Padding(
              padding: padding ?? EdgeInsets.all(16.r),
              child:
                  titleWidget ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.cardForeground,
                        ),
                      ),
                      if (description != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
            ),
          if (content != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.r, 0, 16.r, 16.r),
              child: content,
            ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.r, 0, 16.r, 16.r),
              child: footer,
            ),
        ],
      ),
    );
  }
}
