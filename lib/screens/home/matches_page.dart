import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_colors.dart';
import 'chat_screen.dart';

class MatchesPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;
  final VoidCallback? onNavigateToDiscover;

  const MatchesPage({
    super.key,
    required this.user,
    this.userData,
    this.onNavigateToDiscover,
  });

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with AutomaticKeepAliveClientMixin {
  final MessagingService _messagingService = MessagingService();
  List<Map<String, dynamic>>? _cachedMatches;

  @override
  bool get wantKeepAlive => true;

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messagingService.getMatchesStream(),
        builder: (context, snapshot) {
          // Only show loading on first load, not when returning from chat
          if (snapshot.connectionState == ConnectionState.waiting && _cachedMatches == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // Update cache when we get new data
          if (snapshot.hasData) {
            _cachedMatches = snapshot.data;
          }

          final matches = _cachedMatches ?? [];

          if (matches.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // 30-day auto-delete notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.lightBlue.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: AppColors.gsuBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Heads up! Messages are automatically deleted after 30 days.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Matches list
              Expanded(
                child: ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _buildMatchTile(match);
                  },
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 64,
                color: AppColors.gsuBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you match with someone, you can start chatting here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onNavigateToDiscover != null) {
                  widget.onNavigateToDiscover!();
                }
              },
              icon: const Icon(Icons.explore),
              label: const Text('Start Discovering'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gsuBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchTile(Map<String, dynamic> match) {
    final lastMessage = match['lastMessage'] as Map<String, dynamic>?;
    final lastMessageText = lastMessage?['text'] ?? 'Start chatting!';
    final lastMessageSenderId = lastMessage?['senderId'];
    final isMyMessage = lastMessageSenderId == widget.user.uid;
    final lastMessageAt = match['lastMessageAt'] as Timestamp?;
    final unreadCount = match['unreadCount'] as int? ?? 0;
    final hasUnread = unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[300],
        backgroundImage: match['otherUserPhoto'] != null
            ? CachedNetworkImageProvider(match['otherUserPhoto'])
            : null,
        child: match['otherUserPhoto'] == null
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(
        match['otherUserName'] ?? 'User',
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
          color: hasUnread ? Colors.black : null,
        ),
      ),
      subtitle: Text(
        isMyMessage ? 'You: $lastMessageText' : lastMessageText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? Colors.black87 : Colors.grey[600],
          fontSize: 14,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lastMessageAt != null)
            Text(
              _formatTimestamp(lastMessageAt),
              style: TextStyle(
                color: hasUnread ? AppColors.gsuBlue : Colors.grey[500],
                fontSize: 12,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gsuBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              matchId: match['matchId'],
              otherUserId: match['otherUserId'],
              otherUserName: match['otherUserName'] ?? 'User',
              otherUserPhoto: match['otherUserPhoto'],
            ),
          ),
        );
      },
    );
  }
}
