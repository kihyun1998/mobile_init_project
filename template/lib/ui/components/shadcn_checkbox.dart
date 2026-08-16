import 'package:flutter/material.dart';
import 'package:flutter_checkbox/flutter_checkbox.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';
import 'shadcn_shadow.dart';

/// 상자에 실을 스타일. 색은 전부 여기서 [TweakcnColors] 로 채워 넘긴다.
///
/// **패키지는 색을 스스로 정하지 않는다** — `CheckboxStyle` 의 색 필드가 전부
/// `Color?` 라 우리가 주는 값이 그대로 그려진다. 그래서 미리보기와 생성 결과가
/// 갈릴 자리가 생기지 않는다. 이것이 이 패키지를 들인 근거이므로, 여기서
/// 색을 하나라도 비워두면 그 근거가 무너진다.
///
/// 테스트가 렌더 트리를 거치지 않고 이 값을 직접 보기 위해 공개해 둔다.
///
/// 색과 달리 그림자는 [TweakcnShadows] 에 살아서 인자로 따로 받는다. 다른
/// 컴포넌트들은 `context.tweakcnShadows` 를 그 자리에서 읽지만, 이 함수는
/// 위처럼 context 없이 부를 수 있어야 해서 넘겨받는다.
CheckboxStyle shadcnCheckboxStyle(
  TweakcnColors colors,
  TweakcnShadows shadows, {
  bool disabled = false,
}) {
  return CheckboxStyle(
    size: 16.r,
    // checkbox.tsx:17 — `shadow-xs`. 슬롯은 `flutter_checkbox` 0.3.2 가 줬다
    // (`kihyun1998/flutter_checkbox#8`).
    //
    // **`BlurStyle.outer` 로 바꿔 싣는다.** CSS 의 바깥 `box-shadow` 는 요소
    // 뒤로 잘려서 안 보이는데 Flutter 의 기본 `BlurStyle.normal` 은 도형 밑까지
    // 통째로 칠한다. 우리 [inactiveColor] 가 투명이라, 그대로 실으면 안 켜진
    // 상자를 **통과해 비친다.** 상류가 릴리스 노트에서 직접 권한 방법이고
    // (`0.3.2` — "use `BoxShadow(blurStyle: BlurStyle.outer)` … for the CSS
    // look"), 값을 바꾸는 것이 아니라 CSS 의미론을 미러링하는 것이다.
    //
    // 배율은 `.r` 이 먼저 태우고 `blurStyle` 은 그대로 통과한다
    // (`shadcn_shadow.dart` 의 `ShadcnShadowScale`).
    shadows: [
      for (final shadow in shadows.shadowXs.r)
        BoxShadow(
          color: shadow.color,
          offset: shadow.offset,
          blurRadius: shadow.blurRadius,
          spreadRadius: shadow.spreadRadius,
          blurStyle: BlurStyle.outer,
        ),
    ],
    // **`--radius` 를 따라가지 않는다.** shadcn 원본이 `rounded-[4px]` 로 고정한다
    // (registry/new-york-v4/ui/checkbox.tsx). #23 에서 실측하고 정한 것이고,
    // `radius_token_test.dart` 가 렌더 결과로 못박고 있다.
    borderRadius: 3.r,
    borderWidth: 1.r,
    activeColor: colors.primary,
    checkColor: colors.primaryForeground,
    borderColor: disabled ? colors.mutedForeground : colors.primary,
    inactiveColor: Colors.transparent,
  );
}

/// tweakcn 테마를 따르는 체크박스.
///
/// `flutter_checkbox` 위에 앉아 있다. 직접 그리지 않는 이유는 그 패키지가
/// 시맨틱과 키보드 활성화를 이미 제대로 하기 때문이다 — `CheckboxInteraction`
/// 이 `checked`/`enabled` 를 한 노드에 싣고 Space·Enter 를 받는다. 손으로 만든
/// 이전 구현은 `GestureDetector` 라 스크린 리더에 체크 상태가 나가지 않았다.
class ShadcnCheckbox extends StatelessWidget {
  const ShadcnCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final style = shadcnCheckboxStyle(
      colors,
      context.tweakcnShadows,
      disabled: disabled,
    );
    // 패키지는 tristate 를 위해 `bool?` 을 받는다. 우리 표면은 계속 `bool` 이라
    // null 이 올라올 일이 없지만, 방어적으로 현재 값을 유지한다.
    final onChangedOrNull = onChanged;
    final handler = disabled || onChangedOrNull == null
        ? null
        : (bool? next) => onChangedOrNull(next ?? value);

    return FlutterCheckboxTile(
      value: value,
      onChanged: handler,
      enabled: !disabled,
      checkboxStyle: style,
      label: label,
      gap: 8.w,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      expandWidth: false,
      labelStyle: TextStyle(
        fontSize: 14.sp,
        color: disabled ? colors.mutedForeground : colors.foreground,
      ),
    );
  }
}
