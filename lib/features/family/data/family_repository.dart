import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/models/family_model.dart';
import '../../../shared/models/user_model.dart';

class FamilyRepository {
  FamilyRepository(this._firestore);

  final FirebaseFirestore _firestore;
  static const String _primaryFamilyId = 'primary';

  Future<int> _countAdmins() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.users)
        .where('familyId', isEqualTo: _primaryFamilyId)
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    return snapshot.docs.length;
  }

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
          (snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            if ((data['id'] as String? ?? '').isEmpty) data['id'] = doc.id;
            return UserModel.fromMap(data);
          }).toList(),
        );
  }

  Future<void> removeMember({
    required String familyId,
    required String memberId,
  }) async {
    final familyRef = _firestore
        .collection(FirestorePaths.families)
        .doc(familyId);
    final userRef = _firestore.collection(FirestorePaths.users).doc(memberId);

    final batch = _firestore.batch();
    batch.update(familyRef, {'membersCount': FieldValue.increment(-1)});
    batch.set(userRef, {
      'familyId': null,
      'role': 'member',
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    final userRef = _firestore.collection(FirestorePaths.users).doc(memberId);
    await userRef.set({'role': role}, SetOptions(merge: true));
  }

  Future<String> autoJoinDefaultFamily({
    required UserModel user,
    String? defaultFamilyName,
  }) async {
    final familyRef = _firestore
        .collection(FirestorePaths.families)
        .doc(_primaryFamilyId);
    final familyDoc = await familyRef.get();

    if (!familyDoc.exists) {
      final code = _generateInviteCode();
      final family = FamilyModel(
        id: _primaryFamilyId,
        name: (defaultFamilyName ?? 'Famille Cousinade').trim(),
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
          'familyId': _primaryFamilyId,
          'role': 'admin',
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      return _primaryFamilyId;
    }

    final familyData = familyDoc.data() ?? {};
    final createdBy = (familyData['createdBy'] ?? '') as String;
    var role = createdBy == user.id ? 'admin' : 'member';

    if (role != 'admin') {
      final admins = await _countAdmins();
      if (admins == 0) {
        role = 'admin';
        await familyRef.set({'createdBy': user.id}, SetOptions(merge: true));
      }
    }

    final batch = _firestore.batch();
    if (user.familyId != _primaryFamilyId) {
      batch.update(familyRef, {
        'membersCount': FieldValue.increment(1),
      });
    }
    batch.set(
      _firestore.collection(FirestorePaths.users).doc(user.id),
      {
        'id': user.id,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'familyId': _primaryFamilyId,
        'role': role,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    return _primaryFamilyId;
  }
}
