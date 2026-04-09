import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/comment_model.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(
    ref.watch(firestoreProvider),
    StorageService(ref.watch(firebaseStorageProvider)),
  );
});

final familyPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null || !user.hasFamily) return Stream.value([]);
  return ref.watch(feedRepositoryProvider).watchFamilyPosts(user.familyId!);
});

final postDetailProvider = StreamProvider.family<PostModel?, String>((
  ref,
  postId,
) {
  return ref.watch(feedRepositoryProvider).watchPost(postId);
});

final postCommentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  postId,
) {
  return ref.watch(feedRepositoryProvider).watchComments(postId);
});

final feedControllerProvider = AsyncNotifierProvider<FeedController, void>(
  FeedController.new,
);

class FeedController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> createPost({required String text, File? image}) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null || !user.hasFamily) return 'Famille introuvable';

    if (text.trim().isEmpty && image == null) {
      return 'Ajoute un texte ou une photo';
    }

    state = const AsyncLoading();
    try {
      await ref
          .read(feedRepositoryProvider)
          .createPost(
            familyId: user.familyId!,
            author: user,
            text: text,
            image: image,
          );
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Publication impossible';
    }
  }

  Future<void> toggleLike(PostModel post) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return;
    await ref
        .read(feedRepositoryProvider)
        .toggleLike(postId: post.id, userId: user.id);
  }

  Future<String?> addComment({
    required String postId,
    required String text,
  }) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return 'Utilisateur introuvable';
    if (text.trim().isEmpty) return 'Commentaire vide';

    try {
      await ref
          .read(feedRepositoryProvider)
          .addComment(postId: postId, author: user, text: text);
      return null;
    } catch (_) {
      return 'Commentaire impossible';
    }
  }
}
