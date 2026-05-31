import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class TrainingSelectorPage extends StatelessWidget {
  const TrainingSelectorPage({super.key});

  static const String routeName = '/training';

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'Entretien technique',
        'subtitle': 'Préparez-vous aux questions techniques et algorithmiques',
        'icon': Icons.code_rounded,
        'route': '/upload',
      },
      {
        'title': 'Soft skills / Communication',
        'subtitle': 'Améliorez votre aisance relationnelle et votre écoute',
        'icon': Icons.handshake_rounded,
        'route': '/upload',
      },
      {
        'title': 'Présentation projet',
        'subtitle': 'Structurez et délivrez des présentations percutantes',
        'icon': Icons.bar_chart_rounded,
        'route': '/upload',
      },
      {
        'title': 'Simulation de coaching',
        'subtitle': 'Entraînez-vous avec un coach IA interactif',
        'icon': Icons.psychology_rounded,
        'route': '/chat',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navIcon),
          onPressed: () => context.pop(),
        ),
        title: Text('Choisir un entraînement', style: AppTextStyles.title2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sélectionnez un scénario', style: AppTextStyles.screenTitle),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final title = item['title'] as String;
                  final subtitle = item['subtitle'] as String;
                  final icon = item['icon'] as IconData;
                  final route = item['route'] as String;

                  return GestureDetector(
                    onTap: () {
                      if (route == '/chat') {
                        context.push(route);
                      } else {
                        context.push(route, extra: title);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.title2.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.80),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
