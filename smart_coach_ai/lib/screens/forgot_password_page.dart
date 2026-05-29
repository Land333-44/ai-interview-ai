import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const String routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre adresse e-mail.')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une adresse e-mail valide.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Send password recovery link via Appwrite's official recovery API
    final success = await AuthService().sendPasswordRecovery(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _linkSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Un lien de récupération sécurisé a été envoyé à votre adresse e-mail.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d\'envoyer le lien de récupération. Veuillez réessayer.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onLinkPasted() {
    final url = _linkController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez coller le lien de récupération.')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
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

      if (userId != null && secret != null) {
        Navigator.pushReplacementNamed(
          context,
          ResetPasswordPage.routeName,
          arguments: {
            'userId': userId,
            'secret': secret,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien invalide. Veuillez copier l\'URL complète depuis votre e-mail.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'analyser le lien. Veuillez vérifier l\'URL et réessayer.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navIcon),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _linkSent ? _buildLinkSentView() : _buildRequestView(),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestView() {
    return Column(
      key: const ValueKey('request_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        // Lock icon header
        Center(
          child: Hero(
            tag: 'app_logo_hero',
            child: Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.skyDark,
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Mot de passe oublié ?',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez votre adresse e-mail ci-dessous et nous vous enverrons un lien sécurisé pour réinitialiser votre mot de passe.',
          style: AppTextStyles.body.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        SkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ADRESSE E-MAIL',
                style: AppTextStyles.label,
              ),
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
                  prefixIcon: const Icon(Icons.mail_outline_rounded,
                      color: AppColors.muted, size: 18),
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
              const SizedBox(height: 24),
              SkyButton(
                label: 'Demander un lien',
                icon: Icons.send_rounded,
                isLoading: _isLoading,
                onTap: _handlePasswordReset,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, LoginPage.routeName);
          },
          child: Text.rich(
            TextSpan(
              text: 'Vous vous souvenez de votre mot de passe ? ',
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
      ],
    );
  }

  Widget _buildLinkSentView() {
    return Column(
      key: const ValueKey('link_sent_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        // Lock icon header
        Center(
          child: Container(
            height: 80,
            width: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: AppColors.skyDark,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Vérifiez votre boîte de réception',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Nous avons envoyé un lien sécurisé de réinitialisation de mot de passe à :\n',
            children: [
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.skyDark),
              ),
            ],
          ),
          style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'COLLEZ LE LIEN DE RÉCUPÉRATION ICI',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              Text(
                'Cliquez sur le lien dans votre e-mail pour réinitialiser votre mot de passe, OU copiez le lien et collez-le ci-dessous pour rester dans cette application :',
                style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.3),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkController,
                maxLines: 2,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Collez le lien de récupération https://... ici',
                  hintStyle: AppTextStyles.caption,
                  prefixIcon: const Icon(Icons.link_rounded,
                      color: AppColors.muted, size: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.skyDark),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
              ),
              const SizedBox(height: 20),
              SkyButton(
                label: 'Vérifier & Réinitialiser',
                icon: Icons.vpn_key_rounded,
                isLoading: _isLoading,
                onTap: _onLinkPasted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 10,
          children: [
            GestureDetector(
              onTap: _isLoading ? null : _handlePasswordReset,
              child: Text(
                'Renvoyer le lien',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  color: AppColors.skyDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _linkSent = false;
                  _linkController.clear();
                });
              },
              child: Text(
                'Changer d\'e-mail',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  color: AppColors.skyDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, LoginPage.routeName);
              },
              child: Text(
                'Retour à la connexion',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  color: AppColors.skyDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
