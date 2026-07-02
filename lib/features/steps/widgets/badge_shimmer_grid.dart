import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';

/// Shimmer placeholder shown while the badges are loading.
/// Mirrors the layout of [BadgesTabSection] (search bar + 2-column grid).
class BadgesShimmerGrid extends StatelessWidget {
  const BadgesShimmerGrid({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 50.h, radius: 25.r)),
              12.horizontalSpace,
              _ShimmerBox(width: 50.w, height: 50.w, radius: 25.w),
            ],
          ),
          14.verticalSpace,
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) => const _ShimmerBadgeCard(),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBadgeCard extends StatelessWidget {
  const _ShimmerBadgeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 10.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 50.w, height: 50.w, radius: 16.r),
          10.verticalSpace,
          _ShimmerBox(width: 110.w, height: 13.h, radius: 6.r),
          8.verticalSpace,
          _ShimmerBox(width: double.infinity, height: 11.h, radius: 6.r),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lightweight shimmer effect (no external package): sweeps a highlight
/// gradient across its child in a loop.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE8ECF3),
                Color(0xFFF7F9FC),
                Color(0xFFE8ECF3),
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 3 - 1.5),
      0,
      0,
    );
  }
}
