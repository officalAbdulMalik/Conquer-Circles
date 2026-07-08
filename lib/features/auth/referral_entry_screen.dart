import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/subscription/view/onboarding_paywall_screen.dart';
import 'package:test_steps/services/supabase_service.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

/// Final, optional onboarding step: lets a new user apply someone's referral
/// code if they didn't enter one at signup. The referrer earns +10 energy.
class ReferralEntryScreen extends StatefulWidget {
  const ReferralEntryScreen({super.key});

  @override
  State<ReferralEntryScreen> createState() => _ReferralEntryScreenState();
}

class _ReferralEntryScreenState extends State<ReferralEntryScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _goToApp() {
    // Final onboarding step after referral: the upgrade paywall.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingPaywallScreen()),
      (route) => false,
    );
  }

  Future<void> _apply() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _goToApp();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final result = await SupabaseService().redeemReferralCode(code);
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral code applied. Thanks!'),
            backgroundColor: Color(0xFF22C9A5),
          ),
        );
        _goToApp();
        return;
      }
      setState(() {
        _isSubmitting = false;
        _error = result['error']?.toString() ?? 'Invalid referral code';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackgroundImage(
            height: 260.h,
            color: AppColors.surface.withValues(alpha: 0.7),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  40.verticalSpace,
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 56.r,
                    color: AppColors.blueColor,
                  ),
                  20.verticalSpace,
                  Text(
                    'Got a referral code?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 24.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  12.verticalSpace,
                  Text(
                    'Enter a friend’s code and they’ll earn +10 energy. '
                    'You can skip this if you don’t have one.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 14.sp,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  32.verticalSpace,
                  AppTextInput(
                    controller: _codeController,
                    hintText: 'Referral code',
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    borderRadius: 20,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  if (_error != null) ...[
                    8.verticalSpace,
                    Text(
                      _error!,
                      style: AppTextStyles.montserrat(
                        size: 12.sp,
                        color: AppColors.error,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  PrimaryButton(
                    label: _isSubmitting ? 'Applying...' : 'Apply & Continue',
                    isLoading: _isSubmitting,
                    onTap: _isSubmitting ? null : _apply,
                    verticalPadding: 15.h,
                  ),
                  12.verticalSpace,
                  TextButton(
                    onPressed: _isSubmitting ? null : _goToApp,
                    child: Text(
                      'Skip for now',
                      style: AppTextStyles.montserrat(
                        size: 14.sp,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  20.verticalSpace,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
