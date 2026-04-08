import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

/// A reusable search TextField widget with consistent styling.
///
/// Provides a pre-styled search field with icon, border, and color scheme
/// that matches the app's design system.
class CustomTextFormField extends StatefulWidget {
  /// Creates a [CustomTextFormField].
  const CustomTextFormField({
    super.key,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.prefixIcon = Icons.search,
    this.enabled = true,
  });

  /// The hint text to display when the field is empty.
  final String hintText;

  /// Callback when the text field value changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the user submits the text field.
  final ValueChanged<String>? onSubmitted;

  /// Text controller for the field.
  final TextEditingController? controller;

  /// The prefix icon to display.
  final IconData prefixIcon;

  /// Whether the field is enabled.
  final bool enabled;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (isFocused) {
        setState(() => _isFocused = isFocused);
      },
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.poppins(
          size: 14,
          color: AppColors.textNavy,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.poppins(
            size: 13,
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            widget.prefixIcon,
            size: 18.sp,
            color: _isFocused ? AppColors.brandPurple : AppColors.textSecondary,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppColors.surface,
              width: 1.w,
            ),
          ),
          
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppColors.brandPurple.withAlpha(0x80),
              width: 1.w,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppColors.surface.withValues(alpha: 0.5),
              width: 1.w,
            ),
          ),
          filled: true,
          fillColor: AppColors.fillColor,
        ),
      ),
    );
  }
}
