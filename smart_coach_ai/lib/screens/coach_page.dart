import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import 'chat_page.dart';
import 'dashboard_page.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  static const String routeName = '/coach';

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<Map<String, dynamic>> _improvements = [
    {
      'icon': Icons.air_rounded,
      'title': 'Respiration profonde',
      'subtitle': 'Stabiliser le rythme cardiaque avant les transitions',
    },
    {
      'icon': Icons.visibility_outlined,
      'title': 'Contact visuel',
      'subtitle': 'Maintenir le regard pendant 3s pour établir le contact',
    },
    {
      'icon': Icons.speed_rounded,
      'title': 'Rythme vocal',
      'subtitle': 'Réduire la vitesse de 15% pendant le résumé',
    },
    {
      'icon': Icons.pause_circle_outline_rounded,
      'title': 'Pauses rhétoriques',
      'subtitle': 'Laisser 2s pour que les idées clés s\'installent',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildStaggered(int index, Widget child) {
    return FadeTransition(
      opacity: _animations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_animations[index]),
        child: child,
      ),
    );
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
          onPressed: () => Navigator.pushReplacementNamed(
              context, DashboardPage.routeName),
        ),
        title: Text(
          'Conseils du Coach IA',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              _buildStaggered(
                0,
                Column(
                  children: [
                    Container(
                      height: 96,
                      width: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: AppColors.skyDark,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Feedback du Coach IA',
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Conseils personnalisés générés à partir de votre dernière session d\'expression.',
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Overall Assessment Card
              _buildStaggered(
                1,
                SkyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assessment_outlined,
                              color: AppColors.skyDark,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Évaluation globale',
                            style: AppTextStyles.title2.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Votre performance montre de solides bases dans la maîtrise du sujet. Cependant, la résonance émotionnelle de votre discours pourrait être renforcée en modulant votre rythme vocal lors des points clés. L\'IA a détecté une légère tension au cours des trois premières minutes, qui s\'est nettement améliorée par la suite.',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Strategic Improvements Card
              _buildStaggered(
                2,
                SkyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMÉLIORATIONS STRATÉGIQUES',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.skyDark,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(_improvements.length, (i) {
                        final item = _improvements[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: AppColors.skyDark,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: AppTextStyles.title2
                                          .copyWith(fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['subtitle'] as String,
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 10,
                                        color: AppColors.textSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                                size: 18,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Chat with AI Coach Button
              _buildStaggered(
                3,
                SkyButton(
                  label: 'Discuter avec le Coach IA',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () {
                    Navigator.pushNamed(context, ChatPage.routeName);
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
