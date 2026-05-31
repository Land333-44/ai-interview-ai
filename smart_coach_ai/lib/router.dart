import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/analysis_result.dart';
import 'models/analysis_session_args.dart';
import 'screens/analysis_page.dart';
import 'screens/chat_page.dart';
import 'screens/coach_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/email_verification_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/history_page.dart';
import 'screens/login_page.dart';
import 'screens/profile_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/results_page.dart';
import 'screens/settings_page.dart';
import 'screens/notifications_page.dart';
import 'screens/training_selector_page.dart';
import 'screens/signup_page.dart';
import 'screens/upload_page.dart';
import 'screens/welcome_page.dart';
import 'screens/splash_page.dart';

final router = GoRouter(
  routes: [
    _route('/', const SplashPage()),
    _route('/welcome', const WelcomePage()),
    _route('/login', const LoginPage()),
    _route('/signup', const SignupPage()),
    _route('/forgot-password', const ForgotPasswordPage()),
    _route('/reset-password', const ResetPasswordPage()),
    _route('/email-verification', const EmailVerificationPage()),
    _route('/dashboard', const DashboardPage()),
    _route('/training', const TrainingSelectorPage()),
    _route('/notifications', const NotificationsPage()),
    _route('/profile', const ProfilePage()),
    _route('/settings', const SettingsPage()),
    _route('/history', const HistoryPage()),
    GoRoute(
      path: '/upload',
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra is int) {
          return _transition(state, UploadPage(initialTab: extra.clamp(0, 3)));
        }
        if (extra is String) {
          return _transition(state, UploadPage(scenarioTitle: extra));
        }
        return _transition(state, const UploadPage());
      },
    ),
    GoRoute(
      path: '/analysis',
      pageBuilder: (context, state) {
        return _transition(
          state,
          AnalysisPage(
            args: state.extra is AnalysisSessionArgs
                ? state.extra as AnalysisSessionArgs
                : null,
          ),
        );
      },
    ),
    GoRoute(
      path: '/results',
      pageBuilder: (context, state) {
        return _transition(
          state,
          ResultsPage(
            result: state.extra is AnalysisResult
                ? state.extra as AnalysisResult
                : null,
          ),
        );
      },
    ),
    _route('/coach', const CoachPage()),
    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          return _transition(
            state,
            ChatPage(
              sessionContext: extra['context']?.toString(),
              sessionScore: extra['score'] as int?,
            ),
          );
        }
        return _transition(state, const ChatPage());
      },
    ),
  ],
);

GoRoute _route(String path, Widget screen) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _transition(state, screen),
  );
}

CustomTransitionPage<void> _transition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
