import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/sky_button.dart';
import '../widgets/sky_card.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const String routeName = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  models.User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  String _initials(String name) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    context.go(LoginPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.name.isNotEmpty == true
        ? _user!.name
        : 'Utilisateur';
    final email = _user?.email ?? 'email inconnu';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: const Text('Profil'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                SkyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _initials(displayName),
                          style: AppTextStyles.title.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(displayName, style: AppTextStyles.title),
                      const SizedBox(height: 6),
                      Text(email, style: AppTextStyles.body),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Niveau débutant',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.skyDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(label: 'Sessions', value: '12'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(label: 'Score moyen', value: '76'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(label: 'Progrès', value: '+14%'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SkyCard(
                  child: Column(
                    children: [
                      _InfoRow(label: 'Nom complet', value: displayName),
                      _InfoRow(label: 'Email', value: email),
                      _InfoRow(label: 'Langue', value: 'Français'),
                      _InfoRow(label: 'État', value: 'Actif'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SkyButton(
                  label: 'Se déconnecter',
                  icon: Icons.logout_rounded,
                  onTap: _logout,
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SkyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.title.copyWith(color: AppColors.skyDark),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            value,
            style: AppTextStyles.body.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}
