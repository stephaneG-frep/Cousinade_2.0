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
    String? avatarUrl;
    if (avatar != null) {
      avatarUrl = await _storageService.uploadFile(
        file: avatar,
        path: 'avatars/$userId.jpg',
      );
    }

    await _firestore.collection(FirestorePaths.users).doc(userId).update({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'displayName': '${firstName.trim()} ${lastName.trim()}'.trim(),
      'bio': bio.trim(),
      if (avatarUrl case final String value) 'avatarUrl': value,
    });
  }
}
