import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';

class PresenceTracker extends ConsumerStatefulWidget {
  const PresenceTracker({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PresenceTracker> createState() => _PresenceTrackerState();
}

class _PresenceTrackerState extends ConsumerState<PresenceTracker>
    with WidgetsBindingObserver {
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncUser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setOnline(false);
    }
  }

  void _syncUser() {
    final user = ref.read(currentFirebaseUserProvider);
    final userId = user?.uid;
    if (userId == null) return;
    if (_lastUserId != userId) {
      _lastUserId = userId;
      _setOnline(true);
    }
  }

  Future<void> _setOnline(bool isOnline) async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) return;
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) {
      try {
        await ref
            .read(authRepositoryProvider)
            .ensureUserProfileForAuthUser(user);
      } catch (_) {
        return;
      }
    }
    await ref
        .read(profileRepositoryProvider)
        .updatePresence(userId: user.uid, isOnline: isOnline);
  }

  @override
  Widget build(BuildContext context) {
    _syncUser();
    return widget.child;
  }
}
