import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/post_card.dart';
import '../providers/feed_providers.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final message = _commentController.text;
    final error = await ref
        .read(feedControllerProvider.notifier)
        .addComment(postId: widget.postId, text: message);

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _commentController.clear();
  }

  Future<void> _editPost(PostModel post) async {
    var draftText = post.text ?? '';
    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier la publication'),
          content: TextFormField(
            initialValue: draftText,
            onChanged: (value) => draftText = value,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Ton message...'),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              Navigator.of(context).pop(draftText);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draftText),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (newText == null) return;

    final error = await ref
        .read(feedControllerProvider.notifier)
        .updatePostText(post: post, text: newText);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Publication mise a jour')));
  }

  Future<void> _deletePost(PostModel post) async {
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

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Publication supprimee')));
  }

  Future<void> _removeMedia(PostModel post, String mediaType) async {
    final label = mediaType == 'image' ? 'photo' : 'video';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Supprimer la $label'),
          content: const Text('Le media sera supprime de la publication.'),
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
        .removePostMedia(post: post, mediaType: mediaType);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Media supprime')));
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;
    final post = postAsync.valueOrNull;
    final isOwner = post != null && currentUser?.id == post.authorId;
    final isAdmin = currentUser?.role == 'admin';
    final canManage = post != null && (isOwner || isAdmin);
    final managedPost = canManage ? post : null;
    final hasVideo = (post?.videoUrl ?? '').isNotEmpty;
    final hasImage = (post?.imageUrl ?? '').isNotEmpty;
    final topSectionFlex = hasVideo ? 7 : 4;
    final commentsSectionFlex = hasVideo ? 3 : 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication'),
        actions: [
          if (managedPost != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  if (isOwner) {
                    await _editPost(managedPost);
                  }
                } else if (value == 'remove_image') {
                  await _removeMedia(managedPost, 'image');
                } else if (value == 'remove_video') {
                  await _removeMedia(managedPost, 'video');
                } else if (value == 'delete') {
                  await _deletePost(managedPost);
                }
              },
              itemBuilder: (context) => [
                if (isOwner)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Modifier'),
                  ),
                if (hasImage)
                  const PopupMenuItem<String>(
                    value: 'remove_image',
                    child: Text('Supprimer la photo'),
                  ),
                if (hasVideo)
                  const PopupMenuItem<String>(
                    value: 'remove_video',
                    child: Text('Supprimer la video'),
                  ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Supprimer'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: topSectionFlex,
            child: postAsync.when(
              data: (post) {
                if (post == null) return const SizedBox.shrink();
                return SingleChildScrollView(
                  child: PostCard(
                    post: post,
                    playVideo: true,
                    onLike: () => ref
                        .read(feedControllerProvider.notifier)
                        .toggleLike(post),
                  ),
                );
              },
              error: (error, _) => ErrorStateWidget(message: error.toString()),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LoadingWidget(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: commentsSectionFlex,
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('Aucun commentaire pour le moment'),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      title: Text(comment.authorName),
                      subtitle: Text(comment.text),
                    );
                  },
                );
              },
              error: (error, _) => ErrorStateWidget(message: error.toString()),
              loading: () => const LoadingWidget(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
