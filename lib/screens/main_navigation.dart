import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/profile/view/profile_bottom_sheet.dart';
import 'package:test_steps/features/social/view/browse_cicle.dart';
import 'package:test_steps/features/steps/view/player_energy_screen.dart';
import 'package:test_steps/features/steps/view/steps_view.dart';
import 'package:test_steps/features/map/view/map_view.dart';
import 'package:test_steps/screens/notifications_screen.dart';
import 'package:test_steps/services/dashboard_service.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  static const Color _activeColor = Color(0xFF5169FF);
  static const Color _activeBackground = Color(0xFFDBEAFE);
  static const Color _inactiveColor = Color(0xFF030712);

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Home', iconAsset: 'assets/icons/home.png'),
    _NavItem(label: 'Map', iconAsset: 'assets/icons/map.png'),
    _NavItem(label: 'Circle', iconAsset: 'assets/icons/messages.png'),
    _NavItem(label: 'Shop', iconAsset: 'assets/icons/shop.png'),
    _NavItem(label: 'Profile', iconAsset: 'assets/icons/profile.png'),
  ];

  /// Selected tab — pure view state, ValueNotifier instead of setState.
  late final ValueNotifier<int> _selectedTab = ValueNotifier(
    widget.initialIndex.clamp(0, _navItems.length - 1).toInt(),
  );

  @override
  void dispose() {
    _selectedTab.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _selectedTab.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final screens = [
      const StepsView(),
      const MapView(),
      const AllCirclesPage(),
      PlayerEnergyScreen(energy: dashboardState.attackEnergy),
      const ProfileScreen(),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: _selectedTab,
      builder: (context, selectedIndex, _) =>
          _buildScaffold(context, screens, selectedIndex),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<Widget> screens,
    int _selectedIndex,
  ) {
    return Scaffold(
      appBar:
          (_selectedIndex == 0 ||
              _selectedIndex == 1 ||
              _selectedIndex == 2 ||
              _selectedIndex == 3 ||
              _selectedIndex == 4)
          ? null
          : AppBar(
              toolbarHeight: 60.sp,
              title: Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
                child: (_selectedIndex == 3 || _selectedIndex == 1)
                    ? null
                    : TopGreetingSection(
                        userName: "FitWarrior",
                        subTitle: _selectedIndex == 0
                            ? "Let's crush today's goals"
                            : _selectedIndex == 1
                            ? "Explore the world around you"
                            : _selectedIndex == 2
                            ? "Your squad, your territory"
                            : _selectedIndex == 3
                            ? "Manage your profile and settings"
                            : "Try FitCoach AI",
                        pulseValue: 0,
                        title: _selectedIndex == 0
                            ? "Good morning! 👋"
                            : _selectedIndex == 1
                            ? "Map"
                            : _selectedIndex == 2
                            ? "Circle"
                            : _selectedIndex == 3
                            ? "Profile"
                            : "ChatBoat",
                        trailing: _selectedIndex == 2
                            ? Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationsScreen(),
                                        ),
                                      );
                                    },
                                    child: SvgPicture.asset(
                                      'assets/icons/notification.svg',
                                    ),
                                  ),
                                  10.horizontalSpace,
                                  SvgPicture.asset('assets/icons/persons.svg'),
                                ],
                              )
                            : null,
                      ),
              ),
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // TickerMode pauses each tab's animations (e.g. the map's pulsing
          // marker / smooth movement) while that tab is off-screen, so hidden
          // tabs don't rebuild in the background and slow the whole app.
          for (var i = 0; i < screens.length; i++)
            TickerMode(enabled: _selectedIndex == i, child: screens[i]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 7.h, 8.w, 8.h),
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final selected = _selectedIndex == index;
                final itemColor = selected ? _activeColor : _inactiveColor;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22.r),
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 58.h,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        color: selected
                            ? _activeBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BottomNavIcon(
                            asset: item.iconAsset,
                            color: itemColor,
                          ),
                          3.verticalSpace,
                          Transform.translate(
                            offset: Offset(0, -1.h),
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                                color: itemColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class TopGreetingSection extends StatelessWidget {
  const TopGreetingSection({
    super.key,
    required this.userName,
    required this.pulseValue,
    required this.title,
    required this.subTitle,
    this.trailing,
  });

  final String title;
  final String userName;
  final double pulseValue;
  final String subTitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, style: AppTextStyles.heading2),
              Text(subTitle, maxLines: 1, style: AppTextStyles.bodySmall),
            ],
          ),
        ),

        trailing != null
            ? trailing!
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 40.sp,
                    width: 40.sp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider, width: 1.w),
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  Positioned(
                    right: -3.w,
                    bottom: -2.h,
                    child: Container(
                      width: 20.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white, width: 1.9.w),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${(userName.length % 20) + 1}',
                        style: AppTextStyles.style(
                          fontFamily: 'Poppins',
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;
}

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({required this.asset, required this.color});

  final String asset;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 25.sp;
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return Image.asset(
      asset,
      width: size,
      height: size,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
    );
  }
}
