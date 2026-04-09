import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

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
  }) async {
    final postRef = _firestore.collection(FirestorePaths.posts).doc();

    String? imageUrl;
    if (image != null) {
      imageUrl = await _storageService.uploadFile(
        file: image,
        path: 'posts/$familyId/${postRef.id}.jpg',
      );
    }

    final post = PostModel(
      id: postRef.id,
      familyId: familyId,
      authorId: author.id,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      text: text.trim().isEmpty ? null : text.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
    );

    await postRef.set(post.toMap());
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
}
