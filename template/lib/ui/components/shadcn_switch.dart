import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';
import 'shadcn_shadow.dart';

/// tweakcn 테마를 따르는 스위치.
///
/// `ToggleableStateMixin` (`package:flutter/widgets.dart` 가 내보낸다) 위에
/// 앉아 있다. Material 의 `Switch` 자신이 그 위에 앉아 있는 그 믹스인이고,
/// `buildToggleableWithChild` 가 포커스·키보드·제스처·`enabled` 를 맡는다.
/// 그림은 그대로 우리가 그리므로 색과 치수가 한 글자도 바뀌지 않는다.
///
/// ## 왜 손으로 붙이지 않았나, 그리고 왜 `checked` 가 아닌가
///
/// 교체 전 실측(#26, 2026-08-05)에서 `flags=()` `actions=(tap)` 으로 나갔다 —
/// 플래그가 하나도 없었다.
///
/// **스위치는 `checked` 가 아니라 `toggled` 다.** Material 과 Cupertino 둘 다
/// `Semantics(toggled: value)` 를 쓴다 (`material/switch.dart:1074`,
/// `cupertino/switch.dart:753`). 형제 작업인 라디오는 `checked` 였으므로,
/// 거기서 유추했으면 틀린 플래그를 실었을 것이다.
///
/// 라디오와 달리 **플랫폼 분기가 없다.** Cupertino 쪽의
/// `defaultTargetPlatform` 분기는 햅틱용이고 시맨틱과 무관하다 — 읽어서 확인했다.
class ShadcnSwitch extends StatefulWidget {
  const ShadcnSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  State<ShadcnSwitch> createState() => _ShadcnSwitchState();
}

class _ShadcnSwitchState extends State<ShadcnSwitch>
    with TickerProviderStateMixin, ToggleableStateMixin {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ShadcnSwitch');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get tristate => false;

  @override
  bool? get value => widget.value;

  @override
  ValueChanged<bool?>? get onChanged {
    final handler = widget.onChanged;
    if (widget.disabled || handler == null) return null;
    // 믹스인은 tristate 를 위해 `bool?` 을 넘긴다. `tristate` 가 false 라
    // null 이 올 일이 없지만, 방어적으로 현재 값을 유지한다.
    return (next) => handler(next ?? widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: widget.value,
      child: buildToggleableWithChild(
        focusNode: _focusNode,
        mouseCursor: const WidgetStatePropertyAll<MouseCursor>(
          SystemMouseCursors.click,
        ),
        child: ShadcnSwitchVisual(
          value: widget.value,
          disabled: widget.disabled || widget.onChanged == null,
        ),
      ),
    );
  }
}

/// 스위치의 **그림만.** 제스처도 시맨틱도 없다.
///
/// 갈라둔 이유는 [ShadcnSwitchWithLabel] 때문이다. 거기서 [ShadcnSwitch] 를
/// 그대로 쓰면 제스처와 시맨틱 노드가 이중으로 겹친다 — 교체 전 실측에서
/// `label=""` `actions=(tap)` 인 빈 노드가 실제로 하나 더 나갔다.
class ShadcnSwitchVisual extends StatelessWidget {
  const ShadcnSwitchVisual({
    super.key,
    required this.value,
    required this.disabled,
  });

  final bool value;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 44.w,
      height: 24.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: disabled
            ? colors.mutedForeground
            : value
            ? colors.primary
            : colors.border,
        // **그림자는 트랙에 있다, 엄지가 아니라.** shadcn 원본이
        // `SwitchPrimitive.Root` 에 `shadow-xs` 를 걸고
        // (switch.tsx:20) `SwitchPrimitive.Thumb` 에는 아무것도 안 건다
        // (switch.tsx:28). 예전 우리 코드는 정확히 반대였다 — 엄지에 손으로
        // 고른 검정 10% 를 그렸고 트랙은 비어 있었다 (#25).
        boxShadow: context.tweakcnShadows.shadowXs.r,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20.r,
          height: 20.r,
          margin: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disabled
                ? colors.mutedForeground
                : value
                ? colors.primaryForeground
                : colors.foreground,
          ),
        ),
      ),
    );
  }
}

/// 라벨과 설명을 옆에 둔 스위치. **타일 전체가 하나의 컨트롤이다.**
///
/// 안에서 [ShadcnSwitch] 를 쓰지 않고 [ShadcnSwitchVisual] 을 쓴다.
/// [ShadcnSwitch] 를 쓰면 제스처와 포커스가 이중이 되고 시맨틱 노드가 갈린다 —
/// 교체 전 실측에서 타일 노드 밑에 `label=""` `actions=(tap)` 인 노드가 하나 더
/// 나갔다. Material 의 `SwitchListTile` 은 `MergeSemantics` + `ExcludeFocus` 로
/// 그 상황을 다루지만(`switch_list_tile.dart:578, 652`), 애초에 안쪽에 컨트롤을
/// 두지 않으면 합칠 것도 없다.
class ShadcnSwitchWithLabel extends StatefulWidget {
  const ShadcnSwitchWithLabel({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? description;
  final bool disabled;

  @override
  State<ShadcnSwitchWithLabel> createState() => _ShadcnSwitchWithLabelState();
}

class _ShadcnSwitchWithLabelState extends State<ShadcnSwitchWithLabel>
    with TickerProviderStateMixin, ToggleableStateMixin {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ShadcnSwitchWithLabel');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get tristate => false;

  @override
  bool? get value => widget.value;

  @override
  ValueChanged<bool?>? get onChanged {
    final handler = widget.onChanged;
    if (widget.disabled || handler == null) return null;
    return (next) => handler(next ?? widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final disabled = widget.disabled || widget.onChanged == null;

    return Semantics(
      toggled: widget.value,
      child: buildToggleableWithChild(
        focusNode: _focusNode,
        mouseCursor: const WidgetStatePropertyAll<MouseCursor>(
          SystemMouseCursors.click,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: disabled
                          ? colors.mutedForeground
                          : colors.foreground,
                    ),
                  ),
                  if (widget.description != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      widget.description!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            ShadcnSwitchVisual(value: widget.value, disabled: disabled),
          ],
        ),
      ),
    );
  }
}
