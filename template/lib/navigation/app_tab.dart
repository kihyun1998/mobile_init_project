import 'package:flutter/material.dart';

import '../ui/screens/home/home_screen.dart';
import '../ui/screens/search/search_screen.dart';
import '../ui/screens/profile/profile_screen.dart';

/// 바텀 네비게이션 탭 정의
/// 탭 추가/삭제 시 이 파일만 수정하면 됨
enum AppTab {
  home(icon: Icons.home_outlined, activeIcon: Icons.home, labelKey: 'tabHome'),
  search(
    icon: Icons.search_outlined,
    activeIcon: Icons.search,
    labelKey: 'tabSearch',
  ),
  profile(
    icon: Icons.person_outlined,
    activeIcon: Icons.person,
    labelKey: 'tabProfile',
  );

  final IconData icon;
  final IconData activeIcon;
  final String labelKey;

  const AppTab({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });

  Widget buildScreen() {
    return switch (this) {
      AppTab.home => const HomeScreen(),
      AppTab.search => const SearchScreen(),
      AppTab.profile => const ProfileScreen(),
    };
  }
}
