import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/providers/circles_provider.dart';
import 'package:test_steps/widgets/shared/app_button.dart';

class CreateCircleOnboardingView extends ConsumerStatefulWidget {
  const CreateCircleOnboardingView({super.key});

  @override
  ConsumerState<CreateCircleOnboardingView> createState() =>
      _CreateCircleOnboardingViewState();
}

class _CreateCircleOnboardingViewState
    extends ConsumerState<CreateCircleOnboardingView> {
  final PageController _pageController = PageController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _stepIndex = 0;
  bool _isPrivate = true;
  final Set<String> _selectedFriends = <String>{};

  static const List<_FriendData> _friends = <_FriendData>[
    _FriendData(name: 'Ayla', avatarColor: Color(0xFFFFE2D7), avatarLabel: 'A'),
    _FriendData(name: 'Noah', avatarColor: Color(0xFFDFF3FF), avatarLabel: 'N'),
    _FriendData(name: 'Zara', avatarColor: Color(0xFFECE5FF), avatarLabel: 'Z'),
    _FriendData(name: 'Liam', avatarColor: Color(0xFFFFF2D6), avatarLabel: 'L'),
    _FriendData(name: 'Mia', avatarColor: Color(0xFFE2F9EA), avatarLabel: 'M'),
    _FriendData(
      name: 'Ethan',
      avatarColor: Color(0xFFE1EDFF),
      avatarLabel: 'E',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_stepIndex < 2) {
      setState(() {
        _stepIndex += 1;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _createCircle();
  }

  void _previousStep() {
    if (_stepIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _stepIndex -= 1;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _createCircle() async {
    final ownerName = _firstNameController.text.trim();
    if (ownerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name.')),
      );
      return;
    }

    final circleName = ownerName.toLowerCase().endsWith('circle')
        ? ownerName
        : '$ownerName Circle';

    final response = await ref
        .read(circlesProvider.notifier)
        .createCircle(name: circleName, isPrivate: _isPrivate);

    final success = response['success'] == true;
    final message = success
        ? (response['invite_code'] != null
              ? 'Circle created. Invite code: ${response['invite_code']}'
              : 'Circle created successfully.')
        : (response['error']?.toString() ?? 'Failed to create circle');

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(circlesProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFE8FF), Color(0xFFE6F6FF), Color(0xFFF7F3FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _previousStep,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: AppColors.textNavy,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Create Circle',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          2.verticalSpace,
                          Text(
                            '${_stepIndex + 1} / 3',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                10.verticalSpace,
                _ProgressBar(stepIndex: _stepIndex),
                14.verticalSpace,
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(color: const Color(0xFFE6E8F5)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPurple.withValues(alpha: 0.10),
                          blurRadius: 26.r,
                          offset: Offset(0, 12.h),
                        ),
                      ],
                    ),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StepOne(firstNameController: _firstNameController),
                        _StepTwo(
                          searchController: _searchController,
                          selectedFriends: _selectedFriends,
                          onSearchChanged: (_) {
                            setState(() {});
                          },
                          onFriendToggle: (String name) {
                            setState(() {
                              if (_selectedFriends.contains(name)) {
                                _selectedFriends.remove(name);
                              } else {
                                _selectedFriends.add(name);
                              }
                            });
                          },
                        ),
                        _StepThree(
                          isPrivate: _isPrivate,
                          onTypeSelected: (bool privateValue) {
                            setState(() {
                              _isPrivate = privateValue;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                14.verticalSpace,
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _stepIndex == 2 ? 'Create Circle' : 'Continue',
                    onPressed: circlesState.isCreating ? null : _nextStep,
                    isFullWidth: true,
                    height: 50,
                    backgroundColor: AppColors.brandPurple,
                    textStyle: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                if (circlesState.isCreating) ...[
                  8.verticalSpace,
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Creating circle...',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepOne extends StatelessWidget {
  const _StepOne({required this.firstNameController});

  final TextEditingController firstNameController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('First Name & Image', style: AppTextStyles.heading3),
          6.verticalSpace,
          Text(
            'Pick a name and image for your circle leader profile.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          18.verticalSpace,
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 110.r,
                  height: 110.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C67E5), Color(0xFF58D7EB)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPurple.withValues(alpha: 0.18),
                        blurRadius: 18.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 56.sp,
                      color: AppColors.brandPurple,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: -2,
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandPurple,
                      border: Border.all(color: Colors.white, width: 2.w),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          22.verticalSpace,
          Text(
            'First Name',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textNavy,
            ),
          ),
          8.verticalSpace,
          TextField(
            controller: firstNameController,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter your first name',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.fillColor,
              prefixIcon: Icon(
                Icons.badge_outlined,
                size: 20.sp,
                color: AppColors.brandPurple,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: AppColors.brandPurple.withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTwo extends StatelessWidget {
  const _StepTwo({
    required this.searchController,
    required this.selectedFriends,
    required this.onSearchChanged,
    required this.onFriendToggle,
  });

  final TextEditingController searchController;
  final Set<String> selectedFriends;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFriendToggle;

  @override
  Widget build(BuildContext context) {
    final String query = searchController.text.trim().toLowerCase();
    final List<_FriendData> filtered = _CreateCircleOnboardingViewState._friends
        .where((friend) => friend.name.toLowerCase().contains(query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite Friends', style: AppTextStyles.heading3),
        6.verticalSpace,
        Text(
          'Invite your people now. You can always add more later.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        14.verticalSpace,
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search friends',
            hintStyle: AppTextStyles.bodySmall,
            filled: true,
            fillColor: AppColors.fillColor,
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        12.verticalSpace,
        if (selectedFriends.isNotEmpty)
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: selectedFriends.map((String name) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.tabActiveBg,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    4.horizontalSpace,
                    GestureDetector(
                      onTap: () => onFriendToggle(name),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14.sp,
                        color: AppColors.brandPurple,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (selectedFriends.isNotEmpty) 12.verticalSpace,
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => 8.verticalSpace,
            itemBuilder: (context, index) {
              final _FriendData friend = filtered[index];
              final bool selected = selectedFriends.contains(friend.name);
              return InkWell(
                onTap: () => onFriendToggle(friend.name),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.tabActiveBg
                        : AppColors.fillColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: selected
                          ? AppColors.brandPurple.withValues(alpha: 0.45)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38.r,
                        height: 38.r,
                        decoration: BoxDecoration(
                          color: friend.avatarColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            friend.avatarLabel,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandPurple,
                            ),
                          ),
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: Text(
                          friend.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: selected
                            ? AppColors.brandPurple
                            : AppColors.textSecondary,
                        size: 22.sp,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StepThree extends StatelessWidget {
  const _StepThree({required this.isPrivate, required this.onTypeSelected});

  final bool isPrivate;
  final ValueChanged<bool> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Circle Type', style: AppTextStyles.heading3),
        6.verticalSpace,
        Text(
          'Choose who can discover and join your circle.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        18.verticalSpace,
        _TypeCard(
          title: 'Private Circle',
          subtitle: 'Only invited friends can join.',
          icon: Icons.lock_rounded,
          selected: isPrivate,
          onTap: () => onTypeSelected(true),
        ),
        12.verticalSpace,
        _TypeCard(
          title: 'Public Circle',
          subtitle: 'Visible to everyone in circle discovery.',
          icon: Icons.public_rounded,
          selected: !isPrivate,
          onTap: () => onTypeSelected(false),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.fillColor,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18.sp,
                color: AppColors.brandPurple,
              ),
              8.horizontalSpace,
              Expanded(
                child: Text(
                  isPrivate
                      ? 'Private circles are ideal for close teams and friends.'
                      : 'Public circles help you grow fast and discover new players.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.tabActiveBg : AppColors.fillColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected
                ? AppColors.brandPurple.withValues(alpha: 0.55)
                : const Color(0xFFE7E9F4),
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brandPurple.withValues(alpha: 0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: selected
                    ? AppColors.brandPurple
                    : AppColors.textSecondary,
                size: 22.sp,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textNavy,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.brandPurple : AppColors.textSecondary,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(3, (int index) {
        final bool active = index <= stepIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 8.w),
            child: Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: active ? AppColors.brandPurple : const Color(0xFFE5E7F1),
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FriendData {
  const _FriendData({
    required this.name,
    required this.avatarColor,
    required this.avatarLabel,
  });

  final String name;
  final Color avatarColor;
  final String avatarLabel;
}
