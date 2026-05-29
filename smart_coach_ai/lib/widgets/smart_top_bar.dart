import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../screens/notifications_page.dart';
import 'smart_logo.dart';

class SmartTopBar extends StatelessWidget {
  const SmartTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.centerTitle = false,
    this.trailingIcon = Icons.notifications_none_rounded,
    this.onBack,
    this.onTrailingTap,
    this.logoGradient = AppColors.primaryGradient,
    this.titleColor,
    this.trailing,
  });

  final String title;
  final bool showBack;
  final bool centerTitle;
  final IconData trailingIcon;
  final VoidCallback? onBack;
  final VoidCallback? onTrailingTap;
  final Gradient logoGradient;
  final Color? titleColor;
  /// Optional fully custom trailing widget (overrides trailingIcon)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.navIcon,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
          ],
          SmartLogo(size: 38, gradient: logoGradient),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              textAlign: centerTitle ? TextAlign.center : TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(
                fontSize: 22,
                color: titleColor ?? AppColors.text,
              ),
            ),
          ),
          // Use custom trailing widget if provided
          if (trailing != null)
            trailing!
          else
            GestureDetector(
              onTap: onTrailingTap ??
                  (trailingIcon == Icons.notifications_none_rounded
                      ? () {
                          context.push(NotificationsPage.routeName,
                          );
                        }
                      : null),
              child: Icon(
                trailingIcon,
                color: trailingIcon == Icons.help_outline_rounded
                    ? AppColors.textSoft
                    : const Color(0xFF93A0B2),
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}