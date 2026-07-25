import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_builder/main.dart';

void main() {
  // 빌더 설계 전체가 "template/ 의 진짜 컴포넌트를 빌더 안에서 렌더할 수 있다"에
  // 걸려 있다. 이 테스트가 깨지면 미리보기가 성립하지 않는다는 뜻이다.
  testWidgets('template/ 컴포넌트가 빌더 위젯 트리에서 렌더된다', (tester) async {
    await tester.pumpWidget(const BuilderApp());
    await tester.pumpAndSettle();

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Outline'), findsOneWidget);
  });
}
