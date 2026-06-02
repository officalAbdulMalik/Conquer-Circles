import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleJoinRequestsSection extends StatefulWidget {
  const CircleJoinRequestsSection({super.key, required this.requests});

  final List<CircleJoinRequest> requests;

  @override
  State<CircleJoinRequestsSection> createState() =>
      _CircleJoinRequestsSectionState();
}

class _CircleJoinRequestsSectionState extends State<CircleJoinRequestsSection> {
  late List<CircleJoinRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = List<CircleJoinRequest>.from(widget.requests);
  }

  @override
  void didUpdateWidget(CircleJoinRequestsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requests != widget.requests) {
      _requests = List<CircleJoinRequest>.from(widget.requests);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Request',
          style: AppTextStyles.montserrat(
            size: 16.sp,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        12.verticalSpace,
        ...List.generate(_requests.length, (index) {
          final request = _requests[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _requests.length - 1 ? 0 : 12.h,
            ),
            child: CircleJoinRequestTile(
              request: request,
              onAccept: () => _removeRequest(request),
              onDelete: () => _removeRequest(request),
            ),
          );
        }),
      ],
    );
  }

  void _removeRequest(CircleJoinRequest request) {
    setState(() => _requests.removeWhere((item) => item.id == request.id));
  }
}

class CircleJoinRequestTile extends StatelessWidget {
  const CircleJoinRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDelete,
  });

  final CircleJoinRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: AppBorders.raised(),
      ),
      child: Row(
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lightBlueColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Text(
              request.avatar,
              style: AppTextStyles.montserrat(
                size: 27.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.montserrat(
                    size: 14.sp,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                8.verticalSpace,
                Row(
                  children: [
                    CircleJoinRequestButton(
                      label: 'Accept',
                      selected: true,
                      onTap: onAccept,
                    ),
                    6.horizontalSpace,
                    CircleJoinRequestButton(
                      label: 'Delete',
                      selected: false,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CircleJoinRequestButton extends StatelessWidget {
  const CircleJoinRequestButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueColor : AppColors.segmentTrack,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Text(
            label,
            style: AppTextStyles.montserrat(
              size: 13.sp,
              color: selected ? AppColors.surface : AppColors.textSecondary,
              weight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
