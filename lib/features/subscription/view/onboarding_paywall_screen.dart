import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/subscription_provider.dart';
import 'package:test_steps/screens/main_navigation.dart';
import 'package:test_steps/widgets/shared/app_background_image.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

const _freeId = '__free__';

/// Final onboarding step: an upgrade paywall backed by RevenueCat offerings.
/// Closing, choosing Free, or completing a purchase all lead into the app.
class OnboardingPaywallScreen extends ConsumerStatefulWidget {
  const OnboardingPaywallScreen({super.key});

  @override
  ConsumerState<OnboardingPaywallScreen> createState() =>
      _OnboardingPaywallScreenState();
}

class _OnboardingPaywallScreenState
    extends ConsumerState<OnboardingPaywallScreen> {
  String? _selectedId; // null = default (recommended package)
  bool _purchasing = false;

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  Package? _recommended(List<Package> packages) {
    if (packages.isEmpty) return null;
    return packages.firstWhere(
      (p) => p.identifier == 'early' || p.packageType == PackageType.annual,
      orElse: () => packages.first,
    );
  }

  Package? _effectivePackage(List<Package> packages) {
    if (_selectedId == _freeId || packages.isEmpty) return null;
    if (_selectedId == null) return _recommended(packages);
    return packages.firstWhere(
      (p) => p.identifier == _selectedId,
      orElse: () => _recommended(packages)!,
    );
  }

  Future<void> _subscribe(List<Package> packages) async {
    final pkg = _effectivePackage(packages);
    if (pkg == null) {
      _enterApp();
      return;
    }
    setState(() => _purchasing = true);
    final ok = await ref.read(subscriptionProvider.notifier).purchasePackage(pkg);
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (ok) {
      _enterApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase not completed.')),
      );
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final premium =
        await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (premium) {
      _enterApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active subscription found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(subscriptionPackagesProvider);
    final packages = packagesAsync.value ?? const <Package>[];
    final selectedPackage = _effectivePackage(packages);
    final freeSelected = _selectedId == _freeId;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          AppBackgroundImage(
            height: 320.h,
            color: AppColors.surface.withValues(alpha: 0.55),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: _CloseButton(onTap: _enterApp),
                        ),
                        14.verticalSpace,
                        Text(
                          'Unlock Your Full\nTerritory Potential',
                          style: AppTextStyles.montserrat(
                            size: 30.sp,
                            weight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        12.verticalSpace,
                        Text(
                          'Capture more. Compete harder. Dominate your circle.',
                          style: AppTextStyles.montserrat(
                            size: 16.sp,
                            weight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        24.verticalSpace,
                        packagesAsync.when(
                          loading: () => Padding(
                            padding: EdgeInsets.only(top: 40.h),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, __) => _PlansUnavailable(
                            reason: _describeOfferingError(e),
                            onRetry: () =>
                                ref.invalidate(subscriptionPackagesProvider),
                          ),
                          data: (pkgs) {
                            if (pkgs.isEmpty) {
                              return _PlansUnavailable(
                                reason:
                                    'RevenueCat returned no subscription packages. '
                                    'Check that your subscription products are '
                                    'configured in the store and attached to an '
                                    'offering.',
                                onRetry: () => ref
                                    .invalidate(subscriptionPackagesProvider),
                              );
                            }
                            return Column(
                              children: [
                                for (final p in pkgs)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 14.h),
                                    child: _PlanCard(
                                      title: _labelFor(p),
                                      price: p.storeProduct.priceString,
                                      period: _periodFor(p),
                                      badge: (p.identifier == 'early' ||
                                              p.packageType ==
                                                  PackageType.annual)
                                          ? 'Best value'
                                          : null,
                                      showFeatures: true,
                                      selected: !freeSelected &&
                                          selectedPackage?.identifier ==
                                              p.identifier,
                                      onTap: () => setState(
                                        () => _selectedId = p.identifier,
                                      ),
                                    ),
                                  ),
                                _FreeCard(
                                  selected: freeSelected,
                                  onTap: () =>
                                      setState(() => _selectedId = _freeId),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 12.h),
                  child: Column(
                    children: [
                      _SubscribeButton(
                        label: _purchasing
                            ? 'Processing...'
                            : (freeSelected || selectedPackage == null)
                                ? 'Continue with Free'
                                : 'Subscribe to PRO',
                        onTap: _purchasing
                            ? null
                            : () => _subscribe(packages),
                      ),
                      if (packages.isNotEmpty) ...[
                        4.verticalSpace,
                        TextButton(
                          onPressed: _purchasing ? null : _restore,
                          child: Text(
                            'Restore purchases',
                            style: AppTextStyles.montserrat(
                              size: 13.sp,
                              weight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ] else
                        8.verticalSpace,
                      Text(
                        'Cancel anytime · Terms and Condition',
                        style: AppTextStyles.montserrat(
                          size: 12.sp,
                          weight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `conquer_circle_pro` uses custom package identifiers ("early", "monthly")
/// rather than RevenueCat's predefined `$rc_*` ones, so `packageType` comes
/// back as `custom`/`unknown` for them. Recognize those identifiers directly
/// before falling back to the predefined types.
String _labelFor(Package p) {
  switch (p.identifier) {
    case 'early':
      return 'Early Bird';
    case 'monthly':
      return 'Monthly';
  }
  switch (p.packageType) {
    case PackageType.annual:
      return 'Annual';
    case PackageType.sixMonth:
      return '6 Months';
    case PackageType.threeMonth:
      return '3 Months';
    case PackageType.twoMonth:
      return '2 Months';
    case PackageType.monthly:
      return 'Monthly';
    case PackageType.weekly:
      return 'Weekly';
    case PackageType.lifetime:
      return 'Lifetime';
    default:
      final t = p.storeProduct.title;
      return t.isNotEmpty ? t : 'Premium';
  }
}

String _periodFor(Package p) {
  switch (p.packageType) {
    case PackageType.annual:
      return '/yr';
    case PackageType.sixMonth:
      return '/6mo';
    case PackageType.threeMonth:
      return '/3mo';
    case PackageType.twoMonth:
      return '/2mo';
    case PackageType.monthly:
      return '/mo';
    case PackageType.weekly:
      return '/wk';
    default:
      // Custom package type: derive the period from the underlying store
      // product's actual billing period instead of guessing.
      return _periodFromIso(p.storeProduct.subscriptionPeriod) ??
          (p.identifier == 'monthly' ? '/mo' : '');
  }
}

/// Parses an ISO-8601 duration (e.g. "P1Y", "P1M", "P7D") into a short price
/// suffix. Returns null if it can't be parsed.
String? _periodFromIso(String? iso) {
  if (iso == null) return null;
  final match =
      RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$').firstMatch(iso);
  if (match == null) return null;
  final years = int.tryParse(match.group(1) ?? '') ?? 0;
  final months = int.tryParse(match.group(2) ?? '') ?? 0;
  final weeks = int.tryParse(match.group(3) ?? '') ?? 0;
  final days = int.tryParse(match.group(4) ?? '') ?? 0;
  if (years >= 1) return '/yr';
  if (months == 6) return '/6mo';
  if (months == 3) return '/3mo';
  if (months == 2) return '/2mo';
  if (months == 1) return '/mo';
  if (weeks == 1 || days == 7) return '/wk';
  return null;
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderColor),
        ),
        child:
            Icon(Icons.close_rounded, size: 20.r, color: AppColors.textPrimary),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.showFeatures,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final bool showFeatures;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: AppBorders.raised(
            color: selected ? AppColors.blueColor : AppColors.borderColor,
           
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.blueColor.withValues(alpha: selected ? 0.10 : 0.04),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTextStyles.montserrat(
                            size: 22.sp,
                            weight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        8.horizontalSpace,
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueColor,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            badge!,
                            style: AppTextStyles.montserrat(
                              size: 11.sp,
                              weight: FontWeight.w700,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: price,
                    style: AppTextStyles.montserrat(
                      size: 20.sp,
                      weight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: period,
                        style: AppTextStyles.montserrat(
                          size: 13.sp,
                          weight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showFeatures) ...[
              18.verticalSpace,
              _FeatureRow(
                icon: Icons.chat_bubble_rounded,
                iconColor: AppColors.blueColor,
                iconBg: AppColors.lightBlueColor,
                boldText: 'Join 5 ',
                normalText: 'Circle',
              ),
              14.verticalSpace,
              _FeatureRow(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.surface,
                iconBg: AppColors.success,
                boldText: '1,500 ',
                normalText: 'Energy Monthly',
              ),
              14.verticalSpace,
              _FeatureRow(
                icon: Icons.alarm_rounded,
                iconColor: AppColors.blueColor,
                iconBg: AppColors.lightBlueColor,
                boldText: '30min ',
                normalText: 'Extra Cool Down Time',
              ),
              14.verticalSpace,
              _FeatureRow(
                icon: Icons.notifications_rounded,
                iconColor: AppColors.blueColor,
                iconBg: AppColors.lightBlueColor,
                boldText: '',
                normalText: 'Priority Attack Notifications',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: selected ? AppColors.blueColor : AppColors.borderColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free',
                        style: AppTextStyles.montserrat(
                          size: 22.sp,
                          weight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      2.verticalSpace,
                      Text(
                        'Free version',
                        style: AppTextStyles.montserrat(
                          size: 13.sp,
                          weight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$0',
                  style: AppTextStyles.montserrat(
                    size: 22.sp,
                    weight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            _FeatureRow(
              icon: Icons.chat_bubble_rounded,
              iconColor: AppColors.blueColor,
              iconBg: AppColors.lightBlueColor,
              boldText: 'Join 1 ',
              normalText: 'Circle',
            ),
            14.verticalSpace,
            _FeatureRow(
              icon: Icons.lock_rounded,
              iconColor: AppColors.blueColor,
              iconBg: AppColors.lightBlueColor,
              boldText: '',
              normalText: 'Capture & Defend Territories',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansUnavailable extends StatelessWidget {
  const _PlansUnavailable({this.reason, this.onRetry});

  final String? reason;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FreeCard(selected: true, onTap: () {}),
        14.verticalSpace,
        Text(
          'Upgrade plans are unavailable right now. You can continue for free '
          'and upgrade later.',
          textAlign: TextAlign.center,
          style: AppTextStyles.montserrat(
            size: 12.sp,
            weight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        if (onRetry != null) ...[
          8.verticalSpace,
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, size: 16.r),
            label: Text(
              'Try again',
              style: AppTextStyles.montserrat(
                size: 13.sp,
                weight: FontWeight.w600,
                color: AppColors.blueColor,
              ),
            ),
          ),
        ],
        if (kDebugMode && reason != null) ...[
          6.verticalSpace,
          Text(
            reason!,
            textAlign: TextAlign.center,
            style: AppTextStyles.montserrat(
              size: 11.sp,
              weight: FontWeight.w400,
              color: AppColors.error,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

String _describeOfferingError(Object error) {
  if (error is PlatformException) {
    final code = PurchasesErrorHelper.getErrorCode(error);
    return '[$code] ${error.message ?? error.details ?? ''}';
  }
  return error.toString();
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.boldText,
    required this.normalText,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String boldText;
  final String normalText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, size: 17.r, color: iconColor),
        ),
        12.horizontalSpace,
        Expanded(
          child: Text.rich(
            TextSpan(
              text: boldText,
              style: AppTextStyles.montserrat(
                size: 14.sp,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: normalText,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    weight: FontWeight.w400,
                    color: AppColors.textNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: Material(
        color: onTap == null
            ? AppColors.blueColor.withValues(alpha: 0.6)
            : AppColors.blueColor,
        borderRadius: BorderRadius.circular(30.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30.r),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.montserrat(
                size: 16.sp,
                weight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
