import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_tab.dart';

part 'navigation_provider.g.dart';

@Riverpod(dependencies: [], keepAlive: true)
class Navigation extends _$Navigation {
  @override
  int build() => 0;

  /// 인덱스로 탭 선택
  void selectTab(int index) {
    if (index >= 0 && index < AppTab.values.length) {
      state = index;
    }
  }

  /// AppTab 타입으로 탭 선택
  void selectTabByType(AppTab tab) {
    state = tab.index;
  }
}
