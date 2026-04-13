import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/help_action.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          const HelpAction(),
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilisateur introuvable'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(currentUserProfileProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: AppAvatar(
                    initial: user.displayName,
                    imageUrl: user.avatarUrl,
                    radius: 42,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 4),
                Center(child: Text(user.email)),
                const SizedBox(height: 12),
                if ((user.bio ?? '').isNotEmpty)
                  Text(user.bio!, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.editProfile),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier mon profil'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.notifications),
                  icon: const Icon(Icons.notifications_none),
                  label: const Text('Notifications'),
                ),
              ],
            ),
          );
        },
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
        loading: () => const LoadingWidget(),
      ),
    );
  }
}
