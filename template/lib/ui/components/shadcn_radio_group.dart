import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

/// tweakcn 테마를 따르는 라디오 그룹.
///
/// `RawRadio` + `RadioGroup` 위에 앉아 있다. 둘 다
/// `package:flutter/widgets.dart` 의 공개 API 이고, `RawRadio` 는 `builder` 로
/// **그림을 우리가 그리게** 해준다 — Material 의 동그라미가 아니라 이 파일의
/// 타일이 그대로 그려진다.
///
/// ## 왜 손으로 `Semantics` 를 붙이지 않았나
///
/// 교체 전에는 `GestureDetector` 하나였고, 시맨틱 트리 실측(#26, 2026-08-05)에서
/// 항목이 `flags=[]` `actions=[tap]` 으로 나갔다 — **플래그가 하나도 없었다.**
/// 스크린 리더에게 이 둘은 서로 배타적인 선택지가 아니라 그냥 탭 되는 글자였다.
///
/// 그런데 손으로 붙였다면 **틀리게 붙였을 것이다.** `RawRadio`
/// (`widgets/raw_radio.dart:200-229`) 는 `selected` 와 `hint` 를 **플랫폼마다
/// 다르게** 싣는다:
///
/// | 플랫폼 | `checked` | `selected` | `hint` |
/// |---|---|---|---|
/// | android · linux · windows | 값 | **null** | **null** |
/// | ios · macos | 값 | 값 | 안 골라진 것에만 `radioButtonUnselectedLabel` |
///
/// 상류 주석이 이유를 적어둔다 — iOS 는 `selected` 로 이미 알리므로 둘 다 세우면
/// **중복 안내**가 된다. 이건 모바일 템플릿이라 두 분기가 다 나간다.
///
/// 그 `hint` 는 `flutter_localizations` 가 언어별로 들고 있다 (ko 는
/// `"선택되지 않음"`). 손으로 붙였다면 우리 arb 에 문구를 만들고 언어마다
/// 관리해야 했다.
///
/// 배타 그룹 안에서의 방향키 이동과 포커스 순서도 `RadioGroup` 이 한다.
///
/// **`shadcn_checkbox` 가 패키지로 얻은 것을 이쪽은 프레임워크 기본형으로 얻는다**
/// — "손으로 `Semantics` 를 붙인다" 가 유일한 답이 아니라는 #27 의 교훈이 여기서
/// 한 번 더 성립한다.
class ShadcnRadioGroup<T> extends StatelessWidget {
  const ShadcnRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final List<ShadcnRadioItem<T>> items;

  @override
  Widget build(BuildContext context) {
    final handler = onChanged;

    return RadioGroup<T>(
      groupValue: value,
      // `RadioGroup` 은 `ValueChanged<T?>` 를 받는다. null 은 `toggleable` 인
      // 라디오가 선택을 지울 때 오는데, 아래에서 `toggleable: false` 이므로
      // 우리 표면으로는 올라올 일이 없다. 그래도 우리 API 가 `ValueChanged<T>`
      // 라 방어적으로 거른다.
      onChanged: (next) {
        if (next != null) handler?.call(next);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => _RadioTile<T>(
                item: item,
                selected: value == item.value,
                enabled: handler != null,
              ),
            )
            .toList(),
      ),
    );
  }
}

class ShadcnRadioItem<T> {
  final T value;
  final String label;
  final String? description;

  const ShadcnRadioItem({
    required this.value,
    required this.label,
    this.description,
  });
}

/// 항목 하나. `RawRadio` 가 시맨틱·포커스·제스처를 맡고 그림만 여기서 그린다.
///
/// `RawRadio` 가 `focusNode` 를 **필수로** 받으므로 상태가 있어야 한다 —
/// 만들어 들고 있다가 버려야 하는 것이 이 위젯이 `StatefulWidget` 인 유일한
/// 이유다.
class _RadioTile<T> extends StatefulWidget {
  const _RadioTile({
    required this.item,
    required this.selected,
    required this.enabled,
  });

  final ShadcnRadioItem<T> item;
  final bool selected;
  final bool enabled;

  @override
  State<_RadioTile<T>> createState() => _RadioTileState<T>();
}

class _RadioTileState<T> extends State<_RadioTile<T>> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'ShadcnRadio(${widget.item.label})',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawRadio<T>(
      value: widget.item.value,
      groupRegistry: RadioGroup.maybeOf<T>(context),
      enabled: widget.enabled,
      focusNode: _focusNode,
      autofocus: false,
      // 다시 눌러 선택을 지울 수 있게 하지 않는다. 지우면 `onChanged` 로 null 이
      // 올라오는데 우리 표면은 `ValueChanged<T>` 다.
      toggleable: false,
      mouseCursor: const WidgetStatePropertyAll<MouseCursor>(
        SystemMouseCursors.click,
      ),
      builder: (context, state) => _tile(context),
    );
  }

  Widget _tile(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final selected = widget.selected;

    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius.md.r),
        border: Border.all(
          color: selected ? colors.ring : colors.border,
          width: 1,
        ),
        color: selected
            ? colors.input.withValues(alpha: 0.2)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 16.r,
            height: 16.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 1.r),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: colors.foreground,
                  ),
                ),
                if (widget.item.description != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    widget.item.description!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
