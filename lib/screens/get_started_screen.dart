import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/auth/gender_selection_screen.dart';
import 'package:test_steps/features/auth/login_screen.dart';
import 'package:test_steps/features/auth/signup_screen.dart';
import 'package:test_steps/providers/auth_provider.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';
import 'package:test_steps/widgets/shared/social_auth_button.dart';

class GetStartedScreen extends ConsumerStatefulWidget {
  const GetStartedScreen({super.key});

  @override
  ConsumerState<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends ConsumerState<GetStartedScreen> {
  static const _backgroundImages = [
    'assets/images/get_started_runner.png',
    'assets/images/get_started_workout_2.png',
    'assets/images/get_started_workout_3.png',
  ];

  late final PageController _pageController;
  Timer? _slideTimer;
  int _activeSlide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final nextSlide = (_activeSlide + 1) % _backgroundImages.length;
      _pageController.animateToPage(
        nextSlide,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _continueWithGoogle() async {
    await _completeSocialAuth(
      ref.read(authProvider.notifier).continueWithGoogle,
    );
  }

  Future<void> _continueWithApple() async {
    await _completeSocialAuth(
      ref.read(authProvider.notifier).continueWithApple,
    );
  }

  Future<void> _completeSocialAuth(
    Future<AuthActionResult> Function() signIn,
  ) async {
    final result = await signIn();
    if (!mounted) return;

    if (!result.success) {
      _showAuthError(result.error);
      return;
    }
    if (!result.completedSession) return;

    final hasCompletedOnboarding = await ref
        .read(authProvider.notifier)
        .isCurrentProfileOnboardingComplete();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => hasCompletedOnboarding
            ? const MainNavigation()
            : const GenderSelectionScreen(),
      ),
      (route) => false,
    );
  }

  void _showAuthError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Something went wrong.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openSignup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _backgroundImages.length,
              onPageChanged: (index) {
                setState(() => _activeSlide = index);
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _backgroundImages[index],
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.42),
                );
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x22000000),
                    Color(0xCC000000),
                    Color(0xF8000000),
                  ],
                  stops: [0, 0.38, 0.72, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        children: [
                          Text(
                            'Welcome to\nConquer Circles',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.poppins(
                              size: 34.sp,
                              color: AppColors.surface,
                              weight: FontWeight.w800,
                            ),
                          ),
                          8.verticalSpace,
                          Text(
                            'Build your territory & Challenge your friends.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.poppins(
                              size: 18.sp,
                              color: AppColors.surface,
                              weight: FontWeight.w400,
                            ),
                          ),
                          30.verticalSpace,
                          _GetStartedPager(
                            activeIndex: _activeSlide,
                            itemCount: _backgroundImages.length,
                          ),
                          20.verticalSpace,
                          PrimaryButton(
                            label: 'Login with email',
                            onTap: _openLogin,
                          ),
                          16.verticalSpace,
                          SocialAuthButton(
                            label: 'Continue with Google',
                            icon: SvgPicture.asset(
                              'assets/icons/google_icon.svg',
                              width: 20.w,
                              height: 20.w,
                            ),
                            onTap: authState.isSocialAuthLoading
                                ? null
                                : _continueWithGoogle,
                          ),
                          16.verticalSpace,
                          SocialAuthButton(
                            label: 'Continue with Apple',
                            icon: SvgPicture.asset(
                              'assets/icons/apple_icon.svg',
                              width: 21.w,
                              height: 21.w,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                            onTap: authState.isSocialAuthLoading
                                ? null
                                : _continueWithApple,
                          ),
                          16.verticalSpace,
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account ? ",
                                style: AppTextStyles.poppins(
                                  size: 15.sp,
                                  color: AppColors.surface.withValues(
                                    alpha: 0.92,
                                  ),
                                  height: 1.3,
                                ),
                              ),
                              GestureDetector(
                                onTap: _openSignup,
                                child: Text(
                                  'Sign up',
                                  style: AppTextStyles.poppins(
                                    size: 15.sp,
                                    color: AppColors.splashBlue,
                                    weight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GetStartedPager extends StatelessWidget {
  const _GetStartedPager({required this.activeIndex, required this.itemCount});

  final int activeIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(itemCount, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == itemCount - 1 ? 0 : 9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(
                  alpha: index == activeIndex ? 1 : 0.4,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      }),
    );
  }
}
