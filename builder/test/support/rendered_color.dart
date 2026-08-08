import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/ui/components/shadcn_card.dart';

/// 화면에 실제로 그려진 첫 카드의 배경색.
///
/// 테마 값을 다시 읽는 게 아니라 렌더 트리에서 꺼내온다. 테마가 컴포넌트까지
/// 닿았는지를 봐야 미리보기가 동작한다고 말할 수 있다.
Color renderedCardColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(ShadcnCard),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

/// 화면에 실제로 그려진 첫 카드의 그림자.
///
/// [renderedCardColor] 와 같은 이유로 렌더 트리에서 꺼낸다. `PreviewTheme` 이
/// 그림자를 들고 있는 것과, 그 그림자가 **컴포넌트까지 닿는 것**은 다른
/// 이야기다 — #25 이전에는 앞의 것만 참이었고 카드는 손으로 고른 검정을
/// 그리고 있었다.
List<BoxShadow> renderedCardShadow(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(ShadcnCard),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).boxShadow ?? const [];
}
