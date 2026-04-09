import 'package:flutter/material.dart';

import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';

enum OnboardingIllustrationType {
  walkToConquer,
  ownTheMap,
  competeWithFriends,
  buildAndDefend,
  earnAndLevelUp,
}

class OnboardingStepTemplate extends StatelessWidget {
  const OnboardingStepTemplate({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.primaryCtaLabel,
    required this.secondaryCtaLabel,
    required this.illustrationType,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  final int stepIndex;
  final String title;
  final String subtitle;
  final String primaryCtaLabel;
  final String secondaryCtaLabel;
  final OnboardingIllustrationType illustrationType;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFE8FF), Color(0xFFE0F4FF), Color(0xFFF0E8FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE8EAF7)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPurple.withValues(alpha: 0.16),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OnboardingProgressBar(stepIndex: stepIndex),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${stepIndex + 1} / 5',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF8E90A4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _OnboardingIllustration(
                        illustrationType: illustrationType,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2.copyWith(
                          color: const Color(0xFF232338),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF6F7082),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: onPrimaryPressed,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B62E3), Color(0xFF57D7EB)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Text(
                                primaryCtaLabel,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onSecondaryPressed,
                        child: Text(
                          secondaryCtaLabel,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF8E90A4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingProgressBar extends StatelessWidget {
  const _OnboardingProgressBar({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(5, (int index) {
        final bool active = index <= stepIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.brandPurple : const Color(0xFFE9EBF6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.illustrationType});

  final OnboardingIllustrationType illustrationType;

  @override
  Widget build(BuildContext context) {
    switch (illustrationType) {
      case OnboardingIllustrationType.walkToConquer:
        return const _WalkToConquerIllustration();
      case OnboardingIllustrationType.ownTheMap:
        return const _OwnMapIllustration();
      case OnboardingIllustrationType.competeWithFriends:
        return const _CompeteIllustration();
      case OnboardingIllustrationType.buildAndDefend:
        return const _BuildDefendIllustration();
      case OnboardingIllustrationType.earnAndLevelUp:
        return const _EarnLevelIllustration();
    }
  }
}

class _WalkToConquerIllustration extends StatelessWidget {
  const _WalkToConquerIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F0FF), Color(0xFFF6F8FF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: _CityShape(height: 76, width: 20),
          ),
          Positioned(
            top: 32,
            left: 48,
            child: _CityShape(height: 62, width: 18),
          ),
          Positioned(
            top: 16,
            right: 48,
            child: _CityShape(height: 84, width: 24),
          ),
          Positioned(
            top: 26,
            right: 22,
            child: _CityShape(height: 70, width: 18),
          ),
          const Center(
            child: Icon(
              Icons.directions_walk_rounded,
              size: 104,
              color: Color(0xFF5F7ED8),
            ),
          ),
          const Positioned(bottom: 26, left: 48, child: _HexPath()),
        ],
      ),
    );
  }
}

class _OwnMapIllustration extends StatelessWidget {
  const _OwnMapIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _HexCluster(color: Color(0xFFDDE8FF)),
          const Icon(Icons.bolt_rounded, size: 40, color: Color(0xFF8A63E8)),
          Positioned(
            left: 24,
            bottom: 24,
            child: Icon(
              Icons.person_pin_circle_rounded,
              color: AppColors.warning,
              size: 58,
            ),
          ),
          Positioned(
            right: 28,
            top: 34,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF57D7EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompeteIllustration extends StatelessWidget {
  const _CompeteIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          const Center(
            child: _HexCluster(color: Color(0xFFDDE8FF), scale: 0.86),
          ),
          Positioned(
            left: 28,
            top: 30,
            child: _AvatarChip(icon: Icons.person, crown: true),
          ),
          Positioned(
            right: 24,
            top: 34,
            child: _AvatarChip(icon: Icons.person_2, crown: true),
          ),
          Positioned(
            left: 34,
            bottom: 38,
            child: _AvatarChip(icon: Icons.person_3),
          ),
          Positioned(
            right: 32,
            bottom: 30,
            child: _AvatarChip(icon: Icons.person_4, crown: true),
          ),
          const Positioned(
            left: 72,
            top: 94,
            child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF8A63E8)),
          ),
          const Positioned(
            right: 72,
            top: 112,
            child: Icon(Icons.arrow_back_rounded, color: Color(0xFF57D7EB)),
          ),
        ],
      ),
    );
  }
}

