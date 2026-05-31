import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/analysis_result.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/emotion_bar.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import 'chat_page.dart';
import 'dashboard_page.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, this.result});

  static const String routeName = '/results';

  final AnalysisResult? result;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      6,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
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
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animations[index]),
        child: child,
      ),
    );
  }

  AnalysisResult _resolveResult(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AnalysisResult) return args;
    return widget.result ?? AnalysisResult.demo;
  }

  @override
  Widget build(BuildContext context) {
    final data = _resolveResult(context);
    final score = data.score > 0 ? data.score : 78;
    final scoreValue = score / 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navIcon),
          onPressed: () =>
              context.go(DashboardPage.routeName),
        ),
        title: Text(
          'Résultats de l\'Analyse',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
      ),
      bottomNavigationBar: const SmartBottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildStaggered(
                0,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Analyse Terminée',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Résultats de Votre Session',
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Voici l\'analyse de vos émotions et de vos patterns de discours.',
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Overall Score Ring Card
              _buildStaggered(
                1,
                SkyCard(
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 72,
                            width: 72,
                            child: CircularProgressIndicator(
                              value: scoreValue,
                              strokeWidth: 7,
                              backgroundColor: AppColors.outline,
                              color: AppColors.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$score',
                                style: AppTextStyles.screenTitle.copyWith(
                                  fontSize: 20,
                                  color: AppColors.text,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Score',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              score >= 80
                                  ? 'Niveau Élite 🏆'
                                  : score >= 60
                                  ? 'Bon Niveau 👍'
                                  : 'En Progression 📈',
                              style: AppTextStyles.title2.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              score >= 80
                                  ? 'Excellente prestation ! Vous êtes dans le top des orateurs.'
                                  : score >= 60
                                  ? 'Bonne performance avec des axes d\'amélioration identifiés.'
                                  : 'Continuez à pratiquer pour progresser rapidement.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSoft,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildStaggered(
                2,
                SkyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              color: AppColors.skyDark,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Top 5 Émotions (Hume AI)',
                            style: AppTextStyles.title2.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      EmotionBar(
                        label: 'Confiance',
                        value: data.emotion('Confidence', fallback: 0.88),
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 14),
                      EmotionBar(
                        label: 'Nervosité',
                        value: data.emotion('Nervousness', fallback: 0.42),
                        color: const Color(0xFF8B8798),
                      ),
                      const SizedBox(height: 14),
                      EmotionBar(
                        label: 'Enthousiasme',
                        value: data.emotion('Excitement', fallback: 0.76),
                        color: AppColors.skyDark,
                      ),
                      const SizedBox(height: 14),
                      EmotionBar(
                        label: 'Stress',
                        value: data.emotion('Stress', fallback: 0.25),
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 14),
                      EmotionBar(
                        label: 'Tristesse',
                        value: data.emotion('Sadness', fallback: 0.12),
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Groq Coaching Bloc
              _buildStaggered(
                3,
                SkyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: AppColors.skyDark,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Analyse Groq (LLaMA 3)',
                            style: AppTextStyles.title2.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Points Forts
                      _buildCoachingSection(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.success,
                        title: '✅ Points Forts',
                        items: _extractList(data.feedback, 'strengths'),
                        emptyText: data.summary.isNotEmpty
                            ? data.summary
                            : 'Bonne communication générale.',
                        isStrength: true,
                      ),
                      const SizedBox(height: 16),

                      // Points Faibles
                      _buildCoachingSection(
                        icon: Icons.cancel_outlined,
                        iconColor: AppColors.danger,
                        title: '❌ Points Faibles',
                        items: _extractList(data.feedback, 'weaknesses'),
                        emptyText: 'Travaillez la clarté et la structure.',
                        isStrength: false,
                      ),
                      const SizedBox(height: 16),

                      // Solutions
                      _buildCoachingSection(
                        icon: Icons.lightbulb_outline_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: '💡 Solutions Recommandées',
                        items: _extractList(data.feedback, 'improvements'),
                        emptyText: 'Pratiquez régulièrement pour progresser.',
                        isStrength: null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildStaggered(
                4,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SkyButton(
                      label: '💬 Discuter avec le Coach',
                      icon: Icons.chat_rounded,
                      onTap: () {
                        context.push(ChatPage.routeName, extra: {
                            'context': data.insightText,
                            'score': data.score,
                            'emotions': data.emotions,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.go(
                        DashboardPage.routeName,
                      ),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Center(
                          child: Text(
                            'Retour au Tableau de Bord',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.textSoft,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Extracts a list from the feedback map by key.
  List<String> _extractList(Map<String, dynamic> feedback, String key) {
    final raw = feedback[key];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    }
    return [];
  }

  /// Builds a coaching section (strengths / weaknesses / improvements).
  Widget _buildCoachingSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
    required String emptyText,
    bool? isStrength,
  }) {
    final Color bgColor = isStrength == true
        ? AppColors.success.withValues(alpha: 0.08)
        : isStrength == false
        ? AppColors.danger.withValues(alpha: 0.08)
        : const Color(0xFFF59E0B).withValues(alpha: 0.08);

    final displayItems = items.isNotEmpty ? items : [emptyText];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.title2.copyWith(
                  fontSize: 13,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...displayItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: iconColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}