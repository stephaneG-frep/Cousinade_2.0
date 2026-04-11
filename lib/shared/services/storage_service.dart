import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadFile({
    required File file,
    required String path,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);

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

  Future<void> deleteFileByUrl(String fileUrl) async {
    final ref = _storage.refFromURL(fileUrl);
    await ref.delete();
  }
}
