import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/models/family_model.dart';
import '../../../shared/models/user_model.dart';

class FamilyRepository {
  FamilyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> createFamily({
    required String name,
    required UserModel user,
  }) async {
    final familyRef = _firestore.collection(FirestorePaths.families).doc();
    final code = _generateInviteCode();

    final family = FamilyModel(
      id: familyRef.id,
      name: name.trim(),
      inviteCode: code,
      createdBy: user.id,
      createdAt: DateTime.now(),
      membersCount: 1,
    );

    final batch = _firestore.batch();
    batch.set(familyRef, family.toMap());
    batch.set(
      _firestore.collection(FirestorePaths.users).doc(user.id),
      {
        'id': user.id,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'familyId': familyRef.id,
        'role': 'admin',
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> joinFamily({
    required String inviteCode,
    required UserModel user,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    final familyQuery = await _firestore
        .collection(FirestorePaths.families)
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (familyQuery.docs.isEmpty) {
      throw Exception('Code famille invalide');
    }

    final familyDoc = familyQuery.docs.first;
    final batch = _firestore.batch();

    batch.update(familyDoc.reference, {
      'membersCount': FieldValue.increment(1),
    });

    batch.set(
      _firestore.collection(FirestorePaths.users).doc(user.id),
      {
        'id': user.id,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'familyId': familyDoc.id,
        'role': 'member',
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Stream<FamilyModel?> watchFamily(String familyId) {
    return _firestore
        .collection(FirestorePaths.families)
        .doc(familyId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return FamilyModel.fromMap(doc.data()!);
        });
  }

  Stream<List<UserModel>> watchFamilyMembers(String familyId) {
    return _firestore
        .collection(FirestorePaths.users)
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }
}
