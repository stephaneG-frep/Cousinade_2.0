import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  File? _avatar;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (image == null) return;

    setState(() {
      _avatar = File(image.path);
    });
  }

  Future<void> _save() async {
    if (ref.read(profileControllerProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final error = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          bio: _bioController.text,
          avatar: _avatar,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil mis a jour')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final state = ref.watch(profileControllerProvider);

    if (user != null && !_initialized) {
      _initialized = true;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _bioController.text = user.bio ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_avatar != null)
                CircleAvatar(radius: 42, backgroundImage: FileImage(_avatar!))
              else
                CircleAvatar(
                  radius: 42,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickAvatar,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Changer la photo'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _firstNameController,
                label: 'Prenom',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Prenom obligatoire'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _lastNameController,
                label: 'Nom',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nom obligatoire'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _bioController,
                label: 'Bio',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Enregistrer',
                isLoading: state.isLoading,
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
