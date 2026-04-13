import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadFile({
    required File file,
    required String path,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final resolvedContentType = contentType ?? _inferContentType(file.path);
    final metadata = resolvedContentType == null
        ? null
        : SettableMetadata(contentType: resolvedContentType);
    final uploadTask = ref.putFile(file, metadata);

    StreamSubscription<TaskSnapshot>? subscription;
    if (onProgress != null) {
      subscription = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        if (total <= 0) return;
        onProgress(snapshot.bytesTransferred / total);
      });
    }

    try {
      await uploadTask;
      onProgress?.call(1);
      return ref.getDownloadURL();
    } finally {
      await subscription?.cancel();
    }
  }

  String? _inferContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    if (lower.endsWith('.mp4')) {
      return 'video/mp4';
    }
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (lower.endsWith('.3gp')) {
      return 'video/3gpp';
    }
    if (lower.endsWith('.mkv')) {
      return 'video/x-matroska';
    }
    if (lower.endsWith('.webm')) {
      return 'video/webm';
    }
    return null;
  }

  Future<void> deleteFileByUrl(String fileUrl) async {
    final ref = _storage.refFromURL(fileUrl);
    await ref.delete();
  }
}
