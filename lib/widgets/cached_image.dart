import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable cached image widget that handles both local files and network URLs.
/// Uses CachedNetworkImage for proper caching of network images.
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final String? localPath;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    this.imageUrl,
    this.localPath,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Prioritize local path if available
    if (localPath != null && localPath!.isNotEmpty) {
      imageWidget = Image.file(
        File(localPath!),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultErrorWidget();
        },
      );
    }
    // Then try network URL with caching
    else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    }
    // No image available
    else {
      imageWidget = errorWidget ?? _defaultErrorWidget();
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0039A6)),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[500],
        size: 32,
      ),
    );
  }
}
