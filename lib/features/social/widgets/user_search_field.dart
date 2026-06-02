import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';

class UserSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const UserSearchField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: AppTextInput(
        controller: controller,
        onChanged: onChanged,
        hintText: 'Search by username',
        borderRadius: 16,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: Icon(Icons.search, size: 20.sp),
      ),
    );
  }
}
