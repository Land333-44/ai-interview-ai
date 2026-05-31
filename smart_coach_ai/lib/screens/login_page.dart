import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import 'dashboard_page.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse e-mail valide.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await AuthService().login(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (session != null) {
        await AuthService().createProfileForCurrentUser();
        if (!mounted) return;
        context.go(DashboardPage.routeName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre e-mail ou mot de passe est incorrect.'),
          ),
        );
      }
    } on AppwriteException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = 'Une erreur est survenue lors de la connexion.';
      if (e.code == 401) {
        errorMsg = 'Votre e-mail ou mot de passe est incorrect.';
      } else if (e.code == 403) {
        errorMsg =
            'Accès interdit (CORS/Platform). Assurez-vous d\'enregistrer votre plateforme Web/Mobile dans la Console Appwrite (ID Projet: 6a10c9d5003b379b2981).';
      } else if (e.message != null) {
        errorMsg = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion : $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final successUrl = '${Uri.base.origin}/login';
    final session = await AuthService().loginWithGoogle(successUrl: successUrl);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (session != null) {
      await AuthService().createProfileForCurrentUser();
      if (!mounted) return;
      context.go(DashboardPage.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La connexion Google a échoué. Veuillez réessayer.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated Big Logo
                Hero(
                  tag: 'app_logo_hero',
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '🎙️',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ravi de vous revoir !',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre mentor IA est prêt à continuer.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SkyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      Text('ADRESSE E-MAIL', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ex: nom@exemple.com',
                          hintStyle: AppTextStyles.caption,
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.muted,
                            size: 18,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.skyDark),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Password field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('MOT DE PASSE', style: AppTextStyles.label),
                          GestureDetector(
                            onTap: () => context.push(
                              ForgotPasswordPage.routeName,
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.skyDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: AppTextStyles.caption,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.muted,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.muted,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.skyDark),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SkyButton(
                        label: 'Se connecter',
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        onTap: _login,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OU CONTINUER AVEC',
                        style: AppTextStyles.label.copyWith(fontSize: 10),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.outline)),
                  ],
                ),
                const SizedBox(height: 24),
                // Google Sign In Button
                GestureDetector(
                  onTap: _isLoading ? null : _loginWithGoogle,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline, width: 1.2),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continuer avec Google',
                            style: AppTextStyles.title2.copyWith(
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                GestureDetector(
                  onTap: () => context.go(SignupPage.routeName),
                  child: Text.rich(
                    TextSpan(
                      text: "Vous n'avez pas de compte ? ",
                      children: [
                        TextSpan(
                          text: "S'inscrire",
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.skyDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}