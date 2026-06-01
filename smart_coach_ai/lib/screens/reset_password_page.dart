import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/sky_button.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

/// This page is shown when the user taps the "Reset password" link from email.
///
/// Appwrite appends `?userId=xxx&secret=yyy` to the URL you registered in
/// [AppwriteConstants.passwordRecoveryUrl].
///
/// How the page receives those values:
///   • On **Flutter Web**: parsed directly from [Uri.base] (window.location).
///   • On **mobile / named route**: pass them as route arguments:
///       context.push(ResetPasswordPage.routeName,
///         arguments: {'userId': '...', 'secret': '...'});
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  static const String routeName = '/reset-password';

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _success = false;
  bool _isAuthenticated = false;   // true after OTP verification
  String _resetEmail = '';         // email used for resetPasswordViaToken

  String? _userId;
  String? _secret;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Parse query params from URL (web only).
    WidgetsBinding.instance.addPostFrameCallback((_) => _extractParams());
  }

  /// Reads `userId` and `secret` either from the web URL bar or from
  /// named-route arguments (passed when navigating inside the Flutter app).
  void _extractParams() {
    // 1. Try named-route arguments first (works on mobile & web).
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      // Check if this is the authenticated OTP flow
      final isAuth = args['isAuthenticated'] as bool? ?? false;
      if (isAuth) {
        setState(() {
          _isAuthenticated = true;
          _resetEmail = (args['email'] as String?) ?? '';
        });
        return;
      }
      // Classic link-based flow: get userId + secret from args
      setState(() {
        _userId = args['userId'] as String?;
        _secret = args['secret'] as String?;
      });
      return;
    }

    // 2. Fallback: parse the real browser URL (Flutter Web only).
    if (kIsWeb) {
      final uri = Uri.base;
      var userId = uri.queryParameters['userId'];
      var secret = uri.queryParameters['secret'];

      // Check URL fragment (hash routing) if not found in queryParameters
      if (userId == null || secret == null) {
        final fragment = uri.fragment;
        if (fragment.contains('?')) {
          final queryIndex = fragment.indexOf('?');
          final queryString = fragment.substring(queryIndex + 1);
          final params = Uri.splitQueryString(queryString);
          userId ??= params['userId'];
          secret ??= params['secret'];
        }
      }

      setState(() {
        _userId = userId;
        _secret = secret;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool ok;
    if (_isAuthenticated) {
      // OTP-verified flow: create recovery token + immediately use its secret
      ok = await AuthService().resetPasswordViaToken(
        email: _resetEmail,
        newPassword: _passwordController.text.trim(),
      );
    } else {
      // Classic link flow: userId + secret came from the email link URL
      if (_userId == null || _secret == null) {
        _showSnack(
          'Lien de réinitialisation invalide ou expiré. Veuillez en demander un nouveau.',
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }
      ok = await AuthService().confirmPasswordReset(
        userId: _userId!,
        secret: _secret!,
        newPassword: _passwordController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      setState(() => _success = true);
    } else {
      _showSnack(
        _isAuthenticated
            ? 'Impossible de réinitialiser le mot de passe. Veuillez réessayer.'
            : 'Le lien de réinitialisation a expiré ou a déjà été utilisé. Veuillez en demander un nouveau.',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────── build ──────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navIcon),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _success ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────── success view ─────────────
  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.skyDark,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Mot de passe mis à jour !',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _isAuthenticated
              ? 'Votre mot de passe a été réinitialisé avec succès.\nVous êtes maintenant connecté et prêt.'
              : 'Votre mot de passe a été réinitialisé avec succès.\nVous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
          style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SkyButton(
          label: _isAuthenticated ? 'Aller au Tableau de Bord' : 'Aller à la Connexion',
          icon: _isAuthenticated ? Icons.dashboard_rounded : Icons.login_rounded,
          onTap: () =>
              Navigator.pushReplacementNamed(
                context,
                _isAuthenticated ? DashboardPage.routeName : LoginPage.routeName,
              ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────── form view ────────────
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Créer un nouveau mot de passe',
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Créez un mot de passe contenant au moins 6 lettres et chiffres. Vous aurez besoin de ce mot de passe pour vous connecter.",
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.textSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: 'Nouveau mot de passe',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.muted,
                fontSize: 15,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.muted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.outline,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.skyDark,
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 2.0,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez entrer un mot de passe.';
              }
              if (v.trim().length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères.';
              }
              // Check if it has both letters and numbers
              final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(v);
              final hasDigit = RegExp(r'[0-9]').hasMatch(v);
              if (!hasLetter || !hasDigit) {
                return 'Le mot de passe doit contenir à la fois des lettres et des chiffres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.skyDark, // application theme active accent color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26), // pill shape
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Continuer',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}