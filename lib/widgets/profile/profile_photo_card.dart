import 'package:flutter/material.dart';
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
            // Photo
            Image.network(
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
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                );
              },
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
