import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_text_input.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class HomeBaseSetupSheet extends StatelessWidget {
  const HomeBaseSetupSheet({
    super.key,
    required this.onUseCurrentLocation,
    required this.onSetHomeBase,
    this.isLoading = false,
  });

  final VoidCallback onUseCurrentLocation;
  final VoidCallback onSetHomeBase;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.68;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DEE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Image.asset(
                  'assets/images/home_base_back.png',
                  fit: BoxFit.cover,
                  height: 130.sp,
                ),
                16.verticalSpace,
                Text(
                  'Choose Your Home Base',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins(
                    size: 20.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                5.verticalSpace,
                Text(
                  'Choose one real-world location to become\nyour protected headquarters.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 16.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16.h),
                const _HomeBaseBenefitsCard(),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Text(
                      'Location',
                      style: AppTextStyles.montserrat(
                        size: 14.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onUseCurrentLocation,
                      child: Text(
                        'Use Your Current Location',
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.blueColor,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                AppTextInput(
                  enabled: false,
                  hintText: 'Search location or use current one',
                  height: 50,
                  hintStyle: AppTextStyles.montserrat(
                    size: 15.sp,
                    color: const Color(0xffD1D5DB),
                    weight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 24.h),
                PrimaryButton(
                  label: 'Set Home Base',
                  isLoading: isLoading,
                  onTap: onSetHomeBase,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBaseBenefitsCard extends StatelessWidget {
  const _HomeBaseBenefitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: const [
          _BenefitRow(
            icon: 'assets/icons/battery.png',
            iconColor: Color(0xFF1EDB28),
            text: '+50% Energy Gain',
            boldPrefixLength: 4,
          ),
          SizedBox(height: 14),
          _BenefitRow(
            icon: 'assets/icons/lock.png',
            iconColor: Color(0xFF6FA7FF),
            text: 'No Territory Decay Within 300m',
            boldSuffix: '300m',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.boldPrefixLength,
    this.boldSuffix,
  });

  final String icon;
  final Color iconColor;
  final String text;
  final int? boldPrefixLength;
  final String? boldSuffix;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.montserrat(
      size: 14,
      color: AppColors.textPrimary,
      weight: FontWeight.w500,
    );

    return Row(
      children: [
        Image(
          image: AssetImage(icon),
          width: 22.w,
          height: 22.w,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _BenefitText(
            text: text,
            style: style,
            boldPrefixLength: boldPrefixLength,
            boldSuffix: boldSuffix,
          ),
        ),
      ],
    );
  }
}

class _BenefitText extends StatelessWidget {
  const _BenefitText({
    required this.text,
    required this.style,
    this.boldPrefixLength,
    this.boldSuffix,
  });

  final String text;
  final TextStyle style;
  final int? boldPrefixLength;
  final String? boldSuffix;

  @override
  Widget build(BuildContext context) {
    final boldStyle = style.copyWith(fontWeight: FontWeight.w800);

    if (boldPrefixLength != null) {
      final split = boldPrefixLength!;
      return RichText(
        text: TextSpan(
          style: style,
          children: [
            TextSpan(text: text.substring(0, split), style: boldStyle),
            TextSpan(text: text.substring(split)),
          ],
        ),
      );
    }

    if (boldSuffix != null && text.endsWith(boldSuffix!)) {
      final plain = text.substring(0, text.length - boldSuffix!.length);
      return RichText(
        text: TextSpan(
          style: style,
          children: [
            TextSpan(text: plain),
            TextSpan(text: boldSuffix, style: boldStyle),
          ],
        ),
      );
    }

    return Text(text, style: style);
  }
}
