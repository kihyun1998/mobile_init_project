import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/localization/generated/l10n.dart';
import '../../core/theme/tweakcn_theme.g.dart';
import '../../navigation/app_tab.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56.h,
          child: Row(
            children: List.generate(AppTab.values.length, (index) {
              final tab = AppTab.values[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          key: ValueKey('${tab.name}_$isSelected'),
                          size: 24.r,
                          color: isSelected
                              ? colors.primary
                              : colors.mutedForeground,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _getLabel(context, tab),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? colors.primary
                              : colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _getLabel(BuildContext context, AppTab tab) {
    final s = S.of(context);
    return switch (tab) {
      AppTab.home => s.tabHome,
      AppTab.search => s.tabSearch,
      AppTab.profile => s.tabProfile,
    };
  }
}
