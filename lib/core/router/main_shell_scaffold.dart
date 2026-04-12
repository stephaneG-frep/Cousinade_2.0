import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/family/presentation/providers/family_providers.dart';

class MainShellScaffold extends ConsumerStatefulWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends ConsumerState<MainShellScaffold> {
  bool _checkedFamily = false;
  bool _checkedFamilyDoc = false;
  bool _handledReturnToPublish = false;

  @override
  void initState() {
    super.initState();
    _handleReturnToPublish();
  }

  Future<void> _handleReturnToPublish() async {
    if (_handledReturnToPublish) return;
    _handledReturnToPublish = true;
    final prefs = await SharedPreferences.getInstance();
    final shouldReturn = prefs.getBool('return_to_publish') ?? false;
    if (!shouldReturn) return;
    await prefs.remove('return_to_publish');
    if (!mounted) return;
    widget.navigationShell.goBranch(2, initialLocation: true);
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProfileProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user == null || _checkedFamily) return;
      _checkedFamily = true;
      ref
          .read(familyControllerProvider.notifier)
          .autoJoinDefaultFamily();
    });

    ref.listen(currentFamilyProvider, (previous, next) {
      if (_checkedFamilyDoc) return;
      final family = next.valueOrNull;
      final user = ref.read(currentUserProfileProvider).valueOrNull;
      if (user == null) return;
      if (family == null) {
        _checkedFamilyDoc = true;
        ref
            .read(familyControllerProvider.notifier)
            .autoJoinDefaultFamily();
      }
    });

    final isPublishSelected = widget.navigationShell.currentIndex == 2;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
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
