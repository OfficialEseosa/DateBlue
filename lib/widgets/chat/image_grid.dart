import 'package:flutter/material.dart';

/// Widget to display multiple images in a grid layout
class ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final bool isMine;
  final DateTime timestamp;
  final bool showTimestamp;
  final Function(int index) onImageTap;
  final VoidCallback? onLongPress;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    required this.isMine,
    required this.timestamp,
    required this.onImageTap,
    this.showTimestamp = true,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final count = imageUrls.length;
    
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: isMine ? 48 : 12,
            right: isMine ? 12 : 48,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildGrid(count),
              ),
              if (showTimestamp) ...[
                const SizedBox(height: 2),
                Text(
                  '${count} photos',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(int count) {
    if (count == 1) {
      return _buildImage(0, width: 220, height: 280);
    }
    
    if (count == 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImage(0, width: 110, height: 140),
          const SizedBox(width: 2),
          _buildImage(1, width: 110, height: 140),
        ],
      );
    }
    
    if (count == 3) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImage(0, width: 146, height: 180),
          const SizedBox(width: 2),
          Column(
            children: [
              _buildImage(1, width: 72, height: 89),
              const SizedBox(height: 2),
              _buildImage(2, width: 72, height: 89),
            ],
          ),
        ],
      );
    }
    
    // 4+ images: 2x2 grid with count overlay on last
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(0, width: 110, height: 110),
            const SizedBox(width: 2),
            _buildImage(1, width: 110, height: 110),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(2, width: 110, height: 110),
            const SizedBox(width: 2),
            count > 4
                ? _buildImageWithOverlay(3, width: 110, height: 110, remaining: count - 4)
                : _buildImage(3, width: 110, height: 110),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(int index, {required double width, required double height}) {
    return GestureDetector(
      onTap: () => onImageTap(index),
      child: Image.network(
        imageUrls[index],
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildImageWithOverlay(int index, {
    required double width,
    required double height,
    required int remaining,
  }) {
    return GestureDetector(
      onTap: () => onImageTap(index),
      child: Stack(
        children: [
          Image.network(
            imageUrls[index],
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
          Container(
            width: width,
            height: height,
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Text(
                '+$remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
