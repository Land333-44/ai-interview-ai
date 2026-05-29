import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/sky_button.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  static const String routeName = '/welcome';

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Enregistrez-vous',
      'subtitle': 'Entraînez-vous à la prise de parole et aux entretiens en enregistrant vos réponses audio ou vidéo de haute qualité.',
      'icon': '🎙️',
    },
    {
      'title': 'L\'IA analyse tout',
      'subtitle': 'Notre coach intelligent analyse votre confiance vocale, votre présence, la clarté de votre discours et votre niveau de stress.',
      'icon': '🧠',
    },
    {
      'title': 'Suivez vos progrès',
      'subtitle': 'Visualisez votre progression hebdomadaire grâce à des tableaux de bord personnalisés et des échanges directs avec le coach IA.',
      'icon': '📈',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    context.go(LoginPage.routeName);
                  },
                  child: Text(
                    'Passer',
                    style: AppTextStyles.title2.copyWith(
                      color: AppColors.skyDark,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final item = _onboardingData[index];
                  return AnimatedOpacity(
                    opacity: _currentPage == index ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Big Emoji / Icon
                          Hero(
                            tag: 'app_logo_hero',
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item['icon']!,
                                style: const TextStyle(fontSize: 54),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            item['title']!,
                            style: AppTextStyles.screenTitle.copyWith(
                              fontSize: 26,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item['subtitle']!,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Dots Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.skyDark
                        : AppColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Bottom Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.skyDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            'Retour',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.skyDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: SkyButton(
                      label: _currentPage == _onboardingData.length - 1
                          ? 'Commencer'
                          : 'Suivant',
                      onTap: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          context.go(SignupPage.routeName);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}