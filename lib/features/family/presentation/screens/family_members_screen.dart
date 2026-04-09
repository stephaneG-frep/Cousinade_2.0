import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/family_providers.dart';

class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final conversationId = await ref
        .read(chatControllerProvider.notifier)
        .startConversationWith(userId);

    if (conversationId != null && context.mounted) {
      context.push('/chat/$conversationId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Famille'),
        actions: [
          if (familyAsync.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('Code: ${familyAsync.valueOrNull!.inviteCode}'),
              ),
            ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun membre',
              subtitle: 'Ajoutez des proches avec votre code famille.',
              icon: Icons.group_outlined,
            );
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return UserTile(
                user: member,
                trailing: member.id == currentUser?.id
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () => _openChat(context, ref, member.id),
                      ),
              );
            },
          );
        },
        error: (error, _) => ErrorStateWidget(message: error.toString()),
        loading: () =>
            const LoadingWidget(message: 'Chargement des membres...'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createOrJoinFamily),
        icon: const Icon(Icons.group_add),
        label: const Text('Invitation'),
      ),
    );
  }
}
