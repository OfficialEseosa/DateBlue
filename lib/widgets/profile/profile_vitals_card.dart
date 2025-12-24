import 'package:flutter/material.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';

/// A card displaying user vitals/facts in a grid layout.
/// Uses Material Icons for a professional look.
class ProfileVitalsCard extends StatelessWidget {
  final List<ProfileVital> vitals;

  const ProfileVitalsCard({
    super.key,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DateBlueTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: DateBlueTheme.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About me',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DateBlueTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Vitals grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vitals.map((vital) => _buildVitalChip(vital)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalChip(ProfileVital vital) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DateBlueTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DateBlueTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            vital.icon,
            size: 16,
            color: DateBlueTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              vital.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DateBlueTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
