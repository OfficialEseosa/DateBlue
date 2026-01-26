import 'package:flutter/material.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';
import 'profile_photo_card.dart';
import 'profile_prompt_card.dart';
import 'profile_vitals_card.dart';
import 'voice_prompt_player_card.dart';

/// A full-screen expanded profile view in Hinge-style layout.
/// Shows photos, prompts, and vitals interleaved in a scrollable view.
/// Uses Hero animation for seamless transition from compact card.
class ExpandedProfileCard extends StatefulWidget {
  final ProfileData profile;
  final bool isOwnProfile;
  final VoidCallback? onClose;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final String? heroTag;

  const ExpandedProfileCard({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.onClose,
    this.onLike,
    this.onPass,
    this.heroTag,
  });

  @override
  State<ExpandedProfileCard> createState() => _ExpandedProfileCardState();
}

class _ExpandedProfileCardState extends State<ExpandedProfileCard> {
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

    return Scaffold(
      backgroundColor: DateBlueTheme.surfaceGrey,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Top padding
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 16),
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

          // Action buttons at bottom
          if (!widget.isOwnProfile && (widget.onLike != null || widget.onPass != null))
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: _buildActionButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  /// Build the interleaved content list with categorized sections
  /// Pattern: Photo 1 -> Basics -> Prompt 1 -> Photo 2 -> Identity -> Prompt 2 -> Photo 3 -> Lifestyle -> Prompt 3 -> Relationship
  List<Widget> _buildContentItems() {
    final items = <Widget>[];
    final photos = widget.profile.mediaUrls;
    final prompts = widget.profile.prompts;

    // First photo with name overlay (Hero wrapped)
    if (photos.isNotEmpty) {
      Widget photoWidget = ProfilePhotoCard(
        photoUrl: photos.first,
        showNameOverlay: true,
        name: widget.profile.firstName,
        age: widget.profile.age,
        campus: widget.profile.campus,
        isFirst: true,
      );
      
      // Wrap in Hero if tag provided
      if (widget.heroTag != null) {
        photoWidget = Hero(
          tag: widget.heroTag!,
          child: Material(
            type: MaterialType.transparency,
            child: photoWidget,
          ),
        );
      }
      items.add(photoWidget);
    }

    // Basics section
    if (widget.profile.basicsVitals.isNotEmpty) {
      items.add(ProfileVitalsSection(
        title: 'Basics',
        headerIcon: Icons.info_outline,
        vitals: widget.profile.basicsVitals,
      ));
    }

    // Interleave prompts and photos with remaining sections
    int photoIndex = 1;
    int promptIndex = 0;

    // Prompt 1
    if (promptIndex < prompts.length) {
      items.add(ProfilePromptCard(prompt: prompts[promptIndex]));
      promptIndex++;
    }

    // Voice prompt (after first text prompt)
    if (widget.profile.voicePrompt != null && widget.profile.voicePrompt!.audioUrl != null) {
      items.add(VoicePromptPlayerCard(voicePrompt: widget.profile.voicePrompt!));
    }

    // Photo 2
    if (photoIndex < photos.length) {
      items.add(ProfilePhotoCard(photoUrl: photos[photoIndex], showNameOverlay: false));
      photoIndex++;
    }

    // Identity section
    if (widget.profile.identityVitals.isNotEmpty) {
      items.add(ProfileVitalsSection(
        title: 'Identity',
        headerIcon: Icons.person_outline,
        vitals: widget.profile.identityVitals,
      ));
    }

    // Prompt 2
    if (promptIndex < prompts.length) {
      items.add(ProfilePromptCard(prompt: prompts[promptIndex]));
      promptIndex++;
    }

    // Photo 3
    if (photoIndex < photos.length) {
      items.add(ProfilePhotoCard(photoUrl: photos[photoIndex], showNameOverlay: false));
      photoIndex++;
    }

    // Lifestyle section
    if (widget.profile.lifestyleVitals.isNotEmpty) {
      items.add(ProfileVitalsSection(
        title: 'Lifestyle',
        headerIcon: Icons.spa,
        vitals: widget.profile.lifestyleVitals,
      ));
    }

    // Prompt 3
    if (promptIndex < prompts.length) {
      items.add(ProfilePromptCard(prompt: prompts[promptIndex]));
      promptIndex++;
    }

    // Photo 4+
    if (photoIndex < photos.length) {
      items.add(ProfilePhotoCard(photoUrl: photos[photoIndex], showNameOverlay: false));
      photoIndex++;
    }

    // Relationship section
    if (widget.profile.relationshipVitals.isNotEmpty) {
      items.add(ProfileVitalsSection(
        title: 'Looking for',
        headerIcon: Icons.favorite_border,
        vitals: widget.profile.relationshipVitals,
      ));
    }

    // Remaining prompts and photos
    while (promptIndex < prompts.length || photoIndex < photos.length) {
      if (promptIndex < prompts.length) {
        items.add(ProfilePromptCard(prompt: prompts[promptIndex]));
        promptIndex++;
      }
      if (photoIndex < photos.length) {
        items.add(ProfilePhotoCard(photoUrl: photos[photoIndex], showNameOverlay: false));
        photoIndex++;
      }
    }

    return items;
  }
}
