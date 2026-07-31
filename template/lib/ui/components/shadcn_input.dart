import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/tweakcn_theme.g.dart';

class ShadcnInput extends StatelessWidget {
  const ShadcnInput({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: hasError
                  ? colors.destructive
                  : enabled
                  ? colors.border
                  : colors.mutedForeground,
              width: 1.r,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            readOnly: readOnly,
            obscureText: obscureText,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: onTap,
            autofocus: autofocus,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: enabled ? colors.foreground : colors.mutedForeground,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: colors.mutedForeground,
              ),
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(left: 12.w, right: 8.w),
                      child: prefixIcon,
                    )
                  : null,
              prefixIconConstraints: BoxConstraints(
                minWidth: 20.r,
                minHeight: 20.r,
              ),
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(left: 8.w, right: 12.w),
                      child: suffixIcon,
                    )
                  : null,
              suffixIconConstraints: BoxConstraints(
                minWidth: 20.r,
                minHeight: 20.r,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        if (helperText != null || hasError) ...[
          SizedBox(height: 4.h),
          Text(
            hasError ? errorText! : helperText!,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: hasError ? colors.destructive : colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}

class ShadcnTextArea extends StatelessWidget {
  const ShadcnTextArea({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return ShadcnInput(
      controller: controller,
      placeholder: placeholder,
      label: label,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      focusNode: focusNode,
    );
  }
}
