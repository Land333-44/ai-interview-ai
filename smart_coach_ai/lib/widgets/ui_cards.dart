import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE8E5EF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    this.horizontal = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 25),
    );

    final text = Column(
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.title.copyWith(
            fontSize: horizontal ? 20 : 18,
            height: horizontal ? 1.1 : 1.05,
          ),
        ),
        SizedBox(height: horizontal ? 8 : 6),
        Text(
          description,
          style: AppTextStyles.body.copyWith(
            fontSize: horizontal ? 14 : 12,
            height: horizontal ? 1.35 : 1.22,
          ),
        ),
      ],
    );

    return WhiteCard(
      padding: const EdgeInsets.all(18),
      child: horizontal
          ? Row(
              children: [
                iconBox,
                const SizedBox(width: 18),
                Expanded(child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBox,
                const SizedBox(height: 18),
                text,
              ],
            ),
    );
  }
}

class MetricBar extends StatelessWidget {
  const MetricBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 15,
                    letterSpacing: 1.6,
                    color: AppColors.textSoft,
                  ),
                ),
              ),
              Text(
                '$value%',
                style: AppTextStyles.title.copyWith(
                  fontSize: 18,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: value / 100,
              backgroundColor: AppColors.grayBar,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
