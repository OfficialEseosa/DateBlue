import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onAttachmentPressed;
  final VoidCallback? onAudioPressed;
  final bool enabled;
  final Map<String, dynamic>? replyTo;
  final String? replyToName;
  final VoidCallback? onCancelReply;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onAttachmentPressed,
    this.onAudioPressed,
    this.enabled = true,
    this.replyTo,
    this.replyToName,
    this.onCancelReply,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-focus only when a NEW reply is set (not on rebuild)
    final newReplyId = widget.replyTo?['messageId'];
    final oldReplyId = oldWidget.replyTo?['messageId'];
    if (newReplyId != null && newReplyId != oldReplyId) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyTo != null) _buildReplyPreview(),
            
            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.enabled ? widget.onAttachmentPressed : null,
                    icon: Icon(
                      Icons.attach_file,
                      color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                  
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: _hasText
                        ? IconButton(
                            key: const ValueKey('send'),
                            onPressed: widget.enabled ? _handleSend : null,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.enabled ? AppColors.gsuBlue : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          )
                        : IconButton(
                            key: const ValueKey('audio'),
                            onPressed: widget.enabled ? widget.onAudioPressed : null,
                            icon: Icon(
                              Icons.mic,
                              color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
                              size: 28,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final reply = widget.replyTo!;
    final type = reply['type'] as String? ?? 'text';
    final content = reply['content'] as String? ?? '';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          left: BorderSide(color: AppColors.gsuBlue, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${widget.replyToName ?? 'message'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gsuBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (type == 'image' || type == 'images')
                      Icon(Icons.image, size: 14, color: Colors.grey[600]),
                    if (type == 'audio')
                      Icon(Icons.mic, size: 14, color: Colors.grey[600]),
                    if (type == 'image' || type == 'images' || type == 'audio')
                      const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        type == 'image' || type == 'images' ? 'Photo' : (type == 'audio' ? 'Voice message' : content),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}
