import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

class ScrollableMeasureSelector extends StatefulWidget {
  const ScrollableMeasureSelector({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.selectedValue,
    required this.onChanged,
    this.viewportFraction = 0.18,
  });

  final int minValue;
  final int maxValue;
  final int selectedValue;
  final ValueChanged<int> onChanged;
  final double viewportFraction;

  @override
  State<ScrollableMeasureSelector> createState() =>
      _ScrollableMeasureSelectorState();
}

class _ScrollableMeasureSelectorState extends State<ScrollableMeasureSelector> {
  late final PageController _controller;

  int get _selectedPage => (widget.selectedValue - widget.minValue).clamp(
    0,
    widget.maxValue - widget.minValue,
  );

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _selectedPage,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant ScrollableMeasureSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue == widget.selectedValue ||
        !_controller.hasClients) {
      return;
    }

    final currentPage = _controller.page?.round();
    if (currentPage == _selectedPage) {
      return;
    }

    _controller.animateToPage(
      _selectedPage,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.maxValue - widget.minValue + 1;

    return SizedBox(
      height: 88.h,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: itemCount,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => widget.onChanged(widget.minValue + index),
            itemBuilder: (context, index) {
              final value = widget.minValue + index;
              final selected = value == widget.selectedValue;

              return _MeasureSelectorItem(value: value, selected: selected);
            },
          ),
          Positioned(
            top: 46.h,
            child: Container(
              width: 3.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.splashBlue,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasureSelectorItem extends StatelessWidget {
  const _MeasureSelectorItem({required this.value, required this.selected});

  final int value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          textAlign: TextAlign.center,
          style: AppTextStyles.montserrat(
            size: 18.sp,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        16.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(5, (index) {
            final isMajorTick = index == 2;
            return Container(
              width: 2.w,
              height: isMajorTick ? 34.h : 24.h,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        ),
      ],
    );
  }
}
