import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/steps/widgets/pack_info_dailog.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';
import 'package:test_steps/widgets/shared/custom_app_dialog.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

class PlayerEnergyScreen extends StatefulWidget {
  const PlayerEnergyScreen({
    super.key,
    required this.energy,
    this.showBackButton = true,
  });

  final int energy;
  final bool showBackButton;

  @override
  State<PlayerEnergyScreen> createState() => _PlayerEnergyScreenState();
}

class _PlayerEnergyScreenState extends State<PlayerEnergyScreen> {
  /// Selected tab — ValueNotifier so switching rebuilds only the tab bar
  /// and grid, never the header/energy card.
  final ValueNotifier<int> _selectedTab = ValueNotifier(1);

  @override
  void dispose() {
    _selectedTab.dispose();
    super.dispose();
  }

  static const _packages = [
    _EnergyPackage(energy: 10, price: 'Rs 100', icons: 1),
    _EnergyPackage(energy: 50, price: 'Rs 280', icons: 2),
    _EnergyPackage(energy: 100, price: 'Rs 550', icons: 3),
    _EnergyPackage(energy: 200, price: 'Rs 1,100', icons: 4),
    _EnergyPackage(energy: 300, price: 'Rs 1,600', icons: 6),
    _EnergyPackage(energy: 400, price: 'Rs 2,100', icons: 6),
  ];

  static const _packs = [
    _ShopPack(name: '+1 Additional Circle', energyCost: 250),
    _ShopPack(name: 'Defense Shield', energyCost: 300),
    _ShopPack(name: 'Speed Boost', energyCost: 350),
    _ShopPack(name: 'Territory Lock', energyCost: 400),
    _ShopPack(name: 'Double XP', energyCost: 500),
    _ShopPack(name: 'Attack Surge', energyCost: 450),
  ];

  @override
  Widget build(BuildContext context) {
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
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 26.h),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 38.h,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (widget.showBackButton)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: AppCircularBackButton(size: 36),
                                ),
                              Text(
                                'Available Energy',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.montserrat(
                                  size: 18.sp,
                                  color: AppColors.textPrimary,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        22.verticalSpace,
                        _AvailableEnergyCard(energy: widget.energy),
                        26.verticalSpace,
                        ValueListenableBuilder<int>(
                          valueListenable: _selectedTab,
                          builder: (context, selectedTab, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _EnergyTabBar(
                                selectedIndex: selectedTab,
                                onChanged: (index) =>
                                    _selectedTab.value = index,
                              ),
                              24.verticalSpace,
                              if (selectedTab == 0)
                                _EnergyMarketplaceGrid(packages: _packages)
                              else
                                _PacksGrid(packs: _packs),
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
        ],
      ),
    );
  }
}

class _AvailableEnergyCard extends StatelessWidget {
  const _AvailableEnergyCard({required this.energy});

