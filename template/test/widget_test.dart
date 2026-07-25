import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/main.dart';
import 'package:mobile_init_project/ui/components/app_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // main() 이 하는 초기화를 대신한다. MyApp 은 이 전역이 채워져 있다고 가정한다.
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  });

  testWidgets('앱이 예외 없이 뜨고 바텀 내비게이션이 보인다', (tester) async {
    // 기본 테스트 표면은 800x812 가 아니라 800x600 이다. ScreenUtil 은 가로와
    // 세로 배율을 따로 계산하므로 그 상태로 그리면 .w 는 2배로 늘고 .h 는
    // 줄어들어 실제 기기에서 나지 않는 오버플로가 난다. 기준 크기로 맞춘다.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
  });
}
