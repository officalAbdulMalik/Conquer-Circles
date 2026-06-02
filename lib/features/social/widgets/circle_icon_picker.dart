import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleIconOption {
  const CircleIconOption({required this.id, required this.asset});

  final String id;
  final String asset;
}

class CircleIconPicker extends StatelessWidget {
  const CircleIconPicker({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CircleIconOption> options;
  final String selectedId;
  final ValueChanged<CircleIconOption> onSelected;

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Wrap(
                  
                    children: _buildRowItems(options.take(5).toList()),
                  ),
                  10.verticalSpace,
                   Wrap(
                  
                    children: _buildRowItems(options.take(5).toList()),
                  ),
                  
                ],
              ),
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

  List<Widget> _buildRowItems(List<CircleIconOption> rowOptions) {
    return rowOptions
        .map(
          (option) => Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: CircleIconPickerTile(
              option: option,
              selected: option.id == selectedId,
              onTap: () => onSelected(option),
            ),
          ),
        )
        .toList();
  }
}

class CircleIconPickerTile extends StatelessWidget {
  const CircleIconPickerTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CircleIconOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        color: Colors.white,
        border: Border.all(color: AppColors.borderColor),
      ),
    
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: onTap,
        child: Image.asset(
          option.asset,
          width: 26.sp,
          height: 26.sp,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
