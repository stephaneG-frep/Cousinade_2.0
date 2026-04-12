import 'package:flutter/material.dart';

import '../../core/utils/date_formatter.dart';
import '../models/post_model.dart';
import 'app_avatar.dart';
import 'app_card.dart';
import 'app_network_video.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.playVideo = false,
    this.isNew = false,
    this.headerTrailing,
  });

  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final bool playVideo;
  final bool isNew;
  final Widget? headerTrailing;

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
              if (headerTrailing != null) ...[
                const SizedBox(width: 6),
                headerTrailing!,
              ],
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nouveau',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
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
          if ((post.videoUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: playVideo
                  ? AppNetworkVideo(
                      url: post.videoUrl!,
                      thumbnailUrl: post.videoThumbnailUrl,
                      enableFullscreen: true,
                    )
                  : AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          if ((post.videoThumbnailUrl ?? '').isNotEmpty)
                            Image.network(
                              post.videoThumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.black12,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.videocam_outlined),
                                  ),
                            )
                          else
                            Container(
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Icon(Icons.videocam_outlined),
                            ),
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(27),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
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
