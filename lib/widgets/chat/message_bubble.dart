import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../theme/app_colors.dart';

class MessageBubble extends StatefulWidget {
  final String content;
  final String type;
  final bool isMine;
  final DateTime timestamp;
  final bool isRead;
  final bool edited;
  final bool deleted;
  final String? mediaUrl;
  final List<String>? mediaUrls;
  final String? localImagePath;
  final bool isPending;
  final bool showTimestamp;
  final bool isFirstInSequence;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final Function(String)? onSendImageReply;
  final String? replyToContent;
  final String? replyToType;

  const MessageBubble({
    super.key,
    required this.content,
    required this.type,
    required this.isMine,
    required this.timestamp,
    this.isRead = false,
    this.edited = false,
    this.deleted = false,
    this.mediaUrl,
    this.mediaUrls,
    this.localImagePath,
    this.isPending = false,
    this.showTimestamp = true,
    this.isFirstInSequence = true,
    this.onLongPress,
    this.onReply,
    this.onSendImageReply,
    this.replyToContent,
    this.replyToType,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTime = false;
  double _swipeOffset = 0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.onReply == null) return;
    setState(() {
      _swipeOffset = (_swipeOffset + details.delta.dx).clamp(0.0, 60.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_swipeOffset > 50 && widget.onReply != null) {
      widget.onReply!();
    }
    setState(() => _swipeOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deleted) {
      return _buildDeletedBubble();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onTap: () {
        if (!widget.showTimestamp) {
          setState(() => _showTime = !_showTime);
        }
      },
      child: Container(
        width: double.infinity,
        child: Stack(
          children: [
            if (_swipeOffset > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.reply,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(_swipeOffset, 0),
              child: Align(
                alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                margin: EdgeInsets.only(
                  left: widget.isMine ? 48 : 12,
                  right: widget.isMine ? 12 : 48,
                  top: widget.showTimestamp ? 4 : 1,
                  bottom: widget.showTimestamp ? 4 : 1,
                ),
                child: Column(
                  crossAxisAlignment: widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (widget.replyToContent != null) _buildReplyQuote(),
                    Container(
                      padding: widget.type == 'text'
                          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                          : const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.isMine ? AppColors.gsuBlue : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            widget.replyToContent != null ? 4 : 
                            (!widget.isMine && widget.isFirstInSequence ? 4 : 18)
                          ),
                          topRight: Radius.circular(
                            widget.replyToContent != null ? 4 : 
                            (widget.isMine && widget.isFirstInSequence ? 4 : 18)
                          ),
                          bottomLeft: const Radius.circular(18),
                          bottomRight: const Radius.circular(18),
                        ),
                      ),
                      child: _buildContent(context),
                    ),
                    if (widget.showTimestamp || _showTime) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.jm().format(widget.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (widget.edited) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(edited)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (widget.isMine) ...[
                            const SizedBox(width: 4),
                            Icon(
                              widget.isPending 
                                  ? Icons.access_time 
                                  : (widget.isRead ? Icons.done_all : Icons.done),
                              size: 14,
                              color: widget.isPending 
                                  ? Colors.grey[400] 
                                  : (widget.isRead ? AppColors.gsuBlue : Colors.grey[400]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildReplyQuote() {
    final type = widget.replyToType ?? 'text';
    final content = widget.replyToContent ?? '';
    
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: widget.isMine 
            ? Colors.blue[700]  // Darker blue for contrast on gsuBlue
            : Colors.grey[300], // Stronger grey for visibility
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(
          left: BorderSide(
            color: widget.isMine ? Colors.white : AppColors.gsuBlue,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == 'image' || type == 'images')
            Icon(Icons.image, size: 14, color: widget.isMine ? Colors.white70 : Colors.grey[700]),
          if (type == 'audio')
            Icon(Icons.mic, size: 14, color: widget.isMine ? Colors.white70 : Colors.grey[700]),
          if (type == 'image' || type == 'images' || type == 'audio')
            const SizedBox(width: 4),
          Flexible(
            child: Text(
              type == 'image' || type == 'images' ? 'Photo' : (type == 'audio' ? 'Voice message' : content),
              style: TextStyle(
                fontSize: 12,
                color: widget.isMine ? Colors.white70 : Colors.grey[800],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (widget.type) {
      case 'image':
        if (widget.localImagePath != null && widget.isPending) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 220,
              maxHeight: 280,
              minWidth: 120,
              minHeight: 120,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.file(
                    File(widget.localImagePath!),
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final heroTag = 'chat_image_${widget.mediaUrl}';
        
        return GestureDetector(
          onTap: widget.mediaUrl != null ? () => _openImageViewer(context, widget.mediaUrl!, heroTag) : null,
          child: Hero(
            tag: heroTag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 200,
                maxHeight: 267, // 3:4 aspect ratio
                minWidth: 100,
                minHeight: 100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.mediaUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.mediaUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 180,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 180,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      )
                    : Container(
                        width: 180,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 48),
                      ),
              ),
            ),
          ),
        );

      case 'images':
        final urls = widget.mediaUrls ?? [widget.mediaUrl!];
        return _buildImageGrid(context, urls);

      case 'audio':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_filled,
                color: widget.isMine ? Colors.white : AppColors.gsuBlue,
                size: 32,
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isMine ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:00',
                style: TextStyle(
                  color: widget.isMine ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      default:
        return Text(
          widget.content,
          style: TextStyle(
            color: widget.isMine ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildImageGrid(BuildContext context, List<String> urls) {
    final count = urls.length;
    
    Widget buildGridImage(int index, {required double width, required double height, int? remaining}) {
      final heroTag = 'grid_${widget.timestamp.hashCode}_$index';
      return GestureDetector(
        onTap: () => _openGalleryViewer(context, urls, index, heroTag),
        child: Stack(
          children: [
            Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: urls[index],
                width: width,
                height: height,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            if (remaining != null && remaining > 0)
              Container(
                width: width,
                height: height,
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: count == 1
          ? buildGridImage(0, width: 220, height: 280)
          : count == 2
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildGridImage(0, width: 110, height: 140),
                    const SizedBox(width: 2),
                    buildGridImage(1, width: 110, height: 140),
                  ],
                )
              : count == 3
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildGridImage(0, width: 146, height: 180),
                        const SizedBox(width: 2),
                        Column(
                          children: [
                            buildGridImage(1, width: 72, height: 89),
                            const SizedBox(height: 2),
                            buildGridImage(2, width: 72, height: 89),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildGridImage(0, width: 110, height: 110),
                            const SizedBox(width: 2),
                            buildGridImage(1, width: 110, height: 110),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildGridImage(2, width: 110, height: 110),
                            const SizedBox(width: 2),
                            buildGridImage(3, width: 110, height: 110, remaining: count > 4 ? count - 4 : null),
                          ],
                        ),
                      ],
                    ),
    );
  }

  Widget _buildDeletedBubble() {
    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: widget.isMine ? 48 : 12,
          right: widget.isMine ? 12 : 48,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Text(
              'Message deleted',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl, String heroTag) {
    // Dismiss keyboard before opening viewer
    FocusScope.of(context).unfocus();
    
    Navigator.of(context).push<String?>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ImageViewerScreen(
            imageUrl: imageUrl,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ).then((replyText) {
      if (replyText != null && replyText.isNotEmpty && widget.onSendImageReply != null) {
        widget.onSendImageReply!(replyText);
      }
    });
  }

  void _openGalleryViewer(BuildContext context, List<String> urls, int initialIndex, String heroTag) {
    // Dismiss keyboard before opening viewer
    FocusScope.of(context).unfocus();
    
    Navigator.of(context).push<String?>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _GalleryViewerScreen(
            imageUrls: urls,
            initialIndex: initialIndex,
            initialHeroTag: heroTag,
            messageId: '${widget.timestamp.hashCode}',
            onSendReply: widget.onSendImageReply,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((replyText) {
      if (replyText != null && replyText.isNotEmpty && widget.onSendImageReply != null) {
        widget.onSendImageReply!(replyText);
      }
    });
  }
}

/// Full screen image viewer with swipe gestures
class _ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  double _verticalDrag = 0;
  double _backgroundOpacity = 1.0;
  bool _showReplyInput = false;
  bool _isZoomed = false;
  
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  final PhotoViewController _photoController = PhotoViewController();

  @override
  void initState() {
    super.initState();
    _photoController.outputStateStream.listen((state) {
      final isNowZoomed = state.scale != null && state.scale! > 1.05;
      if (isNowZoomed != _isZoomed) {
        setState(() => _isZoomed = isNowZoomed);
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocus.dispose();
    _photoController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_showReplyInput || _isZoomed) return;
    
    // Only show visual feedback for downward swipes (dismiss)
    // Upward swipes go directly to reply mode
    if (details.delta.dy > 0 || _verticalDrag > 0) {
      setState(() {
        _verticalDrag = (_verticalDrag + details.delta.dy).clamp(0.0, 300.0);
        _backgroundOpacity = (1 - (_verticalDrag / 300)).clamp(0.3, 1.0);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_showReplyInput || _isZoomed) return;
    
    final velocity = details.velocity.pixelsPerSecond.dy;
    
    // Swipe UP to show reply input
    if (velocity < -500) {
      setState(() => _showReplyInput = true);
      Future.delayed(const Duration(milliseconds: 100), () {
        _replyFocus.requestFocus();
      });
      return;
    }
    
    // Swipe DOWN to dismiss
    if (_verticalDrag > 80 || velocity > 500) {
      Navigator.of(context).pop();
      return;
    }
    
    // Reset
    setState(() {
      _verticalDrag = 0;
      _backgroundOpacity = 1.0;
    });
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
    setState(() => _showReplyInput = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _showReplyInput ? 0.95 : _backgroundOpacity),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onVerticalDragUpdate: _isZoomed ? null : _onVerticalDragUpdate,
        onVerticalDragEnd: _isZoomed ? null : _onVerticalDragEnd,
        onTap: _showReplyInput ? _hideKeyboard : null,
        child: Stack(
          children: [
            // Full screen PhotoView - handles zoom, pan, double-tap natively
            Transform.translate(
              offset: Offset(0, _verticalDrag),
              child: Transform.scale(
                scale: _showReplyInput ? 0.85 : _backgroundOpacity,
                child: Hero(
                  tag: widget.heroTag,
                  child: PhotoView(
                    controller: _photoController,
                    imageProvider: CachedNetworkImageProvider(widget.imageUrl),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    initialScale: PhotoViewComputedScale.contained,
                    backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    ),
                  ),
                ),
              ),
            ),
            
            
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            // Reply hint
            if (!_showReplyInput && !_isZoomed)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '↑ Reply  ·  ↓ Close',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ),
            
            // Reply input bar
            if (_showReplyInput)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            focusNode: _replyFocus,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Reply to this photo...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              filled: true,
                              fillColor: Colors.grey[800],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendReply(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendReply,
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String initialHeroTag;
  final String? messageId;
  final Function(String)? onSendReply;

  const _GalleryViewerScreen({
    required this.imageUrls,
    this.initialIndex = 0,
    required this.initialHeroTag,
    this.messageId,
    this.onSendReply,
  });

  @override
  State<_GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<_GalleryViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showReplyInput = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  void _showReply() {
    setState(() => _showReplyInput = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      _replyFocus.requestFocus();
    });
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  void _hideReply() {
    FocusScope.of(context).unfocus();
    setState(() => _showReplyInput = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
        actions: [
          if (widget.onSendReply != null)
            IconButton(
              icon: const Icon(Icons.reply),
              onPressed: _showReply,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _showReplyInput ? _hideReply : null,
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(widget.imageUrls[index]),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: 'grid_${widget.messageId}_$index',
                  ),
                );
              },
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
          // Reply input
          if (_showReplyInput)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          focusNode: _replyFocus,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Reply to this photo...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendReply(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendReply,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