class _BuildDefendIllustration extends StatelessWidget {
  const _BuildDefendIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: Align(alignment: Alignment.bottomCenter, child: _HexPath()),
          ),
          const Center(
            child: Icon(
              Icons.hiking_rounded,
              size: 96,
              color: Color(0xFF5677D1),
            ),
          ),
          Positioned(
            left: 36,
            top: 56,
            child: _ShieldChip(color: AppColors.info),
          ),
          Positioned(
            right: 38,
            top: 64,
            child: _ShieldChip(color: AppColors.brandPurple),
          ),
          Positioned(
            right: 56,
            bottom: 46,
            child: _ShieldChip(color: AppColors.brandCyan),
          ),
        ],
      ),
    );
  }
}

class _EarnLevelIllustration extends StatelessWidget {
  const _EarnLevelIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.celebration_rounded,
              size: 110,
              color: Color(0xFF8A63E8),
            ),
          ),
          Positioned(
            top: 28,
            left: 34,
            child: _RewardChip(
              icon: Icons.emoji_events_rounded,
              color: AppColors.warning,
            ),
          ),
          Positioned(
            top: 72,
            right: 30,
            child: _RewardChip(
              icon: Icons.workspace_premium_rounded,
              color: AppColors.info,
            ),
          ),
          Positioned(
            bottom: 42,
            left: 34,
            child: _RewardChip(
              icon: Icons.redeem_rounded,
              color: AppColors.brandPurple,
            ),
          ),
          Positioned(
            bottom: 58,
            right: 34,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFDCE1F5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'XP',
                    style: AppTextStyles.chipLabel.copyWith(
                      color: AppColors.brandPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '20',
                      style: AppTextStyles.chipLabel.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexPath extends StatelessWidget {
  const _HexPath();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _HexTile(color: Color(0xFFCDBBFF)),
        SizedBox(width: 6),
        _HexTile(color: Color(0xFFCDEFFF)),
        SizedBox(width: 6),
        _HexTile(color: Color(0xFF9DE6F5)),
      ],
    );
  }
}

class _HexCluster extends StatelessWidget {
  const _HexCluster({required this.color, this.scale = 1});

  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double size = 42 * scale;

    return Stack(
      alignment: Alignment.center,
      children: [
        _HexTile(color: color, size: size),
        Positioned(
          left: size * 0.78,
          child: _HexTile(color: color, size: size),
        ),
        Positioned(
          right: size * 0.78,
          child: _HexTile(color: color, size: size),
        ),
        Positioned(
          top: size * 0.72,
          child: _HexTile(color: color, size: size),
        ),
        Positioned(
          bottom: size * 0.72,
          child: _HexTile(color: color, size: size),
        ),
      ],
    );
  }
}

class _HexTile extends StatelessWidget {
  const _HexTile({required this.color, this.size = 42});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.88,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _CityShape extends StatelessWidget {
  const _CityShape({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFC8D9FD),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({required this.icon, this.crown = false});

  final IconData icon;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDCE1F5), width: 2),
          ),
          child: Icon(icon, color: AppColors.brandPurple),
        ),
        if (crown)
          const Positioned(
            right: -4,
            top: -6,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 14,
              color: AppColors.warning,
            ),
          ),
      ],
    );
  }
}

class _ShieldChip extends StatelessWidget {
  const _ShieldChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.shield_outlined, color: color, size: 20),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}
