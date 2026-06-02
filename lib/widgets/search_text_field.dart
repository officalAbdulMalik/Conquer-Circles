import 'package:flutter/material.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

/// A reusable search TextField widget with consistent styling.
///
/// Provides a pre-styled search field with icon, border, and color scheme
/// that matches the app's design system.
class CustomTextFormField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AppTextInput(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      borderRadius: 14,
      fillColor: const Color(0xFFF5F3FF),
    );
  }
}
