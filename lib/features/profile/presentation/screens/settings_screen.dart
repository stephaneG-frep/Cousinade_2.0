import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/user_guide_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Confidentialite'),
            subtitle: Text('Application privee reservee a la famille'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Mode d\'emploi'),
            subtitle: const Text('Guide simple pas a pas'),
            onTap: () => context.push(AppRoutes.userGuide),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt_outlined),
            title: const Text('Revoir le guide au prochain lancement'),
            subtitle: const Text('Le guide s\'ouvrira automatiquement'),
            onTap: () async {
              await ref.read(userGuideProvider.notifier).markGuideUnseen();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Parfait, le mode d\'emploi reviendra au prochain demarrage.',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: const Text('Choisis entre clair et sombre'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Clair'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Sombre'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                final selectedMode = selection.first;
                ref.read(themeModeProvider.notifier).setThemeMode(selectedMode);
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Se deconnecter'),
            ),
          ),
        ],
      ),
    );
  }
}
