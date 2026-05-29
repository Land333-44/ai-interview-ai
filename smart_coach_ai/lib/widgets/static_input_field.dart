import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class StaticInputField extends StatelessWidget {
  const StaticInputField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trailingIcon,
    this.controller,
  });

  final String label;
  final String value;
  final IconData icon;
  final IconData? trailingIcon;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final isPassword = label.toUpperCase().contains('PASSWORD');
    final isEmail = label.toUpperCase().contains('EMAIL');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.outline, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.muted, size: 19),
              const SizedBox(width: 13),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword,
                  keyboardType:
                      isEmail ? TextInputType.emailAddress : TextInputType.text,
                  textInputAction: TextInputAction.next,
                  cursorColor: AppColors.sky,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: value,
                    hintStyle: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF697181),
                    ),
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ],
    );
  }
}
