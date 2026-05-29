import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'router.dart';

void main() {
  // Use path-based URLs (no #) so Appwrite redirect links like
  // /reset-password?userId=...&secret=... are handled correctly.
  usePathUrlStrategy();
  runApp(const SmartCoachApp());
}

class SmartCoachApp extends StatelessWidget {
  const SmartCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Coach AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        textTheme: AppTextStyles.textTheme,
      ),
      routerConfig: router,
    );
  }
}
