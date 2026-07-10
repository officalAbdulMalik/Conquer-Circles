import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/features/social/models/circle_detail_models.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

class CircleMetricsRow extends StatelessWidget {
  const CircleMetricsRow({
    super.key,
    required this.metrics,
    required this.circleName,
    required this.members,
    this.canRemoveMembers = false,
    this.removingMemberIds = const {},
    this.onRemoveMember,
  });

  final List<CircleDetailMetric> metrics;
  final String circleName;
  final List<CircleLeaderboardMember> members;
  final bool canRemoveMembers;
  final Set<String> removingMemberIds;
  final Future<Map<String, dynamic>> Function(String memberId)? onRemoveMember;

  Future<bool> _confirmMemberRemoval(
    BuildContext context,
    CircleLeaderboardMember member,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _RemoveMemberDialog(
            memberName: member.name,
            circleName: circleName,
          ),
        ) ??
        false;
  }

  void _showMemberDialog(BuildContext context) {
    final territory = metrics
        .where((metric) => metric.label == 'Territory')
        .firstOrNull;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final hiddenMemberIds = <String>{};
        final locallyRemovingIds = <String>{};
        return StatefulBuilder(
          builder: (context, setSheetState) => Container(
            constraints: BoxConstraints(maxHeight: 700.h),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 49.w,
                      height: 5.h,
                      margin: EdgeInsets.only(bottom: 14.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9DCE4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: AppBorders.raised(),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.blueContiner,
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/battery.png',
                              width: 38.w,
                              height: 38.w,
                            ),
                          ),
                        ),
                        12.verticalSpace,
                        Text(
                          circleName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.montserrat(
                            size: 16.sp,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                        6.verticalSpace,
                        Text(
                          '${territory?.value ?? '0 km²'} Territory · '
                          '${members.length - hiddenMemberIds.length} Members',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.montserrat(
                            size: 12.sp,
                            color: AppColors.textSecondary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  14.verticalSpace,
                  Text(
                    '${members.length - hiddenMemberIds.length} '
                    '${members.length - hiddenMemberIds.length == 1 ? 'member' : 'members'}',
                    style: AppTextStyles.montserrat(
                      size: 14.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  12.verticalSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: AppBorders.raised(),
                    ),
                    child: Column(
                      children: List.generate(
                        members
                            .where(
                              (member) =>
                                  !hiddenMemberIds.contains(member.userId),
                            )
                            .length,
                        (index) {
                          final visibleMembers = members
                              .where(
                                (member) =>
                                    !hiddenMemberIds.contains(member.userId),
                              )
                              .toList();
                          final member = visibleMembers[index];
                          final role = member.role?.toLowerCase();
                          final canRemove =
                              canRemoveMembers &&
                              member.userId.isNotEmpty &&
                              role != 'owner' &&
                              role != 'admin';
                          final isRemoving =
                              locallyRemovingIds.contains(member.userId) ||
                              removingMemberIds.contains(member.userId);
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  12.w,
                                  12.h,
                                  12.w,
                                  12.h,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56.w,
                                      height: 56.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.borderColor,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: member.avatarUrl != null
                                          ? Image.network(
                                              member.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _avatarFallback(
                                                    member.avatar,
                                                  ),
                                            )
                                          : _avatarFallback(member.avatar),
                                    ),
                                    14.horizontalSpace,
                                    Expanded(
                                      child: Text(
                                        member.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.montserrat(
                                          size: 14.sp,
                                          color: AppColors.textPrimary,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (canRemove)
                                      TextButton(
                                        onPressed: isRemoving
                                            ? null
                                            : () async {
                                                final shouldRemove =
                                                    await _confirmMemberRemoval(
                                                      context,
                                                      member,
                                                    );
                                                if (!shouldRemove ||
                                                    !context.mounted) {
                                                  return;
                                                }
                                                setSheetState(
                                                  () => locallyRemovingIds.add(
                                                    member.userId,
                                                  ),
                                                );
                                                final response =
                                                    await onRemoveMember?.call(
                                                      member.userId,
                                                    );
                                                if (!context.mounted) return;
                                                if (response?['success'] ==
                                                    true) {
                                                  setSheetState(() {
                                                    locallyRemovingIds.remove(
                                                      member.userId,
                                                    );
                                                    hiddenMemberIds.add(
                                                      member.userId,
                                                    );
                                                  });
                                                } else {
                                                  setSheetState(
                                                    () => locallyRemovingIds
                                                        .remove(member.userId),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        response?['error']
                                                                ?.toString() ??
                                                            'Could not remove member',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                        child: isRemoving
                                            ? SizedBox(
                                                width: 18.w,
                                                height: 18.w,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                'Remove',
                                                style: AppTextStyles.montserrat(
                                                  size: 14.sp,
                                                  color: AppColors.blueColor,
                                                  weight: FontWeight.w700,
                                                ),
                                              ),
                                      )
                                    else if (member.role != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0EAFF),
                                          borderRadius: BorderRadius.circular(
                                            18.r,
                                          ),
                                        ),
                                        child: Text(
                                          _roleLabel(member.role!),
                                          style: AppTextStyles.montserrat(
                                            size: 13.sp,
                                            color: AppColors.blueColor,
                                            weight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (index != visibleMembers.length - 1)
                                Divider(
                                  height: 1,
                                  color: AppColors.borderColor,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(metrics.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == metrics.length - 1 ? 0 : 12.w,
            ),
            child: InkWell(
              onTap: metrics[index].label == 'Members'
                  ? () => _showMemberDialog(context)
                  : null,
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                height: 148.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: AppBorders.raised(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Image.asset(
                        metrics[index].icon,
                        height: 32.sp,
                        width: 32.sp,
                        fit: BoxFit.cover,
                      ),
                    ),
                    6.verticalSpace,
                    Text(
                      metrics[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.montserrat(
                        size: 14.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w400,
                      ),
                    ),
                    6.verticalSpace,
                    Text(
                      metrics[index].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.montserrat(
                        size: 16.sp,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _avatarFallback(String avatar) {
    return Center(
      child: Text(
        avatar,
        style: AppTextStyles.montserrat(
          size: 28.sp,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    if (role.toLowerCase() == 'owner' || role.toLowerCase() == 'admin') {
      return 'Admin';
    }
    return role[0].toUpperCase() + role.substring(1);
  }
}

class _RemoveMemberDialog extends StatelessWidget {
  const _RemoveMemberDialog({
    required this.memberName,
    required this.circleName,
  });

  final String memberName;
  final String circleName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 22.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26.r),
          border: AppBorders.raised(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(false),
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: Icon(
                    Icons.close_rounded,
                    size: 25.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -8.h),
              child: Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEE3F5C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF35970),
                    width: 2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB91F3B),
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 35.sp,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              'Remove From Circle',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 19.sp,
                color: AppColors.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            14.verticalSpace,
            Text(
              'Remove $memberName from\n$circleName',
              textAlign: TextAlign.center,
              style: AppTextStyles.montserrat(
                size: 15.sp,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            20.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blueColor,
                        side: BorderSide(
                          color: AppColors.blueColor,
                          width: 2.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: AppColors.blueColor,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                14.horizontalSpace,
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.blueColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        'Remove',
                        style: AppTextStyles.montserrat(
                          size: 14.sp,
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
