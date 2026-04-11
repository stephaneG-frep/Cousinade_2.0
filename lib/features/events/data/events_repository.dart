import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/models/event_model.dart';

class EventsRepository {
  EventsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<EventModel>> watchFamilyEvents(String familyId) {
    return _firestore
        .collection(FirestorePaths.events)
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data()))
              .toList();
          events.sort((a, b) => a.startDate.compareTo(b.startDate));
          return events;
        });
  }

  Stream<EventModel?> watchEvent(String eventId) {
    return _firestore
        .collection(FirestorePaths.events)
        .doc(eventId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return EventModel.fromMap(doc.data()!);
        });
  }

  Future<void> createEvent({
    required String familyId,
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required String createdBy,
  }) async {
    final eventRef = _firestore.collection(FirestorePaths.events).doc();

    final event = EventModel(
      id: eventRef.id,
      familyId: familyId,
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      startDate: startDate,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await eventRef.set(event.toMap());
  }
}
