import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class SkyButton extends StatefulWidget {
  const SkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 48,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool isLoading;

  @override
  State<SkyButton> createState() => _SkyButtonState();
}

class _SkyButtonState extends State<SkyButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      setState(() => _scale = 0.95);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null || widget.isLoading;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: disabled ? null : widget.onTap,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: disabled ? AppColors.outline : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTextStyles.button,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
