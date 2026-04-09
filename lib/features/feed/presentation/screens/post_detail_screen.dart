import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Publication')),
      body: Column(
        children: [
          postAsync.when(
            data: (post) {
              if (post == null) return const SizedBox.shrink();
              return PostCard(
                post: post,
                onLike: () =>
                    ref.read(feedControllerProvider.notifier).toggleLike(post),
              );
            },
            error: (error, _) => ErrorStateWidget(message: error.toString()),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingWidget(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
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
