import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/sky_button.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  final _slides = const [
    _OnboardingSlide(
      icon: Icons.videocam_rounded,
      title: 'Enregistrez-vous facilement',
      description:
          'Préparez vos entretiens et vos pitchs avec de l’audio, de la vidéo ou du texte.',
    ),
    _OnboardingSlide(
      icon: Icons.psychology_rounded,
      title: 'L’IA analyse votre voix',
      description:
          'Recevez un diagnostic sur la clarté, le stress et la confiance.',
    ),
    _OnboardingSlide(
      icon: Icons.trending_up_rounded,
      title: 'Progressez chaque semaine',
      description:
          'Suivez vos scores, revoyez vos sessions et améliorez votre impact.',
    ),
  ];

  void _next() {
    if (_index == _slides.length - 1) {
      context.go(LoginPage.routeName);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Smart Coach AI', style: AppTextStyles.title),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(LoginPage.routeName),
                    child: Text(
                      'Passer',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.skyDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    return _slides[index];
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _index == index ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _index == index
                          ? AppColors.primary
                          : AppColors.outline,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SkyButton(
                label: _index == _slides.length - 1 ? 'Commencer' : 'Suivant',
                icon: Icons.arrow_forward_rounded,
                onTap: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 160,
          width: 160,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 72, color: AppColors.skyDark),
        ),
        const SizedBox(height: 40),
        Text(
          title,
          style: AppTextStyles.title.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.6),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}