import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../screens/coach_page.dart';
import '../screens/dashboard_page.dart';
import '../screens/results_page.dart';
import '../screens/upload_page.dart';

class SmartBottomNavBar extends StatelessWidget {
  const SmartBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 4;
          final pillWidth = itemWidth - 26;
          final left = currentIndex * itemWidth + 13;
          return Stack(
            children: [
              Positioned(
                left: left,
                top: 4,
                width: pillWidth,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.softPurple,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              BottomNavigationBar(
                currentIndex: currentIndex,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: AppColors.primaryLight,
                unselectedItemColor: AppColors.navIcon,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                showUnselectedLabels: true,
                onTap: (index) {
                  if (index == currentIndex) return;
                  final route = switch (index) {
                    0 => DashboardPage.routeName,
                    1 => UploadPage.routeName,
                    2 => ResultsPage.routeName,
                    _ => CoachPage.routeName,
                  };
                  Navigator.pushReplacementNamed(context, route);
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    label: 'Upload',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.insert_chart_outlined_rounded),
                    label: 'Analyse',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.smart_toy_outlined),
                    label: 'Coach',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
