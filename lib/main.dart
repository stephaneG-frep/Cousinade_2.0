import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'firebase_options.dart';
import 'shared/widgets/presence_tracker.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/firebase_providers.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await NotificationService(FirebaseMessaging.instance).initialize();
  } catch (_) {
    // Notifications are optional at startup and can fail on emulators.
  }

  runApp(const ProviderScope(child: CousinadeApp()));
}

class CousinadeApp extends ConsumerWidget {
  const CousinadeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return PresenceTracker(
      child: FamilyMigrationGate(
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
  }
}

class FamilyMigrationGate extends ConsumerStatefulWidget {
  const FamilyMigrationGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FamilyMigrationGate> createState() =>
      _FamilyMigrationGateState();
}

class _FamilyMigrationGateState extends ConsumerState<FamilyMigrationGate> {
  bool _ran = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run();
    });
  }

  Future<void> _run() async {
    if (_ran) return;
    _ran = true;

    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await ref
          .read(authRepositoryProvider)
          .ensureUserProfileForAuthUser(user);
      await ref.read(firestoreProvider).collection('users').doc(user.uid).set(
        {'familyId': 'primary'},
        SetOptions(merge: true),
      );
      // No invalidate needed — currentUserProfileProvider is a Firestore stream
      // and will auto-update when the document changes.
    } catch (_) {
      // If it fails, the app will still try to auto-join later.
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
