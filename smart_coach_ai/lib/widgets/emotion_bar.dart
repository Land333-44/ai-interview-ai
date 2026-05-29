import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class EmotionBar extends StatelessWidget {
  const EmotionBar({
    super.key,
    required this.label,
    required this.value, // value between 0.0 and 1.0
    this.color = AppColors.primary,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.title2.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$percentage%',
              style: AppTextStyles.title2.copyWith(
                fontSize: 12,
                color: color == AppColors.primary ? AppColors.skyDark : color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 8,
            width: double.infinity,
            color: AppColors.outline, // kBorder base track
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: value),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
