import 'dart:io';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../../../widgets/cached_image.dart';

class MediaSlotWidget extends StatelessWidget {
  final MediaItem? media;
  final int index;
  final bool isFirstItem;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const MediaSlotWidget({
    super.key,
    required this.media,
    required this.index,
    required this.isFirstItem,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (media == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 24,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 4),
              Text(
                'Add',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onEdit,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0039A6),
                width: 2,
              ),
            ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Display actual image or video thumbnail
                _buildMediaPreview(),

                // Video indicator
                if (media!.type == MediaType.video)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),

                // Main photo badge
                if (isFirstItem)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0039A6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'MAIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Edit button only
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit,
              size: 12,
              color: Color(0xFF0039A6),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (media!.path != null) {
      return Image.file(
        File(media!.path!),
        fit: BoxFit.cover,
        cacheHeight: 400,  // Cache at reasonable size
        cacheWidth: 300,
      );
    } else if (media!.url != null) {
      return CachedImage(
        imageUrl: media!.url,
        fit: BoxFit.cover,
        placeholder: Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: Container(
          color: Colors.grey[300],
          child: Icon(
            media!.type == MediaType.video ? Icons.videocam : Icons.image,
            size: 28,
            color: Colors.grey[600],
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: Icon(
          media!.type == MediaType.video ? Icons.videocam : Icons.image,
          size: 28,
          color: Colors.grey[600],
        ),
      );
    }
  }
}
