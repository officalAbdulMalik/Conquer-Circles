import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_steps/features/profile/view/profile_view.dart';
import 'package:test_steps/features/steps/view/steps_view.dart';
import 'package:test_steps/features/map/view/map_view.dart';
import 'package:test_steps/features/social/view/social_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const Color _activeColor = Color(0xFF0D968B);
  static const Color _inactiveColor = Color(0xFF94A3B8);

  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    StepsView(),
    MapView(),
    CirclesScreen(),
    ProfileView(),
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
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
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

class _NavItem {
  const _NavItem({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;
}
