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
  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null || !user.hasFamily) {
    return Stream.value(null);
  }
  return ref.watch(familyRepositoryProvider).watchFamily(user.familyId!);
});

final familyMembersProvider = StreamProvider<List<UserModel>>((ref) {
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

  Future<String?> createFamily(String name) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return 'Utilisateur introuvable';

    state = const AsyncLoading();
    try {
      await ref
          .read(familyRepositoryProvider)
          .createFamily(name: name, user: user);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Creation de famille impossible';
    }
  }

  Future<String?> joinFamily(String code) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return 'Utilisateur introuvable';

    state = const AsyncLoading();
    try {
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
}
