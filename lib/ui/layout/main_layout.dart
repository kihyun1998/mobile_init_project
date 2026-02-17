import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/app_tab.dart';
import '../../navigation/provider/navigation_provider.dart';
import '../components/app_bottom_nav_bar.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: AppTab.values.map((tab) => tab.buildScreen()).toList(),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(navigationProvider.notifier).selectTab(index),
      ),
    );
  }
}
