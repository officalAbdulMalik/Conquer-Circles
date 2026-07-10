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

    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.maxHeight.isFinite ? constraints.maxHeight : 92.h;
        final double scale = (height / 92.h).clamp(0.0, 1.0);

        final double indicatorTop = height / 2;
        final double indicatorHeight = height / 2;

        return SizedBox(
          height: height,
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

                  return _MeasureSelectorItem(
                    value: value,
                    selected: selected,
                    scale: scale,
                  );
                },
              ),
              Positioned(
                top: indicatorTop,
                height: indicatorHeight,
                child: Container(
                  width: 3.w,
                  decoration: BoxDecoration(
                    color: AppColors.splashBlue,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MeasureSelectorItem extends StatelessWidget {
  const _MeasureSelectorItem({
    required this.value,
    required this.selected,
    required this.scale,
  });

  final int value;
  final bool selected;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          textAlign: TextAlign.center,
          style: AppTextStyles.montserrat(
            size: 18.sp * scale,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        SizedBox(height: 16.h * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(5, (index) {
            final isMajorTick = index == 2;
            return Container(
              width: 2.w,
              height: (isMajorTick ? 34.h : 24.h) * scale,
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