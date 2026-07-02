import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const _otpLength = 6;

  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  Future<void> _verifyOtp() async {
    final result = await ref
        .read(authProvider.notifier)
        .verifySignupOtp(email: widget.email);
    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleOtpChanged(String value, int index) {
    if (value.length > 1) {
      ref.read(authProvider.notifier).fillOtpFromPaste(value);
      _syncControllersWithOtpState();
      return;
    }

    ref.read(authProvider.notifier).setOtpDigit(index, value);
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _syncControllersWithOtpState() {
    final digits = ref.read(authProvider).otpDigits;
    for (var index = 0; index < digits.length; index++) {
      _controllers[index].text = digits[index];
    }
    final nextIndex = digits.join().length.clamp(0, _otpLength - 1);
    _focusNodes[nextIndex].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 260.h,
              color: AppColors.surface.withValues(alpha: 0.7),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppCircularBackButton(),
                  ),
                  178.verticalSpace,
                  Text(
                    'Verify You OTP',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 24.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  28.verticalSpace,
                  Row(
                    children: List.generate(_otpLength, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: _OtpBox(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            onChanged: (value) =>
                                _handleOtpChanged(value, index),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: authState.isOtpVerifying
                        ? 'Verifying...'
                        : 'Verify OTP',
                    isLoading: authState.isOtpVerifying,
                    onTap: authState.isOtpVerifying ? null : _verifyOtp,
                  ),
                  28.verticalSpace,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: AppBorders.raised(),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 6,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: AppTextStyles.montserrat(
          size: 16.sp,
          color: AppColors.textPrimary,
          weight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: '0',
          hintStyle: AppTextStyles.montserrat(
            size: 16.sp,
            color: const Color(0xFFC6CCD7),
            weight: FontWeight.w500,
          ),
          isCollapsed: true,
        ),
      ),
    );
  }
}
