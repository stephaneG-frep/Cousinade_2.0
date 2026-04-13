import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/help_action.dart';
import '../../../../shared/widgets/media_source_sheet.dart';
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
  static const _draftAvatarKey = 'draft_profile_avatar_path';

  @override
  void initState() {
    super.initState();
    _recoverLostAvatar();
    _restoreDraftAvatar();
  }

  Future<void> _recoverLostAvatar() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return;
    if (!mounted) return;

    final file = response.file;
    if (file == null) {
      if (response.exception != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de recuperer la photo.')),
        );
      }
      return;
    }

    setState(() {
      _avatar = File(file.path);
    });
    await _persistDraftAvatar();
  }

  Future<void> _restoreDraftAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_draftAvatarKey);
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    if (!mounted) return;
    setState(() {
      _avatar = file;
    });
  }

  Future<void> _persistDraftAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    if (_avatar != null) {
      await prefs.setString(_draftAvatarKey, _avatar!.path);
    } else {
      await prefs.remove(_draftAvatarKey);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (!mounted) return;
    final source = await showMediaSourceSheet(
      context,
      title: 'Photo de profil',
    );
    if (source == null) return;

    XFile? image;
    String? errorMsg;
    try {
      image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    if (errorMsg != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo : $errorMsg')),
      );
      return;
    }

    if (image == null) return;

    if (!mounted) return;
    setState(() {
      _avatar = File(image!.path);
    });
    await _persistDraftAvatar();
  }

  Future<void> _save() async {
    if (ref.read(profileControllerProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplis ton prenom et ton nom.')),
      );
      return;
    }

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

    await _persistDraftAvatar();

    if (!mounted) return;
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
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: const [HelpAction()],
      ),
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
