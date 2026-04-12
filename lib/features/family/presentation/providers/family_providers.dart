import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/family_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/family_repository.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(firestoreProvider));
});

final currentFamilyProvider = StreamProvider<FamilyModel?>((ref) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) {
    return Stream.value(null);
  }

  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null || !user.hasFamily) {
    return Stream.value(null);
  }
  return ref.watch(familyRepositoryProvider).watchFamily(user.familyId!);
});

final familyMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) {
    return Stream.value([]);
  }

  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null || !user.hasFamily) {
    return Stream.value([]);
  }
  return ref.watch(familyRepositoryProvider).watchFamilyMembers(user.familyId!);
});

final familyControllerProvider = AsyncNotifierProvider<FamilyController, void>(
  FamilyController.new,
);

class FamilyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<UserModel> _resolveCurrentUser() async {
    var user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user != null) return user;

    final authRepository = ref.read(authRepositoryProvider);
    final firebaseUser =
        ref.read(currentFirebaseUserProvider) ?? authRepository.currentAuthUser;
    if (firebaseUser == null) {
      throw Exception('Session utilisateur introuvable');
    }

    user = await authRepository.ensureUserProfileForAuthUser(firebaseUser);
    ref.invalidate(currentUserProfileProvider);
    return user;
  }

  Future<String?> createFamily(String name) async {
    state = const AsyncLoading();
    try {
      final user = await _resolveCurrentUser();
      await ref
          .read(familyRepositoryProvider)
          .createFamily(name: name, user: user);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> joinFamily(String code) async {
    state = const AsyncLoading();
    try {
      final user = await _resolveCurrentUser();
      await ref
          .read(familyRepositoryProvider)
          .joinFamily(inviteCode: code, user: user);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> autoJoinDefaultFamily() async {
    state = const AsyncLoading();
    try {
      final user = await _resolveCurrentUser();
      await ref
          .read(familyRepositoryProvider)
          .autoJoinDefaultFamily(user: user);
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(currentFamilyProvider);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> removeMember(String memberId) async {
    state = const AsyncLoading();
    try {
      final admin = await _resolveCurrentUser();
      if (admin.role != 'admin') {
        state = const AsyncData(null);
        return 'Acces reserve aux administrateurs';
      }
      if (admin.id == memberId) {
        state = const AsyncData(null);
        return 'Impossible de se retirer soi-meme';
      }
      if (!admin.hasFamily) {
        state = const AsyncData(null);
        return 'Famille introuvable';
      }
      await ref
          .read(familyRepositoryProvider)
          .removeMember(familyId: admin.familyId!, memberId: memberId);
      ref.invalidate(familyMembersProvider);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      final admin = await _resolveCurrentUser();
      if (admin.role != 'admin') {
        state = const AsyncData(null);
        return 'Acces reserve aux administrateurs';
      }
      if (admin.id == memberId && role != 'admin') {
        state = const AsyncData(null);
        return 'Impossible de retirer ton propre role admin';
      }
      await ref
          .read(familyRepositoryProvider)
          .updateMemberRole(memberId: memberId, role: role);
      ref.invalidate(familyMembersProvider);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
