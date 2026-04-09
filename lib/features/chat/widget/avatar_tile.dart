import 'package:flutter/material.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/features/chat/models/chat_model.dart';


class MemberAvatarTile extends StatelessWidget {
  final Member member;
  const MemberAvatarTile({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEEEEF8),
                border: Border.all(
                  color: member.isMe
                      ? AppColors.purple.withValues(alpha: 0.5)
                      : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(member.avatar, style: const TextStyle(fontSize: 22)),
              ),
            ),
            if (member.isOnline)
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.onlineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          member.isMe ? 'You' : member.name,
          style: TextStyle(
            fontSize: 10,
            color: member.isMe
                ? AppColors.purple
                : const Color(0xFF888888),
            fontWeight: member.isMe ? FontWeight.w600 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          member.score,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF555555),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}