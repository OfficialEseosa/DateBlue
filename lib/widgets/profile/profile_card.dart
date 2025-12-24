import 'package:flutter/material.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';
import 'campus_badge.dart';
import 'expanded_profile_card.dart';

/// A compact profile card showing the main photo with name, age, and campus.
/// Tapping on it expands to show the full profile in a Hinge-style layout.
/// 
/// This widget is reusable for:
/// - Profile page (own profile)
/// - Discover page (other users' profiles when swiping)
class ProfileCard extends StatelessWidget {
  final ProfileData profile;
  final bool isOwnProfile;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onEditTap;
  final Widget? actionButtons;

  const ProfileCard({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.onSettingsTap,
    this.onEditTap,
    this.actionButtons,
  });

  void _showExpandedProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ExpandedProfileCard(
            profile: profile,
            isOwnProfile: isOwnProfile,
            onClose: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainPhotoUrl = profile.mediaUrls.isNotEmpty 
        ? profile.mediaUrls.first 
        : null;

    return GestureDetector(
      onTap: () => _showExpandedProfile(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DateBlueTheme.radiusLarge),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main Photo
            _buildMainPhoto(mainPhotoUrl),

            // Top-right action buttons (for own profile)
            if (isOwnProfile && (onSettingsTap != null || onEditTap != null))
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    if (onSettingsTap != null) ...[
                      _buildIconButton(
                        icon: Icons.settings,
                        onTap: onSettingsTap!,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (onEditTap != null)
                      _buildIconButton(
                        icon: Icons.edit,
                        onTap: onEditTap!,
                      ),
                  ],
                ),
              ),

            // Bottom content with gradient, name, age, and campus
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: DateBlueTheme.profileGradientOverlay,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and Age row
                    Row(
                      children: [
                        Text(
                          profile.firstName,
                          style: DateBlueTheme.profileName,
                        ),
                        if (profile.age != null && profile.age! > 0) ...[
                          const SizedBox(width: 12),
                          Text(
                            profile.age.toString(),
                            style: DateBlueTheme.profileAge,
                          ),
                        ],
                      ],
                    ),
                    
                    // Campus label (simple icon + text)
                    if (profile.campus != null) ...[
                      const SizedBox(height: 8),
                      CampusBadge(campusName: profile.campus!),
                    ],
                  ],
                ),
              ),
            ),

            // Custom action buttons (for discover page - like/pass buttons)
            if (actionButtons != null)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: actionButtons!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPhoto(String? photoUrl) {
    if (photoUrl != null) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  DateBlueTheme.primaryBlue,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.person,
        size: 100,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
