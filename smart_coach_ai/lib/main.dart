import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'models/analysis_result.dart';
import 'models/analysis_session_args.dart';
import 'screens/analysis_page.dart';
import 'screens/chat_page.dart';
import 'screens/coach_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/email_verification_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/login_page.dart';
import 'screens/notifications_page.dart';
import 'screens/results_page.dart';
import 'screens/signup_page.dart';
import 'screens/upload_page.dart';
import 'screens/welcome_page.dart';
import 'services/auth_service.dart';

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
    return MaterialApp(
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
      // Show a splash that checks session, then routes accordingly
      home: const _SessionSplash(),
      routes: {
        WelcomePage.routeName: (_) => const WelcomePage(),
        LoginPage.routeName: (_) => const LoginPage(),
        ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
        ResetPasswordPage.routeName: (_) => const ResetPasswordPage(),
        EmailVerificationPage.routeName: (_) => const EmailVerificationPage(),
        '/verify-email': (_) => const EmailVerificationPage(),
        NotificationsPage.routeName: (_) => const NotificationsPage(),
        SignupPage.routeName: (_) => const SignupPage(),
        DashboardPage.routeName: (_) => const DashboardPage(),
        UploadPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is int) {
            return UploadPage(initialTab: args.clamp(0, 3));
          }
          if (args is String) {
            return UploadPage(scenarioTitle: args);
          }
          return const UploadPage();
        },
        AnalysisPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return AnalysisPage(
            args: args is AnalysisSessionArgs ? args : null,
          );
        },
        ResultsPage.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return ResultsPage(
            result: args is AnalysisResult ? args : null,
          );
        },
        CoachPage.routeName: (_) => const CoachPage(),
        ChatPage.routeName: (_) => const ChatPage(),
      },
    );
  }
}

/// Checks if a session already exists. If yes → Dashboard. If no → Welcome.
class _SessionSplash extends StatefulWidget {
  const _SessionSplash();

  @override
  State<_SessionSplash> createState() => _SessionSplashState();
}

class _SessionSplashState extends State<_SessionSplash> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await AuthService().getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      // Already logged in → go to Dashboard
      Navigator.pushReplacementNamed(context, DashboardPage.routeName);
    } else {
      // Not logged in → go to Welcome
      Navigator.pushReplacementNamed(context, WelcomePage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a branded loading screen while checking session
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
