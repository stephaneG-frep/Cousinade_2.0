import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/post_card.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/feed_providers.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(familyPostsProvider);
    final totalUnread = ref.watch(totalUnreadMessagesProvider);
    final hasUnread = totalUnread > 0;
    final unreadLabel = totalUnread > 99 ? '99+' : '$totalUnread';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.conversations),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (hasUnread)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        unreadLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Messages',
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucune publication',
              subtitle: 'Publie un premier message pour lancer la discussion.',
              icon: Icons.dynamic_feed_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(familyPostsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  post: post,
                  onTap: () => context.push(AppRoutes.postDetailPath(post.id)),
                  onLike: () => ref
                      .read(feedControllerProvider.notifier)
                      .toggleLike(post),
                );
              },
            ),
          );
        },
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(familyPostsProvider),
        ),
        loading: () => const LoadingWidget(message: 'Chargement du fil...'),
      ),
    );
  }
}
