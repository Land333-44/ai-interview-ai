import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'notifications_page.dart';
import 'reset_password_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  static const String routeName = '/email-verification';

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isAutoVerifying = false;
  bool _isPasswordReset = false;  // true when coming from ForgotPassword
  String _userEmail = 'your email';
  String? _userId;

  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;

  String _statusMessage =
      'Veuillez vérifier votre boîte de réception (et vos spams) et saisir le code de vérification à 6 chiffres ci-dessous.';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (index) {
      final node = FocusNode();
      node.addListener(() {
        setState(() {});
      });
      return node;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _extractParamsAndAutoVerify());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final argUserId = args['userId'] as String?;
      final argEmail = args['email'] as String?;
      final argIsPasswordReset = args['isPasswordReset'] as bool? ?? false;
      if (argUserId != null && _userId == null) {
        setState(() {
          _userId = argUserId;
          _isPasswordReset = argIsPasswordReset;
          if (argEmail != null && argEmail.isNotEmpty) {
            _userEmail = argEmail;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final user = await _authService.getCurrentUser();
    if (user != null && user.email.isNotEmpty) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  void _extractParamsAndAutoVerify() {
    // 1. Try named-route arguments first (works on mobile & web).
    final args = ModalRoute.of(context)?.settings.arguments;
    String? userId;
    String? secret;

    if (args is Map<String, dynamic>) {
      userId = args['userId'] as String?;
      secret = args['secret'] as String?;
    }

    // 2. Fallback: parse the real browser URL (Flutter Web only).
    if (kIsWeb && (userId == null || secret == null)) {
      final uri = Uri.base;
      userId = uri.queryParameters['userId'];
      secret = uri.queryParameters['secret'];

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
    }

    if (userId != null && secret != null) {
      setState(() {
        _isAutoVerifying = true;
      });
      _autoVerifyWithParams(userId, secret);
    }
  }

  Future<void> _autoVerifyWithParams(String userId, String secret) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Confirmation de votre adresse e-mail...';
    });

    final success = await _authService.confirmEmailVerification(
      userId: userId,
      secret: secret,
    );

    if (!mounted) return;

    if (success) {
      // Create user profile
      await _authService.createProfileForCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail vérifié avec succès ! Bienvenue sur Smart Coach IA.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(DashboardPage.routeName);
    } else {
      setState(() {
        _isLoading = false;
        _isAutoVerifying = false;
        _statusMessage = 'Le lien de vérification était invalide, expiré ou déjà utilisé. Veuillez demander un nouveau code ci-dessous.';
      });
    }
  }

  Future<void> _verifyOtp(String code) async {
    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session non trouvée. Veuillez réessayer ou demander un nouveau code.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Vérification du code...';}
    );

    final session = await _authService.verifyEmailOtp(
      userId: userId,
      otp: code,
    );

    if (!mounted) return;

    if (session != null) {
      if (_isPasswordReset) {
        // Identity confirmed via OTP!
        // The user is now logged in via OTP, so they can directly update their password.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Identité vérifiée ! Veuillez définir votre nouveau mot de passe.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(ResetPasswordPage.routeName, extra: {
            'isAuthenticated': true,
            'email': _userEmail,
          },
        );
      } else {
        // Normal signup email verification — create profile and go to Dashboard
        await _authService.createProfileForCurrentUser();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail vérifié avec succès ! Bienvenue sur Smart Coach IA.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(DashboardPage.routeName);
      }
    } else {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Code de vérification invalide. Veuillez vérifier et réessayer.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code incorrect. Veuillez réessayer.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resendVerification(String email) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Renvoi du code de vérification...';
    });

    final otpUserId = await _authService.sendEmailOtp(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (otpUserId != null) {
        _userId = otpUserId;
        _statusMessage = 'Le code de vérification a été renvoyé ! Vérifiez votre boîte de réception.';
      } else {
        _statusMessage = 'Impossible de renvoyer le code de vérification. Veuillez vérifier votre connexion et réessayer.';
      }
    });

    if (otpUserId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code de vérification renvoyé avec succès !'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final displayEmail = args?['email'] as String? ?? _userEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _VerificationHeader(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isAutoVerifying ? _buildAutoVerifyingView() : _buildLandingView(displayEmail),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoVerifyingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: 60,
          width: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.skyDark),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'VÉRIFICATION DE VOTRE COMPTE',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSoft,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_otpControllers[index].text.isEmpty && index > 0) {
                  _otpControllers[index - 1].clear();
                  _otpFocusNodes[index - 1].requestFocus();
                  setState(() {});
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Container(
              width: 38,
              height: 48,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _otpFocusNodes[index].hasFocus
                        ? AppColors.skyDark
                        : _otpControllers[index].text.isNotEmpty
                            ? AppColors.skyDark.withValues(alpha: 0.8)
                            : AppColors.muted.withValues(alpha: 0.5),
                    width: _otpFocusNodes[index].hasFocus ? 3.0 : 1.5,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 6,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                showCursor: true,
                cursorColor: AppColors.skyDark,
                style: AppTextStyles.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                onChanged: (value) {
                  if (value.length == 2) {
                    final newChar = value[value.length - 1];
                    _otpControllers[index].text = newChar;
                    _otpControllers[index].selection = TextSelection.fromPosition(
                      const TextPosition(offset: 1),
                    );
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    }
                  } else if (value.length > 2) {
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    for (int i = 0; i < digits.length && (index + i) < 6; i++) {
                      _otpControllers[index + i].text = digits[i];
                      _otpControllers[index + i].selection = TextSelection.fromPosition(
                        const TextPosition(offset: 1),
                      );
                    }
                    final targetIndex = (index + digits.length - 1).clamp(0, 5);
                    _otpFocusNodes[targetIndex].requestFocus();
                  } else if (value.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                    }
                  }
                  setState(() {});

                  final code = _otpControllers.map((c) => c.text).join();
                  if (code.length == 6) {
                    _verifyOtp(code);
                  }
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLandingView(String displayEmail) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Premium Mockup illustration of phone and verification code speech bubble
        Center(
          child: SizedBox(
            height: 96,
            width: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const Positioned(
                  left: 22,
                  bottom: 12,
                  child: Icon(
                    Icons.smartphone_rounded,
                    color: AppColors.skyDark,
                    size: 46,
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.skyDark, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 3.5,
                          height: 3.5,
                          decoration: const BoxDecoration(
                            color: AppColors.skyDark,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'VÉRIFIER VOTRE ADRESSE E-MAIL',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Nous avons envoyé un code de vérification à 6 chiffres à votre adresse e-mail :',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSoft,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          displayEmail,
          textAlign: TextAlign.center,
          style: AppTextStyles.title2.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSoft,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        _buildOtpInputs(),
        const SizedBox(height: 16),
        // Prominent NEXT / Verify button matching mockup
        SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading || _otpControllers.any((c) => c.text.isEmpty)
                ? null
                : () {
                    final code = _otpControllers.map((c) => c.text).join();
                    _verifyOtp(code);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.skyDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.outline,
              disabledForegroundColor: AppColors.muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
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
                    'SUIVANT',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 10,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  LoginPage.routeName,
                );
              },
              child: Text(
                'Changer d\'e-mail',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.skyDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: _isLoading ? null : () => _resendVerification(displayEmail),
              child: Text(
                'Renvoyer le code',
                style: AppTextStyles.label.copyWith(
                  color: _isLoading ? AppColors.muted : AppColors.skyDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  LoginPage.routeName,
                );
              },
              child: Text(
                'Retour à la connexion',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.skyDark,
                  fontSize: 13.5,
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

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.navIcon,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Smart Coach AI',
            style: AppTextStyles.title.copyWith(fontSize: 14),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.push(NotificationsPage.routeName);
            },
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.navIcon,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}