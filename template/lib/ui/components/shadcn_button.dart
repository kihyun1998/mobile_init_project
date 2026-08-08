import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';
import 'shadcn_shadow.dart';

enum ShadcnButtonVariant {
  defaultStyle,
  secondary,
  outline,
  ghost,
  destructive,
  link,
}

enum ShadcnButtonSize { defaultSize, sm, lg, icon }

class ShadcnButton extends StatelessWidget {
  const ShadcnButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ShadcnButtonVariant.defaultStyle,
    this.size = ShadcnButtonSize.defaultSize,
    this.isLoading = false,
    this.disabled = false,
    this.width,
    this.height,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ShadcnButtonVariant variant;
  final ShadcnButtonSize size;
  final bool isLoading;
  final bool disabled;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;

    // **`outline` 에만 그림자가 붙는다** — 나머지 다섯 변형에는 shadcn 원본이
    // 아무 그림자도 걸지 않는다 (button.tsx:11-24). `ButtonStyle` 에는
    // `BoxShadow` 를 실을 자리가 없고 `elevation` 은 Material 의 그림자라
    // CSS 레이어와 모양이 다르므로, 버튼 밖에 상자 하나를 두른다. 모서리는
    // 버튼의 `shape` 과 같은 값이라 그림자가 어긋나지 않는다.
    final shadow = variant == ShadcnButtonVariant.outline
        ? context.tweakcnShadows.shadowXs.r
        : const <BoxShadow>[];

    return SizedBox(
      width: width,
      height: height ?? _getButtonHeight(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius.md.r),
          boxShadow: shadow,
        ),
        child: ElevatedButton(
          onPressed: disabled || isLoading ? null : onPressed,
          style: _getButtonStyle(colors, radius),
          child: isLoading
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.r,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getLoadingColor(colors),
                    ),
                  ),
                )
              : child,
        ),
      ),
    );
  }

  double _getButtonHeight() {
    switch (size) {
      case ShadcnButtonSize.sm:
        return 32.h;
      case ShadcnButtonSize.lg:
        return 44.h;
      case ShadcnButtonSize.icon:
        return 36.h;
      case ShadcnButtonSize.defaultSize:
        return 36.h;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ShadcnButtonSize.sm:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h);
      case ShadcnButtonSize.lg:
        return EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h);
      case ShadcnButtonSize.icon:
        return EdgeInsets.all(8.r);
      case ShadcnButtonSize.defaultSize:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
    }
  }

  double _getFontSize() {
    switch (size) {
      case ShadcnButtonSize.sm:
        return 12.sp;
      case ShadcnButtonSize.lg:
        return 16.sp;
      case ShadcnButtonSize.icon:
        return 14.sp;
      case ShadcnButtonSize.defaultSize:
        return 14.sp;
    }
  }

  ButtonStyle _getButtonStyle(TweakcnColors colors, TweakcnRadius radius) {
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;
    double elevation = 0;

    switch (variant) {
      case ShadcnButtonVariant.defaultStyle:
        backgroundColor = colors.primary;
        foregroundColor = colors.primaryForeground;
        break;
      case ShadcnButtonVariant.secondary:
        backgroundColor = colors.muted;
        foregroundColor = colors.mutedForeground;
        break;
      case ShadcnButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        borderColor = colors.border;
        break;
      case ShadcnButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        break;
      case ShadcnButtonVariant.destructive:
        backgroundColor = colors.destructive;
        foregroundColor = Colors.white;
        break;
      case ShadcnButtonVariant.link:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        break;
    }

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(backgroundColor),
      foregroundColor: WidgetStateProperty.all(foregroundColor),
      elevation: WidgetStateProperty.all(elevation),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      padding: WidgetStateProperty.all(_getPadding()),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.md.r),
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 1.r)
              : BorderSide.none,
        ),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: _getFontSize(),
          fontWeight: FontWeight.w500,
          decoration: variant == ShadcnButtonVariant.link
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return _getHoverColor(colors);
        }
        if (states.contains(WidgetState.pressed)) {
          return _getPressedColor(colors);
        }
        return Colors.transparent;
      }),
    );
  }

  Color _getHoverColor(dynamic colors) {
    switch (variant) {
      case ShadcnButtonVariant.defaultStyle:
        return colors.primary.withValues(alpha: 0.9);
      case ShadcnButtonVariant.secondary:
        return colors.muted.withValues(alpha: 0.8);
      case ShadcnButtonVariant.outline:
      case ShadcnButtonVariant.ghost:
        return colors.accent;
      case ShadcnButtonVariant.destructive:
        return colors.destructive.withValues(alpha: 0.9);
      case ShadcnButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color _getPressedColor(dynamic colors) {
    switch (variant) {
      case ShadcnButtonVariant.defaultStyle:
        return colors.primary.withValues(alpha: 0.8);
      case ShadcnButtonVariant.secondary:
        return colors.muted.withValues(alpha: 0.7);
      case ShadcnButtonVariant.outline:
      case ShadcnButtonVariant.ghost:
        return colors.accent.withValues(alpha: 0.8);
      case ShadcnButtonVariant.destructive:
        return colors.destructive.withValues(alpha: 0.8);
      case ShadcnButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color _getLoadingColor(dynamic colors) {
    switch (variant) {
      case ShadcnButtonVariant.defaultStyle:
        return colors.primaryForeground;
      case ShadcnButtonVariant.secondary:
        return colors.mutedForeground;
      case ShadcnButtonVariant.outline:
      case ShadcnButtonVariant.ghost:
      case ShadcnButtonVariant.link:
        return colors.primary;
      case ShadcnButtonVariant.destructive:
        return Colors.white;
    }
  }
}
