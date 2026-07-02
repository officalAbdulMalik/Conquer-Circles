import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleIconPicker extends StatelessWidget {
  const CircleIconPicker({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<String> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26.r),
        border: AppBorders.raised(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const itemsPerRow = 5;
                final spacing = 10.w;
                final tileWidth =
                    (constraints.maxWidth - spacing * (itemsPerRow - 1)) /
                    itemsPerRow;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: 10.h,
                    children: options
                        .map(
                          (option) => SizedBox(
                            width: tileWidth,
                            child: CircleIconPickerTile(
                              option: option,
                              selected: option == selectedId,
                              onTap: () => onSelected(option),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 8.h, color: const Color(0xFFE3E7EF)),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 180.w,
              height: 8.h,
              color: AppColors.blueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class CircleIconPickerTile extends StatelessWidget {
  const CircleIconPickerTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final String option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lightBlueColor : Colors.white,
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: onTap,
        child: Container(
          height: 56.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: selected ? AppColors.blueColor : AppColors.borderColor,
              width: selected ? 2.w : 1.w,
            ),
          ),
          child: SizedBox.square(
            dimension: 34.sp,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Image.network(
                option,
                width: 34.sp,
                height: 34.sp,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_outlined,
                  size: 24.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
