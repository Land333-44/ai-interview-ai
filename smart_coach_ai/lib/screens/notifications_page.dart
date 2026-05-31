import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/sky_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const String routeName = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.verified_rounded,
      'title': 'Analyse de session prête',
      'message': 'Votre dernière session d\'expression a été analysée avec succès.',
      'time': 'Maintenant',
      'color': AppColors.success,
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'Nouvel aperçu de l\'IA',
      'message': 'Une nouvelle recommandation de coaching est disponible pour votre rythme vocal.',
      'time': '12 min',
      'color': AppColors.primary,
    },
    {
      'icon': Icons.mic_none_rounded,
      'title': 'Conseil d\'enregistrement',
      'message': 'Utilisez un environnement calme pour améliorer la précision de la détection des émotions.',
      'time': '1h',
      'color': AppColors.warning,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _notifications.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navIcon),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined, color: AppColors.navIcon),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toutes les notifications sont marquées comme lues')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _notifications.length,
          itemBuilder: (context, i) {
            final item = _notifications[i];
            return FadeTransition(
              opacity: _animations[i],
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(_animations[i]),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SkyCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: AppTextStyles.title2.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['message'] as String,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item['time'] as String,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.skyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
