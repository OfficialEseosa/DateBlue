import 'package:flutter/material.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';
import 'profile_photo_card.dart';
import 'profile_prompt_card.dart';
import 'profile_vitals_card.dart';

/// A full-screen expanded profile view in Hinge-style layout.
/// Shows photos, prompts, and vitals interleaved in a scrollable view.
/// Supports swipe-down to dismiss gesture.
/// 
/// Layout pattern: Photo -> Vitals -> Prompt -> Photo -> Prompt -> Photo...
class ExpandedProfileCard extends StatefulWidget {
  final ProfileData profile;
  final bool isOwnProfile;
  final VoidCallback? onClose;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  const ExpandedProfileCard({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.onClose,
    this.onLike,
    this.onPass,
  });

  @override
  State<ExpandedProfileCard> createState() => _ExpandedProfileCardState();
}

class _ExpandedProfileCardState extends State<ExpandedProfileCard>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isAtTop => !_scrollController.hasClients || _scrollController.offset <= 0;

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isAtTop) {
      _isDragging = true;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging && _isAtTop && details.delta.dy > 0) {
      _isDragging = true;
    }
    
    if (_isDragging) {
      setState(() {
        _dragOffset += details.delta.dy;
        if (_dragOffset < 0) _dragOffset = 0;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    _isDragging = false;
    
    // Dismiss if dragged far enough or with enough velocity
    if (_dragOffset > 150 || details.velocity.pixelsPerSecond.dy > 800) {
      _animateOut();
    } else {
      _snapBack();
    }
  }

  void _animateOut() {
    final screenHeight = MediaQuery.of(context).size.height;
    _animationController.duration = const Duration(milliseconds: 200);
    
    final animation = Tween<double>(
      begin: _dragOffset,
      end: screenHeight,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    animation.addListener(() {
      if (mounted) setState(() => _dragOffset = animation.value);
    });
    
    _animationController.forward(from: 0).then((_) {
      _close();
    });
  }

  void _snapBack() {
    _animationController.duration = const Duration(milliseconds: 200);
    
    final animation = Tween<double>(
      begin: _dragOffset,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    animation.addListener(() {
      if (mounted) setState(() => _dragOffset = animation.value);
    });
    
    _animationController.forward(from: 0);
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentItems = _buildContentItems();
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate opacity for background fade
    final progress = (_dragOffset / screenHeight).clamp(0.0, 1.0);

    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5 * (1 - progress)),
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Scaffold(
            backgroundColor: DateBlueTheme.surfaceGrey,
            body: Stack(
              children: [
                // Scrollable content
                CustomScrollView(
                  controller: _scrollController,
                  physics: _isDragging 
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  slivers: [
                    // Drag handle indicator (visual hint)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 12,
                            bottom: 12,
                          ),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                    
                    // Profile content
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= contentItems.length) return null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: contentItems[index],
                            );
                          },
                          childCount: contentItems.length,
                        ),
                      ),
                    ),

                    // Bottom padding for action buttons
                    SliverPadding(padding: EdgeInsets.only(bottom: widget.isOwnProfile ? 40 : 120)),
                  ],
                ),

                // Fixed close button at top
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: _buildCloseButton(context),
                ),

                // Action buttons at bottom (only for other profiles)
                if (!widget.isOwnProfile && (widget.onLike != null || widget.onPass != null))
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                    left: 0,
                    right: 0,
                    child: _buildActionButtons(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pass button (red X)
        if (widget.onPass != null)
          GestureDetector(
            onTap: () {
              widget.onPass!();
              _close();
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 32),
            ),
          ),
        if (widget.onPass != null && widget.onLike != null)
          const SizedBox(width: 40),
        // Like button (blue heart)
        if (widget.onLike != null)
          GestureDetector(
            onTap: () {
              widget.onLike!();
              _close();
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: Color(0xFF0039A6), size: 32),
            ),
          ),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.close,
          color: DateBlueTheme.textPrimary,
          size: 24,
        ),
      ),
    );
  }

  /// Build the interleaved content list
  /// Pattern: Photo 1 (with name) -> Vitals -> Prompt 1 -> Photo 2 -> Prompt 2 -> Photo 3 -> Prompt 3...
  List<Widget> _buildContentItems() {
    final items = <Widget>[];
    final photos = widget.profile.mediaUrls;
    final prompts = widget.profile.prompts;
    final vitals = widget.profile.visibleVitals;

    // First photo with name overlay
    if (photos.isNotEmpty) {
      items.add(ProfilePhotoCard(
        photoUrl: photos.first,
        showNameOverlay: true,
        name: widget.profile.firstName,
        age: widget.profile.age,
        campus: widget.profile.campus,
        isFirst: true,
      ));
    }

    // Vitals card (if any vitals to show)
    if (vitals.isNotEmpty) {
      items.add(ProfileVitalsCard(vitals: vitals));
    }

    // Interleave remaining photos and prompts
    int photoIndex = 1;
    int promptIndex = 0;

    // First add prompts with interleaved photos
    while (promptIndex < prompts.length || photoIndex < photos.length) {
      // Add a prompt
      if (promptIndex < prompts.length) {
        items.add(ProfilePromptCard(prompt: prompts[promptIndex]));
        promptIndex++;
      }

      // Add a photo after every prompt (if available)
      if (photoIndex < photos.length) {
        items.add(ProfilePhotoCard(
          photoUrl: photos[photoIndex],
          showNameOverlay: false,
        ));
        photoIndex++;
      }
    }

    // If there are more photos than prompts, add remaining photos
    while (photoIndex < photos.length) {
      items.add(ProfilePhotoCard(
        photoUrl: photos[photoIndex],
        showNameOverlay: false,
      ));
      photoIndex++;
    }

    return items;
  }
}
