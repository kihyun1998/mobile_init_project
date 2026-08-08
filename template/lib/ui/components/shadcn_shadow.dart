import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// tweakcn 그림자 한 단계를 화면 배율에 실어 준다.
///
/// `context.tweakcnShadows.shadowSm.r` 로 읽는다 — 모서리를
/// `context.tweakcnRadius.md.r` 로 읽는 것과 같은 모양이고, 같은 이유다.
/// 토큰 값은 CSS 논리 픽셀, 즉 기준 디자인(375×812) 위의 생짜 픽셀이다.
/// 모서리만 배율을 타고 그림자는 안 타면 큰 화면에서 둘이 어긋난다.
///
/// `flutter_screenutil` 이 `EdgeInsets` · `BorderRadius` · `BoxConstraints` 에
/// 이미 같은 이름의 확장을 달아두고 있다 (`size_extension.dart:81, 119, 156`).
/// 이건 그 관례를 `List<BoxShadow>` 로 잇는 것이지 새 관례가 아니다.
///
/// CSS 가 어떤 단계도 정의하지 않으면 그 단계는 빈 리스트로 나오고
/// (`TweakcnShadows.fromShadowMap`), 여기서도 빈 리스트로 남는다. 붙여넣은
/// CSS 에 그림자가 없으면 그림자를 안 그리는 것이 맞다.
extension ShadcnShadowScale on List<BoxShadow> {
  /// 오프셋 · 흐림 · 퍼짐을 화면 배율로 옮긴 사본. 색은 그대로다.
  List<BoxShadow> get r => [
    for (final shadow in this)
      BoxShadow(
        color: shadow.color,
        offset: Offset(shadow.offset.dx.r, shadow.offset.dy.r),
        blurRadius: shadow.blurRadius.r,
        spreadRadius: shadow.spreadRadius.r,
        blurStyle: shadow.blurStyle,
      ),
  ];
}
