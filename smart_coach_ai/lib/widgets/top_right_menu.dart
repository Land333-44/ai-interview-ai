import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../screens/notifications_page.dart';
import '../screens/settings_page.dart';
import '../screens/profile_page.dart';
import '../screens/training_selector_page.dart';

class TopRightMenu extends StatelessWidget {
  const TopRightMenu({super.key, this.onLogout, this.unreadCount = 0});

  final VoidCallback? onLogout;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.navIcon,
              ),
              onPressed: () => context.push(NotificationsPage.routeName),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 12,
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
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert, color: AppColors.navIcon),
          onSelected: (value) {
            switch (value) {
              case 0:
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Token de session'),
                    content: const Text(
                      'Aucun token disponible localement. Cette interface montre le token si l\'application le stocke côté client.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
                break;
              case 1:
                context.push(SettingsPage.routeName);
                break;
              case 2:
                context.push(ProfilePage.routeName);
                break;
              case 3:
                context.push(TrainingSelectorPage.routeName);
                break;
              case 4:
                if (onLogout != null) {
                  onLogout!();
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<int>(value: 0, child: Text('Afficher token')),
            const PopupMenuItem<int>(value: 1, child: Text('Paramètres')),
            const PopupMenuItem<int>(value: 2, child: Text('Mon profil')),
            const PopupMenuItem<int>(
              value: 3,
              child: Text('Choisir entraînement'),
            ),
            if (onLogout != null)
              const PopupMenuItem<int>(value: 4, child: Text('Se déconnecter')),
          ],
        ),
      ],
    );
  }
}
