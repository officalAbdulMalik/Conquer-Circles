import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_avatar_stack.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/primary_button.dart';

enum CircleCardAction { request, join, full }

enum CircleCardStatus { active, private, full, joined, requested }

class CircleCardTileData {
  const CircleCardTileData({
    required this.id,
    required this.name,
    required this.icon,
    this.iconUrl,
    required this.iconBackground,
    required this.territory,
    required this.membersLabel,
    required this.memberNames,
    required this.memberAvatarUrls,
    required this.rank,
    required this.status,
    required this.action,
  });

  final String id;
  final String name;
  final String icon;
  final String? iconUrl;
  final Color iconBackground;
  final String territory;
  final String membersLabel;
  final List<String> memberNames;
  final List<String?> memberAvatarUrls;
  final int rank;
  final CircleCardStatus status;
  final CircleCardAction action;
}

class CircleCardTile extends StatelessWidget {
  const CircleCardTile({
    super.key,
    required this.data,
    this.onTap,
    this.onRequestJoin,
    this.isRequesting = false,
  });

  final CircleCardTileData data;
  final VoidCallback? onTap;
  final VoidCallback? onRequestJoin;
  final bool isRequesting;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: AppBorders.raised(),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: AppColors.blueContiner,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: data.iconUrl != null
                        ? Image.network(
                            data.iconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _iconFallback(data.icon),
                          )
                        : _iconFallback(data.icon),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.montserrat(
                                  size: 17.sp,
                                  color: AppColors.textPrimary,
                                  weight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                              7.verticalSpace,
                              Text(
                                data.territory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.montserrat(
                                  size: 14.sp,
                                  color: AppColors.textSecondary,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 15.sp,
                                  color: AppColors.blueColor,
                                ),
                                4.horizontalSpace,
                                Text(
                                  '#${data.rank}',
                                  style: AppTextStyles.montserrat(
                                    size: 13.sp,
                                    color: AppColors.blueColor,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              10.verticalSpace,
              Row(
                children: [
                  AppAvatarStack(
                    emojis: List.filled(data.memberNames.take(4).length, '👤'),
                    imageUrls: data.memberAvatarUrls.take(4).toList(),
                    labels: data.memberNames.take(4).toList(),
                    size: 30,
                    overlap: 18,
                    backgroundColor: AppColors.surface,
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: Text(
                      data.membersLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.montserrat(
                        size: 12.sp,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                  CircleStatusPill(status: data.status),
                ],
              ),
              if (data.action == CircleCardAction.join) ...[
                12.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: PrimaryButton(
                    width: 150.w,
                    textStyle: AppTextStyles.buttonLabel.copyWith(
                      fontSize: 14.sp,
                    ),
                    label: 'Request to Join',
                    isLoading: isRequesting,
                    onTap: onRequestJoin,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFallback(String icon) {
    return Center(
      child: Text(icon, style: TextStyle(fontSize: 28.sp)),
    );
  }
}

class CircleStatusPill extends StatelessWidget {
  const CircleStatusPill({super.key, required this.status});

  final CircleCardStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      CircleCardStatus.active => (
        const Color(0xFFC9F7EC),
        const Color(0xFF10B981),
      ),
      CircleCardStatus.private => (
        const Color(0xFFE4E9F0),
        const Color(0xFF7B8494),
      ),
      CircleCardStatus.full => (
        const Color(0xFFFFF5C8),
        const Color(0xFFFF9B53),
      ),
      CircleCardStatus.joined => (const Color(0xFFE0EAFF), AppColors.blueColor),
      CircleCardStatus.requested => (
        const Color(0xFFFFF4D8),
        const Color(0xFFB7791F),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.montserrat(
          size: 13.sp,
          color: colors.$2,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

extension CircleCardStatusLabel on CircleCardStatus {
  String get label {
    return switch (this) {
      CircleCardStatus.active => 'Active',
      CircleCardStatus.private => 'Private',
      CircleCardStatus.full => 'Full',
      CircleCardStatus.joined => 'Joined',
      CircleCardStatus.requested => 'Requested',
    };
  }
}
