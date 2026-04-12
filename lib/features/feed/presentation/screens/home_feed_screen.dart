import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/last_seen_service.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/one_time_tip_card.dart';
import '../../../../shared/widgets/post_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/feed_providers.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  DateTime? _lastSeen;
  List<PostModel> _cachedPosts = const [];

  @override
  void initState() {
    super.initState();
    _loadLastSeen();
  }

  Future<void> _loadLastSeen() async {
    final lastSeen = await LastSeenService.getLastSeen(LastSeenService.feedKey);
    if (!mounted) return;
    setState(() {
      _lastSeen = lastSeen;
    });
    await LastSeenService.setLastSeen(LastSeenService.feedKey, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(familyPostsProvider);
    final totalUnread = ref.watch(totalUnreadMessagesProvider);
    final hasUnread = totalUnread > 0;
    final unreadLabel = totalUnread > 99 ? '99+' : '$totalUnread';
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;

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
          _cachedPosts = posts;
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
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const OneTimeTipCard(
                    storageKey: 'tip_home_feed',
                    title: 'Fil de famille',
                    message:
                        'Ici tu vois toutes les nouvelles publications. '
                        'Appuie sur une publication pour lire et commenter.',
                    icon: Icons.dynamic_feed_outlined,
                  );
                }

                final post = posts[index - 1];
                final isNew =
                    _lastSeen != null && post.createdAt.isAfter(_lastSeen!);
                return PostCard(
                  post: post,
                  isNew: isNew,
                  onTap: () => context.push(AppRoutes.postDetailPath(post.id)),
                  onLike: () => ref
                      .read(feedControllerProvider.notifier)
                      .toggleLike(post),
                  headerTrailing: _buildPostMenu(context, post, currentUser),
                );
              },
            ),
          );
        },
        error: (error, _) {
          if (_cachedPosts.isNotEmpty) {
            final posts = _cachedPosts;
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(familyPostsProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const OneTimeTipCard(
                      storageKey: 'tip_home_feed',
                      title: 'Fil de famille',
                      message:
                          'Ici tu vois toutes les nouvelles publications. '
                          'Appuie sur une publication pour lire et commenter.',
                      icon: Icons.dynamic_feed_outlined,
                    );
                  }

                  final post = posts[index - 1];
                  final isNew = _lastSeen != null &&
                      post.createdAt.isAfter(_lastSeen!);
                  return PostCard(
                    post: post,
                    isNew: isNew,
                    onTap: () =>
                        context.push(AppRoutes.postDetailPath(post.id)),
                    onLike: () => ref
                        .read(feedControllerProvider.notifier)
                        .toggleLike(post),
                    headerTrailing: _buildPostMenu(context, post, currentUser),
                  );
                },
              ),
            );
          }
          return ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(familyPostsProvider),
          );
        },
        loading: () {
          if (_cachedPosts.isNotEmpty) {
            final posts = _cachedPosts;
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(familyPostsProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const OneTimeTipCard(
                      storageKey: 'tip_home_feed',
                      title: 'Fil de famille',
                      message:
                          'Ici tu vois toutes les nouvelles publications. '
                          'Appuie sur une publication pour lire et commenter.',
                      icon: Icons.dynamic_feed_outlined,
                    );
                  }

                  final post = posts[index - 1];
                  final isNew = _lastSeen != null &&
                      post.createdAt.isAfter(_lastSeen!);
                  return PostCard(
                    post: post,
                    isNew: isNew,
                    onTap: () =>
                        context.push(AppRoutes.postDetailPath(post.id)),
                    onLike: () => ref
                        .read(feedControllerProvider.notifier)
                        .toggleLike(post),
                    headerTrailing: _buildPostMenu(context, post, currentUser),
                  );
                },
              ),
            );
          }
          return const LoadingWidget(message: 'Chargement du fil...');
        },
      ),
    );
  }

  Widget? _buildPostMenu(
    BuildContext context,
    PostModel post,
    UserModel? currentUser,
  ) {
    final isOwner = currentUser?.id == post.authorId;
    final isAdmin = currentUser?.role == 'admin';
    if (!isOwner && !isAdmin) return null;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'delete') {
          await _deletePost(context, post);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(value: 'delete', child: Text('Supprimer')),
      ],
    );
  }

  Future<void> _deletePost(BuildContext context, PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la publication'),
          content: const Text(
            'Cette action est definitive. Les commentaires seront supprimes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final error = await ref
        .read(feedControllerProvider.notifier)
        .deletePost(post);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Publication supprimee')));
  }
}
