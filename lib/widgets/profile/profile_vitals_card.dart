import 'package:flutter/material.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';

/// A section card displaying a category of vitals in a vertical list layout.
/// Used in the expanded profile view for organized display of user info.
class ProfileVitalsSection extends StatelessWidget {
  final String title;
  final IconData headerIcon;
  final List<ProfileVital> vitals;

  const ProfileVitalsSection({
    super.key,
    required this.title,
    required this.headerIcon,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DateBlueTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DateBlueTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  headerIcon,
                  color: DateBlueTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: DateBlueTheme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Vitals list
          ...vitals.asMap().entries.map((entry) {
            final isLast = entry.key == vitals.length - 1;
            return _buildVitalRow(entry.value, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildVitalRow(ProfileVital vital, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DateBlueTheme.surfaceGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  vital.icon,
                  color: DateBlueTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Label and value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vital.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: DateBlueTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vital.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DateBlueTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: Colors.grey.shade200,
            height: 1,
          ),
      ],
    );
  }
}

/// Legacy ProfileVitalsCard - kept for backwards compatibility.
/// Consider using ProfileVitalsSection for better organization.
class ProfileVitalsCard extends StatelessWidget {
  final List<ProfileVital> vitals;

  const ProfileVitalsCard({
    super.key,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileVitalsSection(
      title: 'About me',
      headerIcon: Icons.person_outline,
      vitals: vitals,
    );
  }
}
