import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/conversation_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final conversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value([]);

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
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value([]);

  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user != null) {
    ref
        .read(chatRepositoryProvider)
        .markAsRead(conversationId: conversationId, currentUserId: user.id);
  }
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

final conversationUnreadCountProvider = StreamProvider.family<int, String>((
  ref,
  conversationId,
) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value(0);

  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null) return Stream.value(0);

  return ref
      .watch(chatRepositoryProvider)
      .watchUnreadCount(conversationId: conversationId, currentUserId: user.id);
});

final totalUnreadMessagesProvider = Provider<int>((ref) {
  final conversations =
      ref.watch(conversationsProvider).valueOrNull ?? const [];
  var total = 0;

  for (final conversation in conversations) {
    total +=
        ref
            .watch(conversationUnreadCountProvider(conversation.id))
            .valueOrNull ??
        0;
  }

  return total;
});

final chatControllerProvider = AsyncNotifierProvider<ChatController, void>(
  ChatController.new,
);

class ChatController extends AsyncNotifier<void> {
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

  Future<String?> startConversationWith(String otherUserId) async {
    try {
      final user = await _resolveCurrentUser();
      if (!user.hasFamily) return null;
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
    if (text.trim().isEmpty) return 'Message vide';

    try {
      final user = await _resolveCurrentUser();
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId: conversationId,
            senderId: user.id,
            text: text,
          );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
