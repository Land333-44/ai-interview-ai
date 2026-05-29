import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SmartLogo extends StatelessWidget {
  const SmartLogo({
    super.key,
    this.size = 42,
    this.gradient = AppColors.primaryGradient,
  });

  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(size * 0.28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: size * 0.58,
            ),
          ),
          Positioned(
            right: -4,
            top: 2,
            child: _Node(size: size * 0.12),
          ),
          Positioned(
            right: 3,
            top: -5,
            child: _Node(size: size * 0.09),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: _Node(size: size * 0.08),
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryLight, width: 1.4),
      ),
    );
  }
}
