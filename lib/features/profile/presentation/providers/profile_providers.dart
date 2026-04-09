import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/notification_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/notifications_repository.dart';
import '../../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(firestoreProvider),
    StorageService(ref.watch(firebaseStorageProvider)),
  );
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.watch(firestoreProvider));
});

final userByIdProvider = StreamProvider.family<UserModel?, String>((
  ref,
  userId,
) {
  return ref.watch(profileRepositoryProvider).watchUser(userId);
});

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(notificationsRepositoryProvider)
      .watchUserNotifications(user.id);
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
    File? avatar,
  }) async {
    final current = ref.read(currentUserProfileProvider).valueOrNull;
    if (current == null) return 'Utilisateur introuvable';

    state = const AsyncLoading();
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            userId: current.id,
            firstName: firstName,
            lastName: lastName,
            bio: bio,
            avatar: avatar,
          );
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Mise a jour impossible';
    }
  }

  Future<void> markNotificationRead(String notificationId) {
    return ref.read(notificationsRepositoryProvider).markAsRead(notificationId);
  }
}
