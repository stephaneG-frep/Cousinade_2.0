import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/storage_service.dart';

class ProfileRepository {
  ProfileRepository(this._firestore, this._storageService);

  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromMap(doc.data()!);
        });
  }

  Future<void> updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String bio,
    File? avatar,
  }) async {
    await _firestore.collection(FirestorePaths.users).doc(userId).set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'displayName': '${firstName.trim()} ${lastName.trim()}'.trim(),
      'bio': bio.trim(),
    }, SetOptions(merge: true));

    if (avatar == null) return;

    try {
      final avatarUrl = await _storageService.uploadFile(
        file: avatar,
        path: 'avatars/$userId.jpg',
        contentType: 'image/jpeg',
      );
      await _firestore.collection(FirestorePaths.users).doc(userId).set({
        'avatarUrl': avatarUrl,
      }, SetOptions(merge: true));

      // Propagate the new avatar to existing posts — best effort, non-blocking.
      _updateAuthorAvatarInPosts(userId: userId, avatarUrl: avatarUrl)
          .catchError((_) {});
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'unknown') {
        throw Exception(
          'Photo non envoyee: active Firebase Storage dans Firebase Console (Storage > Get Started).',
        );
      }
      throw Exception(e.message ?? 'Echec upload photo');
    }
  }

  Future<void> _updateAuthorAvatarInPosts({
    required String userId,
    required String avatarUrl,
  }) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.posts)
        .where('authorId', isEqualTo: userId)
        .get();
    if (snapshot.docs.isEmpty) return;

    const batchSize = 400;
    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final end = (i + batchSize < snapshot.docs.length)
          ? i + batchSize
          : snapshot.docs.length;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs.sublist(i, end)) {
        batch.update(doc.reference, {'authorAvatar': avatarUrl});
      }
      await batch.commit();
    }
  }

  Future<void> updatePresence({
    required String userId,
    required bool isOnline,
  }) async {
    await _firestore.collection(FirestorePaths.users).doc(userId).set({
      'isOnline': isOnline,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
