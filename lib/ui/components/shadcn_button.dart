import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/provider/theme_provider.dart';

enum ShadcnButtonVariant {
  defaultStyle,
  secondary,
  outline,
  ghost,
  destructive,
  link,
}

enum ShadcnButtonSize {
  defaultSize,
  sm,
  lg,
  icon,
}

class ShadcnButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.theme;
    final colors = ref.color;

    return SizedBox(
      width: width,
      height: height ?? _getButtonHeight(),
      child: ElevatedButton(
        onPressed: disabled || isLoading ? null : onPressed,
        style: _getButtonStyle(colors),
        child: isLoading
            ? SizedBox(
                width: 16.r,
                height: 16.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.r,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_getLoadingColor(colors)),
                ),
              )
            : child,
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
      default:
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
      default:
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
      default:
        return 14.sp;
    }
  }

  ButtonStyle _getButtonStyle(dynamic colors) {
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;
    double elevation = 0;

    switch (variant) {
      case ShadcnButtonVariant.defaultStyle:
        backgroundColor = colors.primary;
        foregroundColor = colors.onPrimary;
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
        backgroundColor = colors.error;
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
          borderRadius: BorderRadius.circular(6.r),
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
        return colors.error.withValues(alpha: 0.9);
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
        return colors.error.withValues(alpha: 0.8);
      case ShadcnButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color _getLoadingColor(dynamic colors) {
    switch (variant) {
      case ShadcnButtonVariant.defaultStyle:
        return colors.onPrimary;
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
