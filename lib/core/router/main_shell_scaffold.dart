import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPublishSelected = navigationShell.currentIndex == 2;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_2_outlined),
            activeIcon: const Icon(Icons.groups_2),
            label: 'Famille',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded),
            ),
            activeIcon: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPublishSelected ? AppColors.orange : AppColors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.lightShadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: isPublishSelected ? AppColors.white : AppColors.orange,
              ),
            ),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_outlined),
            activeIcon: const Icon(Icons.event),
            label: 'Evenements',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
