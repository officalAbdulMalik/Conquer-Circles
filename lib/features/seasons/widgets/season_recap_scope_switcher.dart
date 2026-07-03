import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class SeasonRecapScopeSwitcher extends StatefulWidget {
  const SeasonRecapScopeSwitcher({
    super.key,
    this.initialAllTime = true,
    required this.onChanged,
  });

  final bool initialAllTime;
  final ValueChanged<bool> onChanged;

  @override
  State<SeasonRecapScopeSwitcher> createState() =>
      _SeasonRecapScopeSwitcherState();
}

class _SeasonRecapScopeSwitcherState extends State<SeasonRecapScopeSwitcher> {
  /// Toggle state — ValueNotifier so switching scope rebuilds only the pills.
  late final ValueNotifier<bool> _isAllTime = ValueNotifier(
    widget.initialAllTime,
  );

  @override
  void dispose() {
    _isAllTime.dispose();
    super.dispose();
  }

  void _select(bool allTime) {
    if (_isAllTime.value == allTime) return;
    _isAllTime.value = allTime;
    widget.onChanged(allTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isAllTime,
        builder: (context, isAllTime, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScopePill(
              label: 'All Time',
              selected: isAllTime,
              onTap: () => _select(true),
            ),
            _ScopePill(
              label: 'Season',
              selected: !isAllTime,
              onTap: () => _select(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopePill extends StatelessWidget {
  const _ScopePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Text(
          label,
          style: AppTextStyles.inter(
            size: 11,
            color: selected ? AppColors.surface : AppColors.textSecondary,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
