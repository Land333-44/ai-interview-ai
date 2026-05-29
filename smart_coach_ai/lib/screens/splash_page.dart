import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await AuthService().getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      context.go(DashboardPage.routeName);
    } else {
      context.go(WelcomePage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Smart Coach AI',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
