import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/conversation_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final conversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null || !user.hasFamily) return Stream.value([]);

  return ref
      .watch(chatRepositoryProvider)
      .watchConversations(familyId: user.familyId!, userId: user.id);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  conversationId,
) {
  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user != null) {
    ref
        .read(chatRepositoryProvider)
        .markAsRead(conversationId: conversationId, currentUserId: user.id);
  }
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

final chatControllerProvider = AsyncNotifierProvider<ChatController, void>(
  ChatController.new,
);

class ChatController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> startConversationWith(String otherUserId) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null || !user.hasFamily) return null;

    try {
      return await ref
          .read(chatRepositoryProvider)
          .createOrGetConversation(
            familyId: user.familyId!,
            currentUserId: user.id,
            otherUserId: otherUserId,
          );
    } catch (_) {
      return null;
    }
  }

  Future<String?> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return 'Utilisateur introuvable';
    if (text.trim().isEmpty) return 'Message vide';

    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId: conversationId,
            senderId: user.id,
            text: text,
          );
      return null;
    } catch (_) {
      return 'Envoi impossible';
    }
  }
}
