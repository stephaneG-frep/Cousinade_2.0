import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/event_model.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(firestoreProvider));
});

final familyEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null || !user.hasFamily) return Stream.value([]);
  return ref.watch(eventsRepositoryProvider).watchFamilyEvents(user.familyId!);
});

final eventDetailProvider = StreamProvider.family<EventModel?, String>((
  ref,
  eventId,
) {
  return ref.watch(eventsRepositoryProvider).watchEvent(eventId);
});

final eventsControllerProvider = AsyncNotifierProvider<EventsController, void>(
  EventsController.new,
);

class EventsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
  }) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null || !user.hasFamily) return 'Famille introuvable';

    state = const AsyncLoading();
    try {
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
      return 'Creation d\'evenement impossible';
    }
  }
}
