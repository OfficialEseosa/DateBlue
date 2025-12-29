import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/messaging_service.dart';
import '../../services/message_cache_service.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../theme/app_colors.dart';
import 'image_preview_screen.dart';

/// Chat screen for messaging between matched users
class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagingService _messagingService = MessagingService();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showPrivacyBanner = true;
  bool _showScrollButton = false;
  Map<String, dynamic>? _matchData;
  List<Map<String, dynamic>>? _cachedMessages;
  Map<String, dynamic>? _replyTo;
  final Set<String> _preloadedUrls = {}; // Track preloaded URLs to avoid redundant work
  
  final List<Map<String, dynamic>> _pendingImages = [];

  @override
  void initState() {
    super.initState();
    _loadMatchData();
    _markAsRead();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show button when scrolled more than 200px from bottom (which is 0 in reverse)
    final shouldShow = _scrollController.hasClients && _scrollController.offset > 200;
    if (shouldShow != _showScrollButton) {
      setState(() => _showScrollButton = shouldShow);
    }
  }

  Future<void> _loadMatchData() async {
    final match = await _messagingService.getMatch(widget.matchId);
    if (mounted) {
      setState(() => _matchData = match);
    }
  }

  void _markAsRead() {
    _messagingService.markMessagesAsRead(widget.matchId);
  }

  /// Preload images for smoother scrolling
  void _preloadImages(List<Map<String, dynamic>> messages) {
    for (final msg in messages) {
      // Preload single images
      if (msg['mediaUrl'] != null) {
        final url = msg['mediaUrl'] as String;
        if (!_preloadedUrls.contains(url)) {
          _preloadedUrls.add(url);
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
      // Preload multi-images
      if (msg['mediaUrls'] != null) {
        for (final url in (msg['mediaUrls'] as List)) {
          if (!_preloadedUrls.contains(url)) {
            _preloadedUrls.add(url as String);
            precacheImage(CachedNetworkImageProvider(url), context);
          }
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // In reverse list, 0 is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage(String content) async {
    final replyData = _replyTo;
    setState(() => _replyTo = null);
    
    try {
      await _messagingService.sendMessage(
        matchId: widget.matchId,
        content: content,
        replyToId: replyData?['messageId'],
        replyToContent: replyData?['content'] ?? (replyData?['type'] == 'image' ? 'Photo' : null),
        replyToType: replyData?['type'],
      );
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0, // With reverse: true, 0 is the bottom
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  void _showProfileCard() {
    // Navigate to profile view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ExpandedProfileScreen(
          userId: widget.otherUserId,
          userName: widget.otherUserName,
          userPhoto: widget.otherUserPhoto,
        ),
      ),
    );
  }

  void _showAllMedia() {
    // Collect all media from cached messages
    final allMedia = <String>[];
    if (_cachedMessages != null) {
      for (final msg in _cachedMessages!) {
        if (msg['mediaUrl'] != null) {
          allMedia.add(msg['mediaUrl']);
        }
        if (msg['mediaUrls'] != null) {
          allMedia.addAll(List<String>.from(msg['mediaUrls']));
        }
      }
    }
    
    if (allMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No media in this chat yet')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MediaGridScreen(
          mediaUrls: allMedia,
          title: 'Media',
        ),
      ),
    );
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gsuBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.gsuBlue),
              ),
              title: const Text('Photos from Gallery'),
              subtitle: const Text('Select up to 20'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gsuBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.gsuBlue),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: 20,
      );
      
      if (images.isEmpty) return;
      
      // Convert to File list and filter by size
      final List<File> validFiles = [];
      for (final image in images) {
        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize <= 10 * 1024 * 1024) {
          validFiles.add(file);
        }
      }
      
      if (validFiles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All images were too large (max 10MB each)')),
          );
        }
        return;
      }
      
      // Show preview screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              images: validFiles,
              onSend: _uploadAndSendImages,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      // Check file size (10MB limit)
      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image too large. Max size is 10MB.')),
          );
        }
        return;
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              images: [file],
              onSend: _uploadAndSendImages,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndSendImages(List<File> images) async {
    if (images.length == 1) {
      await _uploadAndSendImage(images.first);
      return;
    }
    
    final pendingId = 'pending_batch_${DateTime.now().millisecondsSinceEpoch}';
    
    setState(() {
      _pendingImages.add({
        'id': pendingId,
        'localPath': images.first.path,
        'timestamp': DateTime.now(),
        'count': images.length,
      });
    });

    try {
      // Upload all images in parallel for better performance
      final uploadFutures = images.asMap().entries.map((entry) async {
        final index = entry.key;
        final image = entry.value;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child(widget.matchId)
            .child(fileName);
        
        await ref.putFile(image);
        return ref.getDownloadURL();
      });
      
      final uploadedUrls = await Future.wait(uploadFutures);

      // Send as single message with all URLs
      await _messagingService.sendMessage(
        matchId: widget.matchId,
        content: '${images.length} photos',
        type: 'images',
        mediaUrl: uploadedUrls.first,
        mediaUrls: uploadedUrls,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload images: $e')),
        );
      }
    } finally {
      setState(() {
        _pendingImages.removeWhere((p) => p['id'] == pendingId);
      });
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    // Create a pending message ID
    final pendingId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    
    // Add to pending list immediately and show in UI
    setState(() {
      _pendingImages.add({
        'id': pendingId,
        'localPath': imageFile.path,
        'timestamp': DateTime.now(),
      });
    });
    
    // Scroll to bottom to show pending image
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = _messagingService.currentUserId;
      final filename = 'chat_${widget.matchId}_${userId}_$timestamp.jpg';
      
      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.matchId)
          .child(filename);
      
      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final downloadUrl = await ref.getDownloadURL();
      
      // Send the message with image
      await _messagingService.sendMessage(
        matchId: widget.matchId,
        content: '📷 Photo',
        type: 'image',
        mediaUrl: downloadUrl,
      );
      
      // Remove from pending list (message now in Firestore stream)
      if (mounted) {
        setState(() {
          _pendingImages.removeWhere((p) => p['id'] == pendingId);
        });
      }
      
    } catch (e) {
      // Remove from pending and show error
      if (mounted) {
        setState(() {
          _pendingImages.removeWhere((p) => p['id'] == pendingId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  void _showActionMenu() {
    final voiceEnabled = _matchData?['voiceCallsEnabled']?[_messagingService.currentUserId] ?? false;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                voiceEnabled ? Icons.phone_disabled : Icons.phone,
                color: AppColors.gsuBlue,
              ),
              title: Text(voiceEnabled ? 'Disable Voice Calls' : 'Enable Voice Calls'),
              onTap: () {
                Navigator.pop(context);
                _toggleVoiceCalls(!voiceEnabled);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.gsuBlue),
              title: const Text('View Media'),
              subtitle: const Text('All photos in this chat'),
              onTap: () {
                Navigator.pop(context);
                _showAllMedia();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('Report Conversation'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show report dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.heart_broken, color: Colors.red),
              title: const Text('Unmatch'),
              onTap: () {
                Navigator.pop(context);
                _showUnmatchConfirmation();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toggleVoiceCalls(bool enabled) async {
    try {
      await _messagingService.toggleVoiceCalls(
        matchId: widget.matchId,
        enabled: enabled,
      );
      await _loadMatchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'Voice calls enabled. They need to enable too.'
                : 'Voice calls disabled'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${widget.otherUserName}? '
          'This will delete your conversation and they won\'t be able to contact you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _messagingService.blockUser(
                  matchId: widget.matchId,
                  blockedUserId: widget.otherUserId,
                );
                if (mounted) {
                  Navigator.pop(context); // Go back to matches
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.otherUserName} blocked')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showUnmatchConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch'),
        content: Text(
          'Are you sure you want to unmatch with ${widget.otherUserName}? '
          'Your conversation will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _messagingService.unmatch(widget.matchId);
                if (mounted) {
                  Navigator.pop(context); // Go back to matches
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unmatched')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unmatch'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final isMine = message['senderId'] == _messagingService.currentUserId;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Edit only for text messages
            if (isMine && message['type'] == 'text')
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(message);
                },
              ),
            // Delete for all message types
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title: const Text('Report this message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report specific message
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> message) {
    final controller = TextEditingController(text: message['content'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter new message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty || newContent == message['content']) {
                Navigator.pop(context);
                return;
              }
              
              Navigator.pop(context);
              try {
                await _messagingService.editMessage(
                  matchId: widget.matchId,
                  messageId: message['messageId'],
                  newContent: newContent,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message edited')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _messagingService.deleteMessage(
                  matchId: widget.matchId,
                  messageId: message['messageId'],
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceCallsEnabled = _matchData != null
        ? _messagingService.areVoiceCallsEnabled(_matchData!, widget.otherUserId)
        : false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gsuBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _showProfileCard,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.otherUserPhoto != null
                    ? CachedNetworkImageProvider(widget.otherUserPhoto!)
                    : null,
                child: widget.otherUserPhoto == null
                    ? const Icon(Icons.person, size: 20, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Voice call button
          IconButton(
            onPressed: voiceCallsEnabled ? () {
              // TODO: Start call
            } : null,
            icon: Icon(
              Icons.phone,
              color: voiceCallsEnabled ? AppColors.gsuBlue : Colors.grey[400],
            ),
            tooltip: voiceCallsEnabled
                ? 'Call'
                : 'Enable calls in menu',
          ),
          // Menu button
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: _showActionMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Privacy banner
              if (_showPrivacyBanner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.gsuBlue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 18, color: AppColors.gsuBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Be respectful. All messages are private, but reported chats will be reviewed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _showPrivacyBanner = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagingService.getMessagesStream(widget.matchId),
              builder: (context, snapshot) {
                // On first load, try local cache
                if (snapshot.connectionState == ConnectionState.waiting && _cachedMessages == null) {
                  // Try to load from local cache while waiting
                  final localMessages = MessageCacheService.getCachedMessages(widget.matchId);
                  if (localMessages.isNotEmpty) {
                    _cachedMessages = localMessages;
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }

                // Update cache when we get new data from Firebase
                if (snapshot.hasData) {
                  _cachedMessages = snapshot.data;
                  // Save to local cache in background
                  MessageCacheService.cacheMessages(widget.matchId, snapshot.data!);
                  MessageCacheService.updateSyncTime(widget.matchId);
                  // Preload images for smooth scrolling
                  _preloadImages(snapshot.data!);
                }

                final messages = _cachedMessages ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Say hi to ${widget.otherUserName}!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Start at bottom, scroll up for history
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  cacheExtent: 2000, // Keep 2000px of items in memory above/below viewport
                  addAutomaticKeepAlives: true,
                  itemCount: messages.length + _pendingImages.length,
                  itemBuilder: (context, index) {
                    // With reverse: true, index 0 = bottom of screen (newest)
                    // Pending images should appear at the very bottom (index 0, 1, 2...)
                    if (index < _pendingImages.length) {
                      final pending = _pendingImages[_pendingImages.length - 1 - index];
                      return MessageBubble(
                        content: '',
                        type: 'image',
                        isMine: true,
                        timestamp: pending['timestamp'],
                        isRead: false,
                        isPending: true,
                        showTimestamp: false,
                        localImagePath: pending['localPath'],
                      );
                    }
                    
                    // Messages - reverse index to show oldest at top
                    final messageIndex = messages.length - 1 - (index - _pendingImages.length);
                    final message = messages[messageIndex];
                    final timestamp = message['timestamp'];
                    final DateTime dateTime = timestamp is Timestamp
                        ? timestamp.toDate()
                        : DateTime.now();
                    
                    final isMine = message['senderId'] == _messagingService.currentUserId;
                    final readBy = List<String>.from(message['readBy'] ?? []);
                    final isRead = readBy.contains(widget.otherUserId);

                    // Show timestamp only if 30+ min since previous message
                    bool showTimestamp = true;
                    bool isFirstInSequence = true;
                    if (messageIndex < messages.length - 1) {
                      final prevMessage = messages[messageIndex + 1];
                      final prevTimestamp = prevMessage['timestamp'];
                      final prevSenderId = prevMessage['senderId'];
                      
                      // Check if same sender (for bubble tail)
                      isFirstInSequence = prevSenderId != message['senderId'];
                      
                      if (prevTimestamp is Timestamp) {
                        final diff = dateTime.difference(prevTimestamp.toDate());
                        showTimestamp = diff.inMinutes >= 30;
                        // Reset sequence on timestamp break
                        if (showTimestamp) isFirstInSequence = true;
                      }
                    }

                    return MessageBubble(
                      content: message['content'] ?? '',
                      type: message['type'] ?? 'text',
                      isMine: isMine,
                      timestamp: dateTime,
                      isRead: isRead,
                      edited: message['edited'] ?? false,
                      deleted: message['deleted'] ?? false,
                      mediaUrl: message['mediaUrl'],
                      mediaUrls: message['mediaUrls'] != null 
                          ? List<String>.from(message['mediaUrls']) 
                          : null,
                      showTimestamp: showTimestamp,
                      isFirstInSequence: isFirstInSequence,
                      replyToContent: message['replyToContent'],
                      replyToType: message['replyToType'],
                      onLongPress: () => _showMessageOptions(message),
                      onReply: () => setState(() => _replyTo = message),
                      onSendImageReply: (text) async {
                        await _messagingService.sendMessage(
                          matchId: widget.matchId,
                          content: text,
                          replyToId: message['messageId'],
                          replyToContent: 'Photo',
                          replyToType: message['type'],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          ChatInput(
            onSendMessage: _handleSendMessage,
            onAttachmentPressed: _showAttachmentPicker,
            replyTo: _replyTo,
            replyToName: _replyTo != null 
                ? (_replyTo!['senderId'] == _messagingService.currentUserId 
                    ? 'yourself' 
                    : widget.otherUserName)
                : null,
            onCancelReply: () => setState(() => _replyTo = null),
            onAudioPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio messages coming soon!')),
              );
            },
          ),
            ],
          ),
          
          // Scroll to bottom button - positioned over the content (hidden when replying)
          if (_showScrollButton && _replyTo == null)
            Positioned(
              bottom: 72, // Above the input bar
              right: 16,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Expanded profile screen showing user details
class _ExpandedProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userPhoto;

  const _ExpandedProfileScreen({
    required this.userId,
    required this.userName,
    this.userPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[800],
              backgroundImage: userPhoto != null
                  ? CachedNetworkImageProvider(userPhoto!)
                  : null,
              child: userPhoto == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            // TODO: Add more profile details
            Text(
              'Tap to view full profile',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid screen showing all media in chat
class _MediaGridScreen extends StatelessWidget {
  final List<String> mediaUrls;
  final String title;

  const _MediaGridScreen({
    required this.mediaUrls,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title (${mediaUrls.length})'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Open full screen viewer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _FullMediaViewer(
                    mediaUrls: mediaUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: CachedNetworkImage(
              imageUrl: mediaUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full screen media viewer with swipe navigation
class _FullMediaViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const _FullMediaViewer({
    required this.mediaUrls,
    required this.initialIndex,
  });

  @override
  State<_FullMediaViewer> createState() => _FullMediaViewerState();
}

class _FullMediaViewerState extends State<_FullMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.mediaUrls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.mediaUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
