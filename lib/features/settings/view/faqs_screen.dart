import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_steps/core/theme/app_colors.dart';
import 'package:test_steps/core/theme/app_text_styles.dart';
import 'package:test_steps/widgets/shared/app_borders.dart';
import 'package:test_steps/widgets/shared/app_circular_back_button.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  /// Expanded FAQ index — ValueNotifier so taps rebuild only the card.
  final ValueNotifier<int> _expandedIndex = ValueNotifier(0);

  @override
  void dispose() {
    _expandedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/images/back.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250.h,
              color: AppColors.surface.withValues(alpha: 0.72),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 34.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 76.h,
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: AppCircularBackButton(),
                        ),
                        Positioned(
                          top: 9.h,
                          left: 48.w,
                          right: 48.w,
                          child: Text(
                            'Faqs',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.montserrat(
                              size: 20.sp,
                              color: AppColors.textPrimary,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  16.verticalSpace,
                  ValueListenableBuilder<int>(
                    valueListenable: _expandedIndex,
                    builder: (context, expandedIndex, _) => _FaqsCard(
                      items: _faqItems,
                      expandedIndex: expandedIndex,
                      onChanged: (index) {
                        _expandedIndex.value =
                            expandedIndex == index ? -1 : index;
                      },
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

class _FaqsCard extends StatelessWidget {
  const _FaqsCard({
    required this.items,
    required this.expandedIndex,
    required this.onChanged,
  });

  final List<_FaqItemData> items;
  final int expandedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: AppBorders.raised(),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final isExpanded = expandedIndex == index;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FaqTile(
                item: items[index],
                isExpanded: isExpanded,
                onTap: () => onChanged(index),
              ),
              if (index != items.length - 1)
                Divider(
                  height: 1.h,
                  thickness: 1.h,
                  color: AppColors.borderColor,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  final _FaqItemData item;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14.w,
          17.h,
          14.w,
          isExpanded ? 16.h : 18.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: AppTextStyles.montserrat(
                      size: 14.5.sp,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                      height: 1.28,
                    ),
                  ),
                ),
                12.horizontalSpace,
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 25.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: 10.h, right: 22.w),
                child: Text(
                  item.answer,
                  style: AppTextStyles.montserrat(
                    size: 12.5.sp,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w500,
                    height: 1.24,
                  ),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 160),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItemData {
  const _FaqItemData({required this.question, required this.answer});

  final String question;
  final String answer;
}

const _faqItems = [
  _FaqItemData(
    question: 'What is Territory Capture Visualization?',
    answer:
        'Territory Capture Visualization is a data-driven mapping feature that shows how players claim, defend, and contest geographic tiles in real time.',
  ),
  _FaqItemData(
    question: 'How does territory data get updated?',
    answer:
        'Territory updates when a valid walking session crosses a tile. The app refreshes ownership, energy, and battle history from the database.',
  ),
  _FaqItemData(
    question: 'Does it support real-time tracking?',
    answer:
        'Yes. Live walking sessions update your route and nearby territory state while you move, as long as location permissions are enabled.',
  ),
  _FaqItemData(
    question: 'Can I compare performance between territories?',
    answer:
        'Yes. Leaderboards and territory stats help compare tiles, energy, raids won, walking consistency, and overall player activity.',
  ),
  _FaqItemData(
    question: 'Can I customize how territories are defined?',
    answer:
        'Territories are generated from the app rules so the game stays fair, but your routes, claims, and home base shape your own territory pattern.',
  ),
];
