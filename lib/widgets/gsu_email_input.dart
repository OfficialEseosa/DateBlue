import 'package:flutter/material.dart';

class GsuEmailInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final VoidCallback? onSubmitted;

  const GsuEmailInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.showEditButton = false,
    this.onEditPressed,
    this.onSubmitted,
  });

  @override
  State<GsuEmailInput> createState() => _GsuEmailInputState();
}

class _GsuEmailInputState extends State<GsuEmailInput> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.15, 0), // Start position (right)
      end: Offset.zero, // End position (left)
    ).animate(curvedAnimation);
    
    // Start with animation completed if disabled from the start
    if (!widget.enabled) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GsuEmailInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When email is sent (enabled changes from true to false)
    if (oldWidget.enabled && !widget.enabled) {
      _animationController.forward();
    }
    // When user clicks edit (enabled changes from false to true)
    if (!oldWidget.enabled && widget.enabled) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Fixed height to prevent size changes
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Input field (always present but visibility controlled)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !widget.enabled,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.enabled ? 1.0 : 0.0,
                      child: TextField(
                        controller: widget.controller,
                        enabled: widget.enabled,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'CampusID',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                          suffix: Text(
                            '@student.gsu.edu',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => widget.onSubmitted?.call(),
                      ),
                    ),
                  ),
                ),
                // Merged email text (shown when disabled)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: !widget.enabled ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          '${widget.controller.text}@student.gsu.edu',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showEditButton)
            IconButton(
              onPressed: widget.onEditPressed,
              icon: Icon(
                Icons.edit,
                color: Colors.grey.shade600,
                size: 20,
              ),
              tooltip: 'Edit email',
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
