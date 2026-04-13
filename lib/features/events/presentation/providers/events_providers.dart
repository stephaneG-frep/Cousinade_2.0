import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/event_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(firestoreProvider));
});

final familyEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value([]);

  final userAsync = ref.watch(currentUserProfileProvider);
  if (userAsync.isLoading) {
    final controller = StreamController<List<EventModel>>();
    ref.onDispose(controller.close);
    return controller.stream;
  }

  final user = userAsync.valueOrNull;
  if (user == null || !user.hasFamily) return Stream.value([]);
  return ref.watch(eventsRepositoryProvider).watchFamilyEvents(user.familyId!);
});

final eventDetailProvider = StreamProvider.family<EventModel?, String>((
  ref,
  eventId,
) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value(null);
  return ref.watch(eventsRepositoryProvider).watchEvent(eventId);
});

final eventsControllerProvider = AsyncNotifierProvider<EventsController, void>(
  EventsController.new,
);

class EventsController extends AsyncNotifier<void> {
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
    return user;
  }

  Future<String?> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _resolveCurrentUser();
      if (!user.hasFamily) {
        state = const AsyncData(null);
        return 'Famille introuvable';
      }
      await ref
          .read(eventsRepositoryProvider)
          .createEvent(
            familyId: user.familyId!,
            title: title,
            description: description,
            location: location,
            startDate: startDate,
            createdBy: user.id,
          );
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> deleteEvent(EventModel event) async {
    try {
      final user = await _resolveCurrentUser();
      final isAdmin = user.role == 'admin';
      if (user.id != event.createdBy && !isAdmin) {
        return 'Tu ne peux supprimer que tes evenements';
      }

      state = const AsyncLoading();
      await ref.read(eventsRepositoryProvider).deleteEvent(event.id);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
