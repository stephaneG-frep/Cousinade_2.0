import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/one_time_tip_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../family/presentation/providers/family_providers.dart';
import '../providers/feed_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  File? _selectedVideo;

  static const _draftImageKey = 'draft_post_image_path';
  static const _draftVideoKey = 'draft_post_video_path';
  static const _returnToPublishKey = 'return_to_publish';

  bool get _canPublish =>
      _selectedImage != null ||
      _selectedVideo != null ||
      _textController.text.trim().isNotEmpty;

  String? get _selectedVideoName {
    final path = _selectedVideo?.path;
    if (path == null) return null;
    final fileName = path.split('/').last;
    return fileName.isEmpty ? null : fileName;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _recoverLostMedia();
    _restoreDraftMedia();
  }

  Future<void> _recoverLostMedia() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return;
    if (!mounted) return;

    final file = response.file;
    if (file == null) {
      if (response.exception != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de recuperer le media.')),
        );
      }
      return;
    }

    setState(() {
      if (response.type == RetrieveType.video) {
        _selectedVideo = File(file.path);
        _selectedImage = null;
      } else {
        _selectedImage = File(file.path);
        _selectedVideo = null;
      }
    });
    await _persistDraftMedia();
  }

  Future<void> _restoreDraftMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_draftImageKey);
    final videoPath = prefs.getString(_draftVideoKey);

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        if (!mounted) return;
        setState(() {
          _selectedImage = file;
          _selectedVideo = null;
        });
        return;
      }
    }

    if (videoPath != null && videoPath.isNotEmpty) {
      final file = File(videoPath);
      if (await file.exists()) {
        if (!mounted) return;
        setState(() {
          _selectedVideo = file;
          _selectedImage = null;
        });
      }
    }
  }

  Future<void> _persistDraftMedia() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedImage != null) {
      await prefs.setString(_draftImageKey, _selectedImage!.path);
      await prefs.remove(_draftVideoKey);
    } else if (_selectedVideo != null) {
      await prefs.setString(_draftVideoKey, _selectedVideo!.path);
      await prefs.remove(_draftImageKey);
    } else {
      await prefs.remove(_draftImageKey);
      await prefs.remove(_draftVideoKey);
    }
  }

  Future<void> _pickImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_returnToPublishKey, true);

    XFile? image;
    String? errorMsg;
    try {
      image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    await prefs.remove(_returnToPublishKey);

    if (errorMsg != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo : $errorMsg')),
      );
      return;
    }

    // image == null means the user cancelled — nothing to do.
    if (image == null) return;

    if (!mounted) return;
    setState(() {
      _selectedImage = File(image!.path);
      _selectedVideo = null;
    });
    await _persistDraftMedia();
  }

  Future<void> _pickVideo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_returnToPublishKey, true);

    XFile? video;
    String? errorMsg;
    try {
      video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    await prefs.remove(_returnToPublishKey);

    if (errorMsg != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video : $errorMsg')),
      );
      return;
    }

    // video == null means the user cancelled — nothing to do.
    if (video == null) return;

    if (!mounted) return;
    setState(() {
      _selectedVideo = File(video!.path);
      _selectedImage = null;
    });
    await _persistDraftMedia();
  }

  Future<void> _publish() async {
    final error = await ref
        .read(feedControllerProvider.notifier)
        .createPost(
          text: _textController.text,
          image: _selectedImage,
          video: _selectedVideo,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _textController.clear();
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
    await _persistDraftMedia();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final uploadProgress = ref.watch(postUploadProgressProvider);
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;
    final hasFamily = currentUser?.hasFamily == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Publier')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OneTimeTipCard(
            storageKey: 'tip_publish',
            title: 'Publier',
            message:
                'Ecris un message et ajoute une photo ou une video si tu veux.',
            icon: Icons.edit_note_outlined,
          ),
          if (!hasFamily)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connexion famille requise',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Impossible de publier tant que ta famille n\'est pas connectee.',
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () async {
                      final error = await ref
                          .read(familyControllerProvider.notifier)
                          .autoJoinDefaultFamily();
                      if (!context.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Famille connectee'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.groups_2_outlined),
                    label: const Text('Reconnecter ma famille'),
                  ),
                ],
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _textController,
                  label: 'Un message pour la famille',
                  hint: 'Ex: Qui vient au repas dimanche ?',
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (_selectedImage != null) ...[
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    child: Image.file(
                      _selectedImage!,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_selectedVideo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      color: AppColors.roseBeige,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedVideoName ?? 'Video selectionnee',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (feedState.isLoading && uploadProgress != null) ...[
                  Builder(
                    builder: (context) {
                      final boundedProgress = uploadProgress.clamp(0.0, 1.0);
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: boundedProgress,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload ${(boundedProgress * 100).round()}%',
                            textAlign: TextAlign.right,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _selectedImage == null
                              ? 'Ajouter photo'
                              : 'Changer photo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickVideo,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text(
                          _selectedVideo == null
                              ? 'Ajouter video'
                              : 'Changer video',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                  child: ElevatedButton.icon(
                    onPressed: feedState.isLoading || !_canPublish
                        ? null
                        : _publish,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                          backgroundColor: AppColors.orange,
                          foregroundColor: AppColors.white,
                        ),
                        icon: feedState.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Publier'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
