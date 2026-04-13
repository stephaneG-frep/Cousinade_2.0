import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/firebase_providers.dart';
import '../../data/auth_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(firestoreProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).valueOrNull;
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) {
    return Stream.value(null);
  }

  final authRepository = ref.watch(authRepositoryProvider);
  bool hasEnsuredProfile = false;

  return authRepository.watchUserProfile(user.uid).asyncMap((profile) async {
    if (profile != null) return profile;
    if (hasEnsuredProfile) return null;
    hasEnsuredProfile = true;
    try {
      return await authRepository.ensureUserProfileForAuthUser(user);
    } catch (_) {
      return null;
    }
  });
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = const AsyncData(null);
      return null;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
      return e.message ?? 'Erreur de connexion';
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Connexion impossible';
    }
  }

  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
          );
      state = const AsyncData(null);
      return null;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
      return e.message ?? 'Erreur d\'inscription';
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Inscription impossible';
    }
  }

  Future<String?> resetPassword(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      state = const AsyncData(null);
      return null;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
      return e.message ?? 'Impossible d\'envoyer le mail';
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Impossible d\'envoyer le mail';
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).logout();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
