import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/comment_model.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/models/user_model.dart';
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
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value([]);

  final user = ref.watch(currentUserProfileProvider).valueOrNull;
  if (user == null || !user.hasFamily) return Stream.value([]);
  return ref.watch(feedRepositoryProvider).watchFamilyPosts(user.familyId!);
});

final postDetailProvider = StreamProvider.family<PostModel?, String>((
  ref,
  postId,
) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value(null);
  return ref.watch(feedRepositoryProvider).watchPost(postId);
});

final postCommentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  postId,
) {
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) return Stream.value([]);
  return ref.watch(feedRepositoryProvider).watchComments(postId);
});

final feedControllerProvider = AsyncNotifierProvider<FeedController, void>(
  FeedController.new,
);

final postUploadProgressProvider = StateProvider<double?>((ref) => null);

class FeedController extends AsyncNotifier<void> {
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

  Future<String?> createPost({
    required String text,
    File? image,
    File? video,
  }) async {
    if (text.trim().isEmpty && image == null && video == null) {
      return 'Ajoute un texte, une photo ou une video';
    }

    state = const AsyncLoading();
    ref.read(postUploadProgressProvider.notifier).state = 0;
    try {
      final user = await _resolveCurrentUser();
      if (!user.hasFamily) {
        state = const AsyncData(null);
        ref.read(postUploadProgressProvider.notifier).state = null;
        return 'Famille introuvable';
      }
      await ref
          .read(feedRepositoryProvider)
          .createPost(
            familyId: user.familyId!,
            author: user,
            text: text,
            image: image,
            video: video,
            onUploadProgress: (progress) {
              ref.read(postUploadProgressProvider.notifier).state = progress
                  .clamp(0, 1);
            },
          );
      state = const AsyncData(null);
      ref.read(postUploadProgressProvider.notifier).state = null;
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      ref.read(postUploadProgressProvider.notifier).state = null;
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> toggleLike(PostModel post) async {
    UserModel? user;
    try {
      user = await _resolveCurrentUser();
    } catch (_) {
      user = null;
    }
    if (user == null) return;
    await ref
        .read(feedRepositoryProvider)
        .toggleLike(postId: post.id, userId: user.id);
  }

  Future<String?> addComment({
    required String postId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return 'Commentaire vide';

    try {
      final user = await _resolveCurrentUser();
      await ref
          .read(feedRepositoryProvider)
          .addComment(postId: postId, author: user, text: text);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updatePostText({
    required PostModel post,
    required String text,
  }) async {
    try {
      final user = await _resolveCurrentUser();
      if (user.id != post.authorId) {
        return 'Tu ne peux modifier que tes publications';
      }
      if (text.trim().isEmpty &&
          (post.imageUrl ?? '').isEmpty &&
          (post.videoUrl ?? '').isEmpty) {
        return 'Ajoute du texte, une photo ou une video';
      }

      state = const AsyncLoading();
      await ref
          .read(feedRepositoryProvider)
          .updatePostText(postId: post.id, text: text);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> deletePost(PostModel post) async {
    try {
      final user = await _resolveCurrentUser();
      final isAdmin = user.role == 'admin';
      if (user.id != post.authorId && !isAdmin) {
        return 'Tu ne peux supprimer que tes publications';
      }

      state = const AsyncLoading();
      await ref.read(feedRepositoryProvider).deletePost(post.id);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> removePostMedia({
    required PostModel post,
    required String mediaType,
  }) async {
    try {
      final user = await _resolveCurrentUser();
      final isAdmin = user.role == 'admin';
      if (user.id != post.authorId && !isAdmin) {
        return 'Tu ne peux modifier que tes publications';
      }
      if (mediaType != 'image' && mediaType != 'video') {
        return 'Type de media invalide';
      }

      state = const AsyncLoading();
      await ref
          .read(feedRepositoryProvider)
          .removePostMedia(post: post, mediaType: mediaType);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
