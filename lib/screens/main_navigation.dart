import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/chatbot/view/chat_view.dart';
import 'package:test_steps/features/profile/view/profile_view.dart';
import 'package:test_steps/features/social/view/browse_cicle.dart';
import 'package:test_steps/features/steps/view/steps_view.dart';
import 'package:test_steps/features/map/view/map_view.dart';
import 'package:test_steps/screens/notifications_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const Color _activeColor = Color(0xFF0D968B);
  static const Color _inactiveColor = Color(0xFF94A3B8);

  late int _selectedIndex;

  final List<Widget> _screens = const [
    StepsView(),
    MapView(),
    AllCirclesPage(),
    ProfileView(),
    ChatView(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      label: 'Home',
      iconAsset: 'assets/icons/dashboard_nav_home_icon.svg',
    ),
    _NavItem(
      label: 'Map',
      iconAsset: 'assets/icons/dashboard_nav_map_icon.svg',
    ),
    _NavItem(
      label: 'Social',
      iconAsset: 'assets/icons/dashboard_nav_circles_icon.svg',
    ),
    _NavItem(
      label: 'Profile',
      iconAsset: 'assets/icons/dashboard_nav_profile_icon.svg',
    ),
    _NavItem(
      label: 'Chat',
      iconAsset: 'assets/icons/dashboard_nav_profile_icon.svg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1).toInt();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_selectedIndex == 1 || _selectedIndex == 3)
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
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.tileNeutral)),
          boxShadow: [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final selected = _selectedIndex == index;
                final itemColor = selected ? _activeColor : _inactiveColor;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _onItemTapped(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2,
                            width: 24,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _activeColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          SvgPicture.asset(
                            item.iconAsset,
                            width: 19,
                            height: 19,
                            colorFilter: ColorFilter.mode(
                              itemColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: 0.3,
                              color: itemColor,
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
