import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WaveVisualizer extends StatefulWidget {
  const WaveVisualizer({
    super.key,
    required this.isAnimating,
    this.color = AppColors.primary,
  });

  final bool isAnimating;
  final Color color;

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int barCount = 7;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(barCount, (index) {
            // Sinusoidal math based on time and bar index to create organic wave effect
            final double animValue = widget.isAnimating ? _controller.value : 0.0;
            final double angle = animValue * 2 * math.pi + (index * 0.8);
            final double heightMultiplier = (math.sin(angle) + 1.0) / 2.0; // 0.0 to 1.0
            final double height = 8 + (heightMultiplier * 36);

            return Container(
              width: 6,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: widget.isAnimating
                    ? widget.color.withValues(
                        alpha: 0.4 + (heightMultiplier * 0.6))
                    : AppColors.muted,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        );
      },
    );
  }
}
