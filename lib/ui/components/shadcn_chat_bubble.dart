import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';
import 'shadcn_avatar.dart';

class ShadcnChatBubble extends StatelessWidget {
  const ShadcnChatBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.senderName,
    this.senderInitial,
    this.timestamp,
  });

  final String message;
  final bool isSent;
  final String? senderName;
  final String? senderInitial;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            ShadcnAvatar(initial: senderInitial ?? '?', size: 28),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (senderName != null && !isSent)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Text(
                      senderName!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSent ? colors.primary : colors.muted,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                      bottomLeft:
                          isSent ? Radius.circular(12.r) : Radius.circular(2.r),
                      bottomRight:
                          isSent ? Radius.circular(2.r) : Radius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isSent ? colors.primaryForeground : colors.foreground,
                    ),
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.w, right: 4.w),
                    child: Text(
                      timestamp!,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isSent) ...[
            SizedBox(width: 8.w),
            ShadcnAvatar(initial: senderInitial ?? 'U', size: 28),
          ],
        ],
      ),
    );
  }
}
