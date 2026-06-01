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

    // Email format validation
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎙️', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  'Bienvenue !',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(fontSize: 26),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Connectez-vous pour continuer votre progression.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              SkyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.push(ForgotPasswordPage.routeName,
                          );
                        },
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    SkyButton(
                      label: 'Se connecter',
                      icon: Icons.login_rounded,
                      isLoading: _isLoading,
                      onTap: _login,
                    ),
                    const SizedBox(height: 12),
                    SkyButton(
                      label: 'Continuer avec Google',
                      icon: Icons.g_mobiledata_rounded,
                      secondary: true,
                      onTap: _isLoading ? null : _loginWithGoogle,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          SignupPage.routeName,
                        );
                      },
                      child: const Text('Créer un compte'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}