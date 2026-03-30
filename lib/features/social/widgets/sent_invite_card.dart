import 'package:flutter/material.dart';

class SentInviteCard extends StatelessWidget {
  final String name;
  final String status; // 'Pending', 'Accepted'
  final String? avatarUrl;

  const SentInviteCard({
    super.key,
    required this.name,
    required this.status,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = status.toLowerCase() == 'accepted';
    final bgColor = isAccepted
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFFBEB);
    final textColor = isAccepted
        ? const Color(0xFF166534)
        : const Color(0xFF92400E);
    final borderColor = isAccepted
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEF3C7);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
