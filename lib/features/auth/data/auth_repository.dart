import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService, this._firestore);

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _authService.authStateChanges();

  User? get currentAuthUser => _authService.currentUser;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.registerWithEmailPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Compte introuvable',
      );
    }

    final userModel = UserModel(
      id: user.uid,
      role: 'member',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      displayName: '${firstName.trim()} ${lastName.trim()}'.trim(),
      email: email.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .set(userModel.toMap());
  }

  Future<void> login({required String email, required String password}) {
    return _authService.loginWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) {
    return _authService.sendPasswordResetEmail(email.trim());
  }

  Future<void> logout() => _authService.logout();

  Stream<UserModel?> watchUserProfile(String userId) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromMap(doc.data()!);
        });
  }

  Future<void> updateUserFamily({
    required String userId,
    required String familyId,
    required String role,
  }) {
    return _firestore.collection(FirestorePaths.users).doc(userId).update({
      'familyId': familyId,
      'role': role,
    });
  }
}
