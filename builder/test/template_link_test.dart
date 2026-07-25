import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_button.dart';

void main() {
  // 이 도구 전체가 "template/ 의 진짜 컴포넌트를 빌더 안에서 렌더할 수 있다" 는
  // 전제 위에 서 있다. 미리보기가 사본이 아니라 같은 파일을 그리기 때문에
  // 미리보기와 생성 결과가 어긋날 수 없다는 것이 핵심 약속이다.
  //
  // 이 테스트가 깨지면 그 약속이 무너졌다는 뜻이다.
  testWidgets('template/ 컴포넌트가 빌더 위젯 트리에서 렌더된다', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          theme: TweakcnTheme.light,
          home: Scaffold(
            body: ShadcnButton(onPressed: () {}, child: const Text('Primary')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Primary'), findsOneWidget);
    expect(find.byType(ShadcnButton), findsOneWidget);
  });
}