  final int energy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDDEBFF),
        borderRadius: BorderRadius.circular(28.r),
        border: AppBorders.raised(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: CustomPaint(
          painter: _EnergyRayPainter(
            color: AppColors.splashBlue.withValues(alpha: 0.08),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/battery.png',
                width: 42.w,
                height: 42.w,
              ),
              10.verticalSpace,
              Text(
                '$energy',
                style: AppTextStyles.montserrat(
                  size: 30.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              8.verticalSpace,
              Text(
                'Available Energy',
                style: AppTextStyles.montserrat(
                  size: 15.sp,
                  color: AppColors.textPrimary,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnergyTabBar extends StatelessWidget {
  const _EnergyTabBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Marketplace', 'Packs'];

    return Column(
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final selected = selectedIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.montserrat(
                      size: 14.sp,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Stack(
          children: [
            Container(height: 1.h, color: AppColors.borderColor),
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: selectedIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: 0.5.sw - 24.w,
                height: 2.h,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Marketplace ─────────────────────────────────────────────────────────────

class _EnergyMarketplaceGrid extends StatelessWidget {
  const _EnergyMarketplaceGrid({required this.packages});

  final List<_EnergyPackage> packages;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packages.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18.w,
        mainAxisSpacing: 16.h,
        mainAxisExtent: 130.h,
      ),
      itemBuilder: (context, index) {
        return _EnergyPackageCard(package: packages[index]);
      },
    );
  }
}

class _EnergyPackageCard extends StatelessWidget {
  const _EnergyPackageCard({required this.package});

  final _EnergyPackage package;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDEBFF),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFB9D7FF), width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A0F172A),
            blurRadius: 0,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: CustomPaint(
          painter: _EnergyRayPainter(
            color: AppColors.splashBlue.withValues(alpha: 0.08),
            originY: 0.98,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: _EnergyIconRow(count: package.icons)),
                const Spacer(),
                Text(
                  '${package.energy}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.montserrat(
                    size: 17.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 36.h,
                  child: PrimaryButton(
                    verticalPadding: 6.h,
                    label: package.price,
                    onTap: () {},
                    textStyle: AppTextStyles.montserrat(
                      size: 14.sp,
                      color: AppColors.surface,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnergyIconRow extends StatelessWidget {
  const _EnergyIconRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: math.max(32.w, 18.w * (count - 1) + 32.w),
      height: 32.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (index) {
          return Positioned(
            left: index * 17.w,
            child: Image.asset(
              'assets/icons/battery.png',
              width: 32.w,
              height: 32.w,
            ),
          );
        }),
      ),
    );
  }
}

// ─── Packs ───────────────────────────────────────────────────────────────────

class _PacksGrid extends StatelessWidget {
  const _PacksGrid({required this.packs});

  final List<_ShopPack> packs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        mainAxisExtent: 220.h,
      ),
      itemBuilder: (context, index) {
        return _PackCard(pack: packs[index]);
      },
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack});

  final _ShopPack pack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderColor, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    4.horizontalSpace,
                    Text(
                      'Detail',
                      style: AppTextStyles.montserrat(
                        size: 12.sp,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.borderColor, width: 1.w),
              ),
              child: Center(
                child: Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E9FF),

                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Image.asset(
                      'assets/icons/power.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
            12.verticalSpace,
            Text(
              pack.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.montserrat(
                size: 14.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w400,
              ),
            ),
            8.verticalSpace,
            Row(
              children: [
                _OverlappingEnergyIcons(),
                8.horizontalSpace,
                Text(
                  '${pack.energyCost}',
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            10.verticalSpace,
            SizedBox(
              width: double.infinity,
              height: 36.h,
              child: PrimaryButton(
                verticalPadding: 6.h,
                label: 'Buy',
                onTap: () {
                  showCustomAppDialog<void>(
                    context: context,
                    dialog:PackInfoDialog(),
                  );
                },
                textStyle: AppTextStyles.montserrat(
                  size: 14.sp,
                  color: AppColors.surface,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlappingEnergyIcons extends StatelessWidget {
  const _OverlappingEnergyIcons();

  @override
  Widget build(BuildContext context) {
    const count = 2;
    const iconSize = 22.0;
    const overlap = 12.0;

    return SizedBox(
      width: iconSize + overlap * (count - 1),
      height: iconSize,
      child: Stack(
        children: List.generate(count, (index) {
          return Positioned(
            left: index * overlap,
            child: Image.asset(
              'assets/icons/battery.png',
              width: 22.sp,
              height: 22.sp,
            ),
          );
        }),
      ),
    );
  }
}

// ─── Painters & Models ───────────────────────────────────────────────────────

class _EnergyRayPainter extends CustomPainter {
  const _EnergyRayPainter({required this.color, this.originY = 0.0});

  final Color color;
  final double originY;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final origin = Offset(size.width / 2, size.height * originY);

    for (var index = 0; index < 34; index++) {
      final angle = (-math.pi * 0.9) + (index * math.pi * 1.8 / 33);
      final nextAngle = angle + 0.03;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(
          origin.dx + math.cos(angle) * size.width,
          origin.dy + math.sin(angle) * size.height,
        )
        ..lineTo(
          origin.dx + math.cos(nextAngle) * size.width,
          origin.dy + math.sin(nextAngle) * size.height,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyRayPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.originY != originY;
  }
}

class _EnergyPackage {
  const _EnergyPackage({
    required this.energy,
    required this.price,
    required this.icons,
  });

  final int energy;
  final String price;
  final int icons;
}

class _ShopPack {
  const _ShopPack({required this.name, required this.energyCost});

  final String name;
  final int energyCost;
}
