import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/date_blue_theme.dart';
import 'campus_badge.dart';

/// A photo card widget for the expanded profile view.
/// Can optionally show a name overlay (for the first photo).
class ProfilePhotoCard extends StatelessWidget {
  final String photoUrl;
  final bool showNameOverlay;
  final String? name;
  final int? age;
  final String? campus;
  final bool isFirst;

  const ProfilePhotoCard({
    super.key,
    required this.photoUrl,
    this.showNameOverlay = false,
    this.name,
    this.age,
    this.campus,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DateBlueTheme.radiusLarge),
      child: AspectRatio(
        aspectRatio: 3 / 4, // Standard portrait ratio
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo with caching
            CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DateBlueTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 100),
            ),

            // Name overlay for first photo
            if (showNameOverlay && name != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: DateBlueTheme.profileGradientOverlay,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and Age
                      Row(
                        children: [
                          Text(
                            name!,
                            style: DateBlueTheme.profileName,
                          ),
                          if (age != null && age! > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              age.toString(),
                              style: DateBlueTheme.profileAge,
                            ),
                          ],
                        ],
                      ),
                      
                      // Campus badge
                      if (campus != null) ...[
                        const SizedBox(height: 8),
                        CampusBadge(campusName: campus!),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
