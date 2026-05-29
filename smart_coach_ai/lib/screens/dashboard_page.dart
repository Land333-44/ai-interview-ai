import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/dashboard_stats.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import '../widgets/sky_insight_card.dart';
import 'upload_page.dart';
import 'chat_page.dart';
import 'notifications_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const String routeName = '/dashboard';

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final _auth = AuthService();
  final _dashboard = DashboardService();
  String _userName = 'Coach';
  DashboardStats _stats = DashboardStats.empty;
  bool _loading = true;
  int _currentNavIndex = 0;

  late AnimationController _fabController;
  late Animation<double> _fabPulse;

  // Staggered animation controllers for cards
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;



  @override
  void initState() {
    super.initState();
    _loadDashboard();

    // FAB pulse animation
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fabPulse = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    // Staggered card animations
    _cardControllers = List.generate(
      6,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _cardAnimations = _cardControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    }).toList();

    // Start staggered animations
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    for (var c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      final user = await _auth.getCurrentUser();
      if (user != null) {
        await _auth.createProfileForCurrentUser();
      }
      final stats = await _dashboard.loadStats();
      if (!mounted) return;
      setState(() {
        if (user != null) {
          _userName =
              user.name.isNotEmpty ? user.name.split(' ').first : 'Coach';
        }
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, LoginPage.routeName, (r) => false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 18) return 'Bonjour';
    return 'Bonsoir';
  }

  Widget _buildFadeSlide(int index, Widget child) {
    return FadeTransition(
      opacity: _cardAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_cardAnimations[index]),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: ScaleTransition(
        scale: _fabPulse,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, UploadPage.routeName),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
          label: Text('+ Nouvelle Session',
              style: AppTextStyles.button.copyWith(fontSize: 12)),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadDashboard,
                child: CustomScrollView(
                  slivers: [
                    // --- App Bar ---
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: AppColors.background,
                      elevation: 0,
                      title: Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('🎙️',
                                style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Smart Coach AI',
                            style: AppTextStyles.title2.copyWith(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded,
                                  color: AppColors.navIcon),
                              onPressed: () => Navigator.pushNamed(
                                  context, NotificationsPage.routeName),
                            ),
                            if (_stats.unreadNotifications > 0)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  height: 8,
                                  width: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: AppColors.navIcon, size: 20),
                          onPressed: _logout,
                        ),
                      ],
                    ),

                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // --- Greeting ---
                          _buildFadeSlide(
                            0,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()}, $_userName 👋',
                                  style: AppTextStyles.screenTitle.copyWith(
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prêt à améliorer vos compétences ?',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- Stats Row ---
                          _buildFadeSlide(
                            1,
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.mic_rounded,
                                  label: _stats.sessionsLabel,
                                  subtitle: 'Sessions',
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                _StatChip(
                                  icon: Icons.trending_up_rounded,
                                  label: _stats.avgScoreLabel,
                                  subtitle: 'Score Moyen',
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 12),
                                _StatChip(
                                  icon: Icons.emoji_events_outlined,
                                  label: _stats.progressLabel,
                                  subtitle: 'Progrès',
                                  color: AppColors.warning,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // --- Session History ---
                          _buildFadeSlide(
                            2,
                            Row(
                              children: [
                                Text(
                                  'Historique des sessions',
                                  style: AppTextStyles.title.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Voir tout →',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.skyDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFadeSlide(
                            2,
                            _stats.recentSessions.isEmpty
                                ? SkyCard(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Text(
                                        'Aucune session enregistrée.',
                                        style: AppTextStyles.body,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _stats.recentSessions.length,
                                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, i) {
                                      final s = _stats.recentSessions[i];
                                      final title = s['title']?.toString() ?? 'Session';
                                      final type = s['analysisType']?.toString() ?? 'text';
                                      final dateStr = s['runDate']?.toString() ?? s['\$createdAt']?.toString() ?? '';
                                      String formattedDate = '';
                                      try {
                                        final dt = DateTime.parse(dateStr).toLocal();
                                        formattedDate = '${dt.day}/${dt.month}/${dt.year}';
                                      } catch (_) {}

                                      final rawScore = s['score'] ?? 0;
                                      final score = rawScore is num ? rawScore.round() : int.tryParse(rawScore.toString()) ?? 0;

                                      IconData icon = Icons.description_rounded;
                                      if (type.toLowerCase() == 'audio') icon = Icons.mic_rounded;
                                      if (type.toLowerCase() == 'video') icon = Icons.videocam_rounded;
                                      if (type.toLowerCase() == 'image') icon = Icons.image_rounded;

                                      return GestureDetector(
                                        onTap: () {
                                          // Navigate to ResultsPage if desired, but we need the full AnalysisResult.
                                          // For now, it's just a UI list item.
                                        },
                                        child: SkyCard(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(icon, color: AppColors.skyDark, size: 20),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(title, style: AppTextStyles.title2.copyWith(fontSize: 14)),
                                                    const SizedBox(height: 4),
                                                    Text(formattedDate, style: AppTextStyles.caption),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: score >= 80 ? AppColors.success.withValues(alpha: 0.15) : AppColors.outline,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '$score',
                                                  style: AppTextStyles.title2.copyWith(
                                                    fontSize: 14,
                                                    color: score >= 80 ? AppColors.success : AppColors.text,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 28),

                          // --- Global Score of Last Session ---
                          _buildFadeSlide(
                            3,
                            SkyCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Score Global (Dernière Session)',
                                        style: AppTextStyles.title.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Récent',
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.skyDark,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 80,
                                        width: 80,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: (_stats.lastSessionScore ?? 0) / 100,
                                              strokeWidth: 8,
                                              backgroundColor: AppColors.outline,
                                              color: AppColors.primary,
                                              strokeCap: StrokeCap.round,
                                            ),
                                            Text(
                                              '${_stats.lastSessionScore ?? 0}',
                                              style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Text(
                                          _stats.lastSessionScore != null
                                              ? 'Voici le score global calculé lors de votre dernière session d\'entraînement.'
                                              : 'Aucune session enregistrée. Lancez une nouvelle session pour obtenir votre score.',
                                          style: AppTextStyles.body.copyWith(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- Quick Actions ---
                          _buildFadeSlide(
                            4,
                            Row(
                              children: [
                                Expanded(
                                  child: SkyButton(
                                    label: 'Chat Coach',
                                    icon: Icons.chat_rounded,
                                    onTap: () => Navigator.pushNamed(
                                        context, ChatPage.routeName),
                                    height: 44,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, UploadPage.routeName),
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.primary,
                                            width: 1.5),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.upload_file_rounded,
                                                color: AppColors.skyDark,
                                                size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Télécharger',
                                              style: AppTextStyles.button
                                                  .copyWith(
                                                      color: AppColors.skyDark,
                                                      fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- AI Insight Card ---
                          _buildFadeSlide(
                            5,
                            const SkyInsightCard(
                              title: 'Astuce d\'Expert — Méthode STAR',
                              insight:
                                  'Structurez vos réponses avec Situation, Tâche, Action, Résultat. Cette méthode aide les recruteurs à comprendre clairement votre impact lors des entretiens comportementaux.',
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Accueil'},
      {'icon': Icons.history_rounded, 'label': 'Session'},
      {'icon': Icons.chat_rounded, 'label': 'Coach'},
      {'icon': Icons.person_rounded, 'label': 'Progrès'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = _currentNavIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentNavIndex = i);
                  if (i == 2) Navigator.pushNamed(context, ChatPage.routeName);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color:
                            isSelected ? AppColors.skyDark : AppColors.navIcon,
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          items[i]['label'] as String,
                          style: AppTextStyles.title2.copyWith(
                            fontSize: 12,
                            color: AppColors.skyDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.title.copyWith(
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
