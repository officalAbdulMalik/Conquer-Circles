import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';

class AppAvatarStack extends StatelessWidget {
  const AppAvatarStack({
    super.key,
    required this.emojis,
    this.imageUrls = const [],
    this.labels = const [],
    this.size = 30,
    this.overlap = 18,
    this.backgroundColor = AppColors.surface,
  });

  final List<String> emojis;
  final List<String?> imageUrls;
  final List<String> labels;
  final double size;
  final double overlap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final total = [
      emojis.length,
      imageUrls.length,
      labels.length,
    ].reduce((value, length) => value > length ? value : length);
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: size.h,
      width: size.w + overlap.w * (total - 1),
      child: Stack(
        children: List.generate(total, (index) {
          final imageUrl = index < imageUrls.length
              ? imageUrls[index]?.trim()
              : null;
          final label = index < labels.length ? labels[index].trim() : '';
          final fallback = index < emojis.length && emojis[index].isNotEmpty
              ? emojis[index]
              : _initials(label);

          return Positioned(
            left: index * overlap.w,
            child: Tooltip(
              message: label,
              child: Container(
                width: size.w,
                height: size.h,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderColor, width: 2.w),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl?.isNotEmpty == true
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(fallback),
                      )
                    : _fallback(fallback),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _fallback(String text) {
    return Center(
      child: Text(
        text.isEmpty ? '👤' : text,
        style: TextStyle(
          fontSize: text.length <= 2 ? size * 0.34 : size * 0.45,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
