import 'package:flutter/material.dart';
import 'package:flutter_dropdown_button/flutter_dropdown_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

/// tweakcn 테마를 따르는 셀렉트.
///
/// `flutter_dropdown_button` 위에 앉아 있다. 직접 그리지 않는 이유는 그 패키지가
/// 오버레이 배치(위/아래 자동), 바깥 탭 닫기, 스크롤·키보드를 이미 하기 때문이다.
///
/// ## 색을 하나도 빠짐없이 넘기는 이유
///
/// **이 패키지는 `flutter_checkbox` 와 다르다.** 그쪽은 안 넘긴 색을
/// `theme.colorScheme.primary` 에서 파생하므로 안 넘겨도 결국 붙여넣은 CSS 에서
/// 왔다. 이쪽은 `DropdownAmbientColors.of(context)` 가 **`ThemeData` 의 레거시
/// 필드**를 읽는데(`resolved_dropdown_style.dart:24-37`), `TweakcnTheme` 는
/// `colorScheme` 과 `extensions` 만 채운다. 실측(#31, 2026-08-05):
///
/// | 필드 | light | dark |
/// |---|---|---|
/// | `cardColor` | `cs.surface` — light 에선 card·background·popover 가 **우연히 같아** CSS 색처럼 보인다 | `cs.surface` = background. card 가 아니다 |
/// | `primaryColor` | `cs.primary` | **`cs.surface`** (#0a0a0a). 선택된 항목의 틴트가 배경과 같아져 사라진다 |
/// | `splash` `highlight` `hover` `disabled` `hint` `iconTheme.color` | 전부 Material 기본 검정 계열 | 전부 Material 기본 흰색 계열 |
///
/// 빠뜨린 색은 **컴파일도 되고 테스트도 통과하며 화면만 미묘하게 다르다.** 그래서
/// 도달 가능한 슬롯을 전부 명시적으로 채운다. `shadcn_select_test.dart` 의
/// `색 슬롯이 하나도 비어 있지 않다` 가 그것을 못박는다.
///
/// ## 채우지 않은 슬롯과 그 근거
///
/// - **`checkbox` 4개** — 단일선택은 체크박스를 그리지 않는다. 패키지에서
///   `checkboxTheme.resolve()` 를 부르는 곳은 `MultiSelectPresentation.buildItem`
///   (`item_presentation.dart:375`) 하나뿐이고 `FlutterMultiSelectDropdown` 전용이다.
/// - **`search` 2개** — `searchable` 을 노출하지 않는다. 검색 필드 자체가
///   `dropdown_menu_shell.dart:593` 의 `if (widget.searchable)` 안에 있다.
/// - **`tooltip` 2개** — 텍스트 모드에서만 도달한다. 아래처럼 **커스텀 모드**를
///   쓰므로 `CustomItemPresentation` 이 되고, 그것은 `tooltipTheme` 을 아예 받지
///   않는다 (`flutter_dropdown_button.dart:481-488`). 텍스트 모드였다면
///   `TooltipMode.onlyWhenOverflow` 가 기본이라 긴 라벨에서 Flutter 기본
///   회색 툴팁(`Colors.grey.shade700`)이 떴을 것이다.
///
/// ## 왜 텍스트 모드가 아니라 커스텀 모드인가
///
/// 텍스트 모드는 글자색을 `TextDropdownConfig` 하나로 받는데, `config.textStyle`
/// 이 **트리거의 선택된 값과 메뉴의 항목 양쪽**에 쓰인다
/// (`item_presentation.dart:162`·`180`). shadcn 은 그 둘이 다른 토큰이다 —
/// 트리거는 `foreground`, 메뉴는 `popover-foreground`. 기본 CSS 에서는 두 값이
/// 같아서 티가 안 나지만, 다른 CSS 를 붙여넣는 순간 갈린다. 커스텀 모드는 각
/// 표면의 `Text` 를 우리가 만들므로 그 문제가 없다.
class ShadcnSelect<T> extends StatelessWidget {
  const ShadcnSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.label,
    this.placeholder,
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final List<ShadcnSelectItem<T>> items;
  final String? label;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final selectedItem = items.cast<ShadcnSelectItem<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => null,
    );
    final handler = onChanged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colors.foreground,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        // 트리거는 예전 구현처럼 **주어진 폭을 채운다.** 패키지는 `width` 도
        // `expand` 도 없으면 내용에 맞춰 줄어드는데(`dropdown_menu_shell.dart:422`
        // 의 `fillsWidth`), `expand: true` 는 `Expanded` 로 감싸는 것이라
        // 이 `Column` 안에서는 세로를 먹는다. 그래서 폭을 직접 읽어 넘긴다.
        LayoutBuilder(
          builder: (context, constraints) {
            return FlutterDropdownButton<ShadcnSelectItem<T>>(
              items: items,
              value: selectedItem,
              enabled: handler != null,
              width: constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : null,
              height: 240.h,
              itemHeight: 36.h,
              // 항목이 하나여도 화살표를 남긴다. 예전 구현이 늘 보여줬고,
              // 사라지면 같은 컨트롤이 항목 수에 따라 다르게 보인다.
              hideIconWhenSingleItem: false,
              onChanged: (item) {
                if (item != null) handler?.call(item.value);
              },
              selectedBuilder: (item) => _faceText(item.label, colors),
              hintWidget: _faceText(placeholder ?? '', colors, hint: true),
              itemBuilder: (item, isSelected) => Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  // shadcn 원본 select.tsx 의 항목이 `focus:bg-accent
                  // focus:text-accent-foreground`. 달력의 선택된 날짜
                  // (`shadcn_calendar.dart:300-301`)와 같은 짝이다.
                  color: isSelected
                      ? colors.accentForeground
                      : colors.popoverForeground,
                ),
              ),
              theme: _theme(colors, radius),
            );
          },
        ),
      ],
    );
  }

  Widget _faceText(String text, TweakcnColors colors, {bool hint = false}) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14.sp,
        color: hint || onChanged == null
            ? colors.mutedForeground
            : colors.foreground,
      ),
    );
  }

  /// 패키지에 넘길 테마. **도달 가능한 색 슬롯이 여기서 전부 채워진다** — 위
  /// 클래스 doc-comment 의 표가 왜인지를 들고 있다.
  DropdownStyleTheme _theme(TweakcnColors colors, TweakcnRadius radius) {
    return DropdownStyleTheme(
      button: DropdownButtonTheme(
        // shadcn 원본이 트리거·팝오버를 `rounded-md` 로 잡는다 (#23 에서 실측).
        borderRadius: radius.md.r,
        backgroundColor: Colors.transparent,
        border: Border.all(color: colors.border),
        disabledBackgroundColor: Colors.transparent,
        disabledBorder: Border.all(color: colors.border),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        height: 20.h,
        hoverColor: colors.accent,
        splashColor: colors.accent,
        highlightColor: colors.accent,
        icon: Icons.unfold_more,
        iconSize: 16.r,
        iconColor: colors.mutedForeground,
        iconDisabledColor: colors.mutedForeground,
        iconPadding: EdgeInsets.only(left: 8.w),
      ),
      overlay: DropdownOverlayTheme(
        borderRadius: radius.md.r,
        backgroundColor: colors.popover,
        border: Border.all(color: colors.border),
        padding: EdgeInsets.all(4.r),
        // **그림자를 그리지 않는다.** 형제 팝오버(`shadcn_date_picker.dart:218-223`)
        // 도 안 그린다. 그리면 색을 정해야 하는데 `tweakcnShadows` 를 읽을지
        // 말지는 #25 가 들고 있는 미결이고, 여기서 정하면 그 티켓을 앞질러
        // 매핑을 하나 발명하는 것이 된다. 비워두면 Material 기본 검정이 들어오므로
        // 명시적으로 끈다.
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      item: DropdownItemTheme(
        // 항목만 `rounded-sm` 이다 (#23 실측).
        borderRadius: radius.sm.r,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        selectedColor: colors.accent,
        hoverColor: colors.accent,
        splashColor: colors.accent,
        highlightColor: colors.accent,
      ),
      scroll: DropdownScrollTheme(
        thumbColor: colors.mutedForeground,
        // 트랙은 그리지 않는다. 색을 함께 채워두는 것은, `trackVisibility` 를
        // null 로 두면 앱 전역 `ScrollbarTheme` 이 켤 수 있어서다 — 명시적으로
        // 끄고, 그래도 켜졌을 때 Material 기본색이 나오지 않게 색도 준다.
        trackVisibility: false,
        trackColor: colors.muted,
        trackBorderColor: colors.border,
        thickness: 6.r,
        radius: Radius.circular(radius.sm.r),
      ),
    );
  }
}

class ShadcnSelectItem<T> {
  final T value;
  final String label;

  const ShadcnSelectItem({required this.value, required this.label});
}
