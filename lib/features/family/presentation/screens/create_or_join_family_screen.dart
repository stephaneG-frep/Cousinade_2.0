import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/help_action.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/family_providers.dart';

class CreateOrJoinFamilyScreen extends ConsumerStatefulWidget {
  const CreateOrJoinFamilyScreen({super.key});

  @override
  ConsumerState<CreateOrJoinFamilyScreen> createState() =>
      _CreateOrJoinFamilyScreenState();
}

class _CreateOrJoinFamilyScreenState
    extends ConsumerState<CreateOrJoinFamilyScreen> {
  bool _started = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoJoin();
    });
  }

  void _maybeAutoJoin() {
    if (_started) return;
    final authUser = ref.read(currentFirebaseUserProvider);
    if (authUser == null) return;
    _started = true;
    Future<void>.microtask(_autoJoin);
  }

  Future<void> _autoJoin() async {
    final error = await ref
        .read(familyControllerProvider.notifier)
        .autoJoinDefaultFamily();

    if (!mounted) return;
    setState(() {
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProfileProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user?.hasFamily == true && context.mounted) {
        context.go(AppRoutes.home);
      }
    });

    ref.listen(currentFirebaseUserProvider, (previous, next) {
      if (next != null && !_started) {
        _maybeAutoJoin();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma famille'),
        actions: const [HelpAction()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Connexion a la famille...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error ?? 'Nous te connectons automatiquement a la famille.',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _autoJoin,
                    child: const Text('Reessayer'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
