import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/media_item.dart';

class MediaService {
  static Future<String?> uploadMedia(
    MediaItem media,
    String userId,
    int index,
  ) async {
    try {
      final File file = File(media.path!);
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}_$index';

      File? fileToUpload = file;

      // Compress image if it's a photo
      if (media.type == MediaType.photo) {
        final compressedFile = await _compressImage(file);
        if (compressedFile != null) {
          fileToUpload = compressedFile;
        }
      }

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('media')
          .child(fileName);

      await ref.putFile(fileToUpload);
      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      return null;
    }
  }

  static Future<File?> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      return null;
    }
  }
}
