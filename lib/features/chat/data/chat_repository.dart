import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/models/conversation_model.dart';
import '../../../shared/models/message_model.dart';

class ChatRepository {
  ChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<ConversationModel>> watchConversations({
    required String familyId,
    required String userId,
  }) {
    return _firestore
        .collection(FirestorePaths.conversations)
        .where('familyId', isEqualTo: familyId)
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _firestore
        .collection(FirestorePaths.messages)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<String> createOrGetConversation({
    required String familyId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final query = await _firestore
        .collection(FirestorePaths.conversations)
        .where('familyId', isEqualTo: familyId)
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (final doc in query.docs) {
      final model = ConversationModel.fromMap(doc.data());
      if (model.participantIds.contains(otherUserId)) {
        return model.id;
      }
    }

    final conversationRef = _firestore
        .collection(FirestorePaths.conversations)
        .doc();
    final conversation = ConversationModel(
      id: conversationRef.id,
      familyId: familyId,
      participantIds: [currentUserId, otherUserId],
      lastMessage: '',
      lastMessageAt: DateTime.now(),
    );

    await conversationRef.set(conversation.toMap());
    return conversationRef.id;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final messageRef = _firestore.collection(FirestorePaths.messages).doc();

    final message = MessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: senderId,
      text: text.trim(),
      createdAt: DateTime.now(),
      isRead: false,
    );

    final batch = _firestore.batch();
    batch.set(messageRef, message.toMap());
    batch.update(
      _firestore.collection(FirestorePaths.conversations).doc(conversationId),
      {
        'lastMessage': text.trim(),
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
      },
    );

    await batch.commit();
  }

  Future<void> markAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    final query = await _firestore
        .collection(FirestorePaths.messages)
        .where('conversationId', isEqualTo: conversationId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      if ((doc.data()['senderId'] as String?) != currentUserId) {
        batch.update(doc.reference, {'isRead': true});
      }
    }

    await batch.commit();
  }
}
