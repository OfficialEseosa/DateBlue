import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/messaging_service.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../theme/app_colors.dart';

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
  bool _showPrivacyBanner = true;
  Map<String, dynamic>? _matchData;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
    _markAsRead();
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage(String content) async {
    try {
      await _messagingService.sendMessage(
        matchId: widget.matchId,
        content: content,
      );
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
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
              leading: const Icon(Icons.person, color: Colors.grey),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile
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
            if (isMine && message['type'] == 'text') ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show edit dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _messagingService.deleteMessage(
                    matchId: widget.matchId,
                    messageId: message['messageId'],
                  );
                },
              ),
            ],
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
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
      body: Column(
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

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

                // Auto-scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final timestamp = message['timestamp'];
                    final DateTime dateTime = timestamp is Timestamp
                        ? timestamp.toDate()
                        : DateTime.now();
                    
                    final isMine = message['senderId'] == _messagingService.currentUserId;
                    final readBy = List<String>.from(message['readBy'] ?? []);
                    final isRead = readBy.contains(widget.otherUserId);

                    return MessageBubble(
                      content: message['content'] ?? '',
                      type: message['type'] ?? 'text',
                      isMine: isMine,
                      timestamp: dateTime,
                      isRead: isRead,
                      edited: message['edited'] ?? false,
                      deleted: message['deleted'] ?? false,
                      mediaUrl: message['mediaUrl'],
                      onLongPress: () => _showMessageOptions(message),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          ChatInput(
            onSendMessage: _handleSendMessage,
            onAttachmentPressed: () {
              // TODO: Show attachment picker
            },
            onAudioPressed: () {
              // TODO: Start audio recording
            },
          ),
        ],
      ),
    );
  }
}
