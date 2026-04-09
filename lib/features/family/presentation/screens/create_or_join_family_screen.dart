import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/family_providers.dart';

class CreateOrJoinFamilyScreen extends ConsumerStatefulWidget {
  const CreateOrJoinFamilyScreen({super.key});

  @override
  ConsumerState<CreateOrJoinFamilyScreen> createState() =>
      _CreateOrJoinFamilyScreenState();
}

class _CreateOrJoinFamilyScreenState
    extends ConsumerState<CreateOrJoinFamilyScreen> {
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (!_createFormKey.currentState!.validate()) return;

    final error = await ref
        .read(familyControllerProvider.notifier)
        .createFamily(_familyNameController.text);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _joinFamily() async {
    if (!_joinFormKey.currentState!.validate()) return;

    final error = await ref
        .read(familyControllerProvider.notifier)
        .joinFamily(_inviteCodeController.text);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ma famille')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Commence ton espace familial',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Cree une nouvelle famille ou rejoins avec un code d\'invitation.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Form(
                key: _createFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Creer une famille',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _familyNameController,
                      label: 'Nom de la famille',
                      validator: (value) =>
                          Validators.requiredField(value, label: 'Nom'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Creer',
                      icon: Icons.group_add_outlined,
                      isLoading: familyState.isLoading,
                      onPressed: _createFamily,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Form(
                key: _joinFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Rejoindre une famille',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _inviteCodeController,
                      label: 'Code invitation',
                      validator: (value) =>
                          Validators.requiredField(value, label: 'Code'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Rejoindre',
                      icon: Icons.login,
                      isLoading: familyState.isLoading,
                      onPressed: _joinFamily,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
