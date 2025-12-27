import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Chat input bar with text field and send button
class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onAttachmentPressed;
  final VoidCallback? onAudioPressed;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onAttachmentPressed,
    this.onAudioPressed,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
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
  void dispose() {
    _controller.dispose();
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: widget.enabled ? widget.onAttachmentPressed : null,
              icon: Icon(
                Icons.attach_file,
                color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
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
            
            // Audio or send button
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
    );
  }
}
