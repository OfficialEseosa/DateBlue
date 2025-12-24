import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/media_item.dart';

class MediaPicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<MediaItem?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        return await _cropImage(image.path);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<List<MediaItem>> pickMultipleFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 100,
        limit: 6,
      );

      final List<MediaItem> mediaItems = [];
      for (final image in images) {
        final croppedMedia = await _cropImage(image.path);
        if (croppedMedia != null) {
          mediaItems.add(croppedMedia);
        }
      }
      return mediaItems;
    } catch (e) {
      return [];
    }
  }

  static Future<MediaItem?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        return await _cropImage(image.path);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<MediaItem?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        return MediaItem(
          id: DateTime.now().toString(),
          type: MediaType.video,
          path: video.path,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<MediaItem?> cropExisting(String imagePath) async {
    return await _cropImage(imagePath);
  }

  static Future<MediaItem?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFF0039A6),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF0039A6),
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return MediaItem(
          id: DateTime.now().toString(),
          type: MediaType.photo,
          path: croppedFile.path,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
