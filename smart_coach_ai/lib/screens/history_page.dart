import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/sky_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  static const String routeName = '/history';

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  var _filter = 'Tous';

  final _sessions = const [
    _SessionData(
      title: 'Simulation entretien',
      type: 'Entretien',
      date: '24/05/2026',
      score: 82,
    ),
    _SessionData(
      title: 'Pitch produit',
      type: 'Pitch',
      date: '22/05/2026',
      score: 75,
    ),
    _SessionData(
      title: 'Présentation projet',
      type: 'Présentation',
      date: '20/05/2026',
      score: 68,
    ),
  ];

  List<_SessionData> get _filteredSessions {
    if (_filter == 'Tous') return _sessions;
    return _sessions.where((s) => s.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: const Text('Historique'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const Text(
            'Filtres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Tous', 'Entretien', 'Pitch', 'Présentation'].map((
              label,
            ) {
              final selected = _filter == label;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                ),
                onSelected: (_) => setState(() => _filter = label),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          for (final session in _filteredSessions) ...[
            SkyCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      session.type == 'Pitch'
                          ? Icons.campaign_outlined
                          : session.type == 'Présentation'
                          ? Icons.slideshow_rounded
                          : Icons.work_outline_rounded,
                      color: AppColors.skyDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.title, style: AppTextStyles.title2),
                        const SizedBox(height: 4),
                        Text(
                          '${session.date} • ${session.type}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${session.score}',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.skyDark,
                        ),
                      ),
                      Text('score', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SkyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résumé', style: AppTextStyles.title2),
                const SizedBox(height: 12),
                Text(
                  'Vos dernières séances sont affichées ici. Utilisez le filtre pour retrouver vos entraînements passés.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionData {
  const _SessionData({
    required this.title,
    required this.type,
    required this.date,
    required this.score,
  });

  final String title;
  final String type;
  final String date;
  final int score;
}
