import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class AppTextInput extends StatelessWidget {
  const AppTextInput({
    super.key,
    this.controller,
    this.hintText,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.height = 46,
    this.borderRadius = 18,
    this.fillColor = Colors.white,
    this.border,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.prefixIconColor,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? label;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final double? height;
  final double borderRadius;
  final Color fillColor;
  final Border? border;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? prefixIconColor;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller?.text ?? '',
      validator: validator,
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        final field = Container(
          height: height?.h,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(borderRadius.r),
            border:
                border ??
                AppBorders.raised(
                  color: hasError ? AppColors.error : AppColors.borderColor,
                ),
          ),
          child: Center(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              readOnly: readOnly,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              textCapitalization: textCapitalization,
              maxLines: maxLines,
              onChanged: (value) {
                fieldState.didChange(value);
                onChanged?.call(value);
              },
              onFieldSubmitted: onSubmitted,
              onTap: onTap,
              textAlignVertical: TextAlignVertical.center,
              style:
                  textStyle ??
                  AppTextStyles.montserrat(
                    size: 14,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w500,
                  ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: hintText,
                hintStyle:
                    hintStyle ??
                    AppTextStyles.montserrat(
                      size: 14,
                      color: const Color(0xFFC6CCD7),
                      weight: FontWeight.w500,
                    ),
                prefixIcon: prefixIcon,
                prefixIconColor: prefixIconColor ?? const Color(0xFFCBD5E1),
                prefixIconConstraints: BoxConstraints(
                  minWidth: prefixIcon == null ? 0 : 44.w,
                  minHeight: height == null ? 0 : height!.h,
                ),
                suffixIcon: suffixIcon,
                suffixIconConstraints: BoxConstraints(
                  minWidth: suffixIcon == null ? 0 : 44.w,
                  minHeight: height == null ? 0 : height!.h,
                ),
                isDense: true,
                isCollapsed: true,
                contentPadding:
                    contentPadding ??
                    EdgeInsets.symmetric(
                      horizontal: prefixIcon == null ? 15.w : 0,
                      vertical: 0,
                    ),
              ),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null && label!.isNotEmpty) ...[
              Text(
                label!,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              8.verticalSpace,
            ],
            field,
            if (hasError) ...[
              8.verticalSpace,
              Text(
                fieldState.errorText!,
                style: AppTextStyles.montserrat(
                  size: 12,
                  color: AppColors.error,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
