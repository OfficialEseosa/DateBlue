class MediaItem {
  final String id;
  String? path;
  String? url;
  final MediaType type;
  
  MediaItem({
    required this.id,
    this.path,
    this.url,
    required this.type,
  });
}

enum MediaType { photo, video }
