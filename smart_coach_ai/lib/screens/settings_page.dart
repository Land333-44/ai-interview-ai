import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/sky_card.dart';
import '../widgets/sky_button.dart';
import 'history_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const String routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _emailReports = false;
  bool _darkMode = false;
  String _language = 'Français';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const Text(
            'Compte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          SkyCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profil',
                  onTap: () =>
                      context.push(ProfilePage.routeName),
                ),
                _SettingsTile(
                  icon: Icons.history_rounded,
                  title: 'Historique',
                  onTap: () =>
                      context.push(HistoryPage.routeName),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Mot de passe',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fonction de modification de mot de passe non implémentée.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Préférences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          SkyCard(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(labelText: 'Langue'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Français',
                      child: Text('Français'),
                    ),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _language = value);
                    }
                  },
                ),
                SwitchListTile(
                  value: _notifications,
                  activeColor: AppColors.primary,
                  title: const Text('Notifications'),
                  subtitle: const Text('Recevoir des alertes d’activité'),
                  onChanged: (value) => setState(() => _notifications = value),
                ),
                SwitchListTile(
                  value: _emailReports,
                  activeColor: AppColors.primary,
                  title: const Text('Rapports email'),
                  onChanged: (value) => setState(() => _emailReports = value),
                ),
                SwitchListTile(
                  value: _darkMode,
                  activeColor: AppColors.primary,
                  title: const Text('Mode sombre'),
                  onChanged: (value) => setState(() => _darkMode = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'À propos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          SkyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Coach AI', style: AppTextStyles.title2),
                const SizedBox(height: 8),
                Text('Version 1.0.0', style: AppTextStyles.body),
                const SizedBox(height: 6),
                Text(
                  'Application inspirée de lib1',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SkyButton(
            label: 'Retour à l’accueil',
            icon: Icons.arrow_back_rounded,
            secondary: true,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(color: AppColors.text),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}