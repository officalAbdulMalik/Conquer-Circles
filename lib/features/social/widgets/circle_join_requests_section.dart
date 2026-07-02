import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleJoinRequestsSection extends StatelessWidget {
  const CircleJoinRequestsSection({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onDelete,
    this.respondingRequestIds = const {},
  });

  final List<CircleJoinRequest> requests;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onDelete;
  final Set<String> respondingRequestIds;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
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
        ...List.generate(requests.length, (index) {
          final request = requests[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == requests.length - 1 ? 0 : 12.h,
            ),
            child: CircleJoinRequestTile(
              request: request,
              isLoading: respondingRequestIds.contains(request.id),
              onAccept: () => onAccept(request.id),
              onDelete: () => onDelete(request.id),
            ),
          );
        }),
      ],
    );
  }
}

class CircleJoinRequestTile extends StatelessWidget {
  const CircleJoinRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDelete,
    this.isLoading = false,
  });

  final CircleJoinRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDelete;
  final bool isLoading;

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
            clipBehavior: Clip.antiAlias,
            child: request.avatarUrl != null
                ? Image.network(
                    request.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _avatarFallback(request.avatar),
                  )
                : _avatarFallback(request.avatar),
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
                      label: isLoading ? 'Wait' : 'Accept',
                      selected: true,
                      onTap: isLoading ? null : onAccept,
                    ),
                    6.horizontalSpace,
                    CircleJoinRequestButton(
                      label: 'Delete',
                      selected: false,
                      onTap: isLoading ? null : onDelete,
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

  Widget _avatarFallback(String avatar) {
    return Center(
      child: Text(
        avatar,
        style: AppTextStyles.montserrat(
          size: 27.sp,
          color: AppColors.textPrimary,
        ),
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
  final VoidCallback? onTap;

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
