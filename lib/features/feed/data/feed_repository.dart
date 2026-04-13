import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/models/comment_model.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/storage_service.dart';

class FeedRepository {
  FeedRepository(this._firestore, this._storageService);

  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  Stream<List<PostModel>> watchFamilyPosts(String familyId) {
    return _firestore
        .collection(FirestorePaths.posts)
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<PostModel?> watchPost(String postId) {
    return _firestore
        .collection(FirestorePaths.posts)
        .doc(postId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return PostModel.fromMap(doc.data()!);
        });
  }

  Future<void> createPost({
    required String familyId,
    required UserModel author,
    required String text,
    File? image,
    File? video,
    void Function(double progress)? onUploadProgress,
  }) async {
    final postRef = _firestore.collection(FirestorePaths.posts).doc();

    String? imageUrl;
    if (image != null) {
      imageUrl = await _storageService.uploadFile(
        file: image,
        path: 'posts/$familyId/${postRef.id}.jpg',
        contentType: 'image/jpeg',
        onProgress: onUploadProgress,
      );
    }

    String? videoUrl;
    String? videoThumbnailUrl;
    if (video != null) {
      final extension = _extractExtension(video.path, fallback: 'mp4');
      final videoContentType = _videoContentType(extension);
      videoUrl = await _storageService.uploadFile(
        file: video,
        path: 'posts/$familyId/${postRef.id}.$extension',
        contentType: videoContentType,
        onProgress: onUploadProgress == null
            ? null
            : (progress) => onUploadProgress(progress * 0.9),
      );

      final thumbnailFile = await _generateVideoThumbnail(video.path);
      if (thumbnailFile != null) {
        try {
          videoThumbnailUrl = await _storageService.uploadFile(
            file: thumbnailFile,
            path: 'posts/$familyId/${postRef.id}_thumb.jpg',
            contentType: 'image/jpeg',
            onProgress: onUploadProgress == null
                ? null
                : (progress) => onUploadProgress(0.9 + (progress * 0.1)),
          );
        } finally {
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        }
      }
    }

    onUploadProgress?.call(1);

    final post = PostModel(
      id: postRef.id,
      familyId: familyId,
      authorId: author.id,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      text: text.trim().isEmpty ? null : text.trim(),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      videoThumbnailUrl: videoThumbnailUrl,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
    );

    await postRef.set(post.toMap());
  }

  String _extractExtension(String path, {required String fallback}) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return fallback;
    final ext = path.substring(dotIndex + 1).toLowerCase();
    return ext.isEmpty ? fallback : ext;
  }

  String _videoContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'mov':
        return 'video/quicktime';
      case '3gp':
        return 'video/3gpp';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        quality: 70,
        maxWidth: 720,
      );
      if (thumbnailPath == null || thumbnailPath.isEmpty) return null;
      return File(thumbnailPath);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postRef = _firestore.collection(FirestorePaths.posts).doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final postDoc = await transaction.get(postRef);
      final postData = postDoc.data() ?? {};
      final currentCount = (postData['likeCount'] ?? 0) as int;

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likeCount': (currentCount - 1).clamp(0, 999999),
        });
      } else {
        transaction.set(likeRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likeCount': currentCount + 1});
      }
    });
  }

  Stream<List<CommentModel>> watchComments(String postId) {
    return _firestore
        .collection(FirestorePaths.comments)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> addComment({
    required String postId,
    required UserModel author,
    required String text,
  }) async {
    final commentRef = _firestore.collection(FirestorePaths.comments).doc();
    final postRef = _firestore.collection(FirestorePaths.posts).doc(postId);

    final comment = CommentModel(
      id: commentRef.id,
      postId: postId,
      authorId: author.id,
      authorName: author.displayName,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(commentRef, comment.toMap());
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> updatePostText({
    required String postId,
    required String text,
  }) async {
    await _firestore.collection(FirestorePaths.posts).doc(postId).update({
      'text': text.trim().isEmpty ? null : text.trim(),
    });
  }

  Future<void> removePostMedia({
    required PostModel post,
    required String mediaType,
  }) async {
    final updates = <String, dynamic>{};
    final urlsToDelete = <String>[];

    if (mediaType == 'image') {
      if ((post.imageUrl ?? '').isNotEmpty) {
        updates['imageUrl'] = null;
        urlsToDelete.add(post.imageUrl!);
      }
    } else if (mediaType == 'video') {
      if ((post.videoUrl ?? '').isNotEmpty) {
        updates['videoUrl'] = null;
        urlsToDelete.add(post.videoUrl!);
      }
      if ((post.videoThumbnailUrl ?? '').isNotEmpty) {
        updates['videoThumbnailUrl'] = null;
        urlsToDelete.add(post.videoThumbnailUrl!);
      }
    }

    if (updates.isEmpty) return;

    await _firestore.collection(FirestorePaths.posts).doc(post.id).update(
      updates,
    );

    for (final url in urlsToDelete) {
      try {
        await _storageService.deleteFileByUrl(url);
      } catch (_) {
        // Ignore media cleanup failures after post update.
      }
    }
  }

  Future<void> deletePost(String postId) async {
    final postRef = _firestore.collection(FirestorePaths.posts).doc(postId);
    final postDoc = await postRef.get();
    if (!postDoc.exists || postDoc.data() == null) return;

    final post = PostModel.fromMap(postDoc.data()!);

    final commentsSnapshot = await _firestore
        .collection(FirestorePaths.comments)
        .where('postId', isEqualTo: postId)
        .get();
    await _deleteDocsInBatches(
      commentsSnapshot.docs.map((doc) => doc.reference).toList(),
    );

    final likesSnapshot = await postRef.collection('likes').get();
    await _deleteDocsInBatches(
      likesSnapshot.docs.map((doc) => doc.reference).toList(),
    );

    await postRef.delete();

    final mediaUrls = [
      post.imageUrl,
      post.videoUrl,
      post.videoThumbnailUrl,
    ].whereType<String>().toList();
    for (final url in mediaUrls) {
      try {
        await _storageService.deleteFileByUrl(url);
      } catch (_) {
        // Ignore media cleanup failures after post deletion.
      }
    }
  }

  Future<void> _deleteDocsInBatches(List<DocumentReference> refs) async {
    const batchSize = 400;
    if (refs.isEmpty) return;

    for (var i = 0; i < refs.length; i += batchSize) {
      final end = (i + batchSize < refs.length) ? i + batchSize : refs.length;
      final batch = _firestore.batch();
      for (final ref in refs.sublist(i, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
