import 'package:flutter/material.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText,
    this.label,
    this.validator,
  });
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool? obscureText;
  final String? label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AppTextInput(
      controller: controller,
      label: label,
      hintText: hintText ?? 'your@email.com',
      prefixIcon:
          prefixIcon ??
          const Icon(Icons.email_outlined, color: Color(0xFFB5B7CC), size: 20),
      suffixIcon: suffixIcon,
      obscureText: obscureText ?? false,
      keyboardType: TextInputType.emailAddress,
      validator: validator,
      borderRadius: 14,
      fillColor: const Color(0xFFF5F3FF),
    );
  }
}
