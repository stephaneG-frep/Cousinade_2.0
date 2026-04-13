import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/one_time_tip_card.dart';
import '../../../../shared/widgets/help_action.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../family/presentation/providers/family_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/chat_providers.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: const [HelpAction()],
      ),
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

          final members =
              membersAsync.valueOrNull ?? const [];
          final memberMap = {
            for (final member in members) member.id: member,
          };

          final filteredConversations = _query.isEmpty
              ? conversations
              : conversations.where((conversation) {
                  final messageMatch = conversation.lastMessage
                      .toLowerCase()
                      .contains(_query.toLowerCase());
                  if (messageMatch) return true;
                  if (currentUser == null) return false;
                  final otherUserId = conversation.participantIds.firstWhere(
                    (id) => id != currentUser.id,
                    orElse: () =>
                        conversation.participantIds.isNotEmpty
                            ? conversation.participantIds.first
                            : '',
                  );
                  if (otherUserId.isEmpty) return false;
                  final otherUser = memberMap[otherUserId];
                  if (otherUser == null) return false;
                  return otherUser.displayName
                      .toLowerCase()
                      .contains(_query.toLowerCase());
                }).toList();

          if (filteredConversations.isEmpty) {
            return EmptyStateWidget(
              title: 'Aucun resultat',
              subtitle: 'Essaie un autre prenom ou message.',
              icon: Icons.search_off_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(conversationsProvider.future),
            child: ListView.builder(
              itemCount: filteredConversations.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const OneTimeTipCard(
                    storageKey: 'tip_messages',
                    title: 'Messages',
                    message:
                        'Chaque conversation est privee avec un membre de ta famille.',
                    icon: Icons.chat_bubble_outline,
                  );
                }
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une conversation...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  );
                }
                final conversation = filteredConversations[index - 2];
                return _ConversationTile(
                  conversationId: conversation.id,
                  lastMessage: conversation.lastMessage,
                  participantIds: conversation.participantIds,
                  query: _query,
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
    required this.query,
  });

  final String conversationId;
  final String lastMessage;
  final List<String> participantIds;
  final String query;

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
        if (query.isNotEmpty) {
          final haystack = '${user?.displayName ?? ''} $lastMessage'
              .toLowerCase();
          if (!haystack.contains(query.toLowerCase())) {
            return const SizedBox.shrink();
          }
        }
        final isOnline = user?.isOnlineNow == true;
        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                initial: user?.displayName ?? 'M',
                imageUrl: user?.avatarUrl,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.greenAccent.shade400 : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
