import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import 'dashboard_page.dart';
import 'email_verification_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  static const String routeName = '/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
        ),
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
    final user = await AuthService().signUp(email, password, name);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      final otpUserId = await AuthService().sendEmailOtp(email);
      if (!mounted) return;
      context.push(
        EmailVerificationPage.routeName,
        extra: {
          'email': email,
          'userId': otpUserId ?? user.$id,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'inscription a échoué. Veuillez réessayer.'),
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
      context.go(DashboardPage.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La connexion Google a échoué. Veuillez réessayer.'),
        ),
      );
    }
  }

  Future<void> _loginWithApple() async {
    setState(() => _isLoading = true);
    final successUrl = '${Uri.base.origin}/login';
    final session = await AuthService().loginWithApple(successUrl: successUrl);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (session != null) {
      context.go(DashboardPage.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La connexion Apple a échoué. Veuillez réessayer.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool hasToggle = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: AppColors.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.caption,
            prefixIcon: Icon(icon, color: AppColors.muted, size: 18),
            suffixIcon: hasToggle
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    onPressed: onToggle,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.skyDark),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Header
              Hero(
                tag: 'app_logo_hero',
                child: Container(
                  height: 64,
                  width: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎙️', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Créer un compte',
                style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Commencez votre voyage vers l\'excellence aujourd\'hui.',
                style: AppTextStyles.body.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SkyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField(
                      label: 'NOM COMPLET',
                      controller: _nameController,
                      hint: 'ex: Jean Dupont',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'E-MAIL',
                      controller: _emailController,
                      hint: 'ex: jean@exemple.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'MOT DE PASSE',
                      controller: _passwordController,
                      hint: '••••••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      hasToggle: true,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'CONFIRMER LE MOT DE PASSE',
                      controller: _confirmPasswordController,
                      hint: '••••••••••••',
                      icon: Icons.verified_user_outlined,
                      obscure: _obscureConfirm,
                      hasToggle: true,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 16),
                    // Security tip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppColors.skyDark,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Utilisez au moins 12 caractères avec des symboles spéciaux pour une sécurité optimale.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSoft,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SkyButton(
                      label: 'S\'inscrire',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: _isLoading,
                      onTap: _signUp,
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
                      style: AppTextStyles.label.copyWith(fontSize: 9),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.outline)),
                ],
              ),
              const SizedBox(height: 20),
              // Google + Apple buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _loginWithGoogle,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Google',
                              style: AppTextStyles.title2.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _loginWithApple,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.apple_rounded,
                              color: AppColors.text,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Apple',
                              style: AppTextStyles.title2.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => context.go(LoginPage.routeName),
                child: Text.rich(
                  TextSpan(
                    text: 'Vous avez déjà un compte ? ',
                    children: [
                      TextSpan(
                        text: 'Se connecter',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.skyDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}