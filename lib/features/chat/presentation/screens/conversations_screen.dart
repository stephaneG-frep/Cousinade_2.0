import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/chat_providers.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return EmptyStateWidget(
              title: 'Aucune conversation',
              subtitle: 'Discute avec les membres de ta famille.',
              icon: Icons.chat_bubble_outline,
              action: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.family),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Voir ma famille'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(conversationsProvider.future),
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(
                  conversationId: conversation.id,
                  lastMessage: conversation.lastMessage,
                  participantIds: conversation.participantIds,
                );
              },
            ),
          );
        },
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        loading: () =>
            const LoadingWidget(message: 'Chargement des conversations...'),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversationId,
    required this.lastMessage,
    required this.participantIds,
  });

  final String conversationId;
  final String lastMessage;
  final List<String> participantIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;
    final unreadCountAsync = ref.watch(
      conversationUnreadCountProvider(conversationId),
    );
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final hasUnread = unreadCount > 0;
    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUser?.id,
      orElse: () => participantIds.isNotEmpty ? participantIds.first : '',
    );

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    final userAsync = ref.watch(userByIdProvider(otherUserId));

    return userAsync.when(
      data: (user) {
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(
            user?.displayName ?? 'Membre',
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            lastMessage.isEmpty ? 'Commencer la discussion...' : lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: hasUnread
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          minVerticalPadding: 8,
          onTap: () => context.push(AppRoutes.chatPath(conversationId)),
        );
      },
      error: (error, stackTrace) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: const Text('Membre'),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hasUnread
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        onTap: () => context.push(AppRoutes.chatPath(conversationId)),
      ),
      loading: () => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: const Text('Chargement...'),
        subtitle: Text(
          lastMessage.isEmpty ? 'Commencer la discussion...' : lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hasUnread
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        onTap: () => context.push(AppRoutes.chatPath(conversationId)),
      ),
    );
  }
}
