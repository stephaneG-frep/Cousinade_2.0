import 'package:flutter/material.dart';

import '../../core/utils/date_formatter.dart';
import '../models/post_model.dart';
import 'app_avatar.dart';
import 'app_card.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onTap, this.onLike});

  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(initial: post.authorName, imageUrl: post.authorAvatar),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      DateFormatter.shortDateTime(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((post.text ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.text!),
          ],
          if ((post.imageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: onLike,
                icon: const Icon(Icons.favorite_border),
              ),
              Text('${post.likeCount}'),
              const SizedBox(width: 12),
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 4),
              Text('${post.commentCount}'),
            ],
          ),
        ],
      ),
    );
  }
}
