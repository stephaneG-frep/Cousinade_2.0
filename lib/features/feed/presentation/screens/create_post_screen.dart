import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
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

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
      _selectedVideo = null;
    });
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (video == null) return;

    setState(() {
      _selectedVideo = File(video.path);
      _selectedImage = null;
    });
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
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final uploadProgress = ref.watch(postUploadProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Publier')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
