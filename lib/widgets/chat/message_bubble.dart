import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

/// Message bubble widget for chat
class MessageBubble extends StatelessWidget {
  final String content;
  final String type;
  final bool isMine;
  final DateTime timestamp;
  final bool isRead;
  final bool edited;
  final bool deleted;
  final String? mediaUrl;
  final VoidCallback? onLongPress;

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
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (deleted) {
      return _buildDeletedBubble();
    }

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
              Container(
                padding: type == 'text'
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    : const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.gsuBlue : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                ),
                child: _buildContent(),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.jm().format(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (edited) ...[
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
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: isRead ? AppColors.gsuBlue : Colors.grey[400],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: mediaUrl != null
              ? Image.network(
                  mediaUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                )
              : Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 48),
                ),
        );

      case 'audio':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_filled,
                color: isMine ? Colors.white : AppColors.gsuBlue,
                size: 32,
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: isMine ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:00',
                style: TextStyle(
                  color: isMine ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      default:
        return Text(
          content,
          style: TextStyle(
            color: isMine ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildDeletedBubble() {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMine ? 48 : 12,
          right: isMine ? 12 : 48,
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
}
