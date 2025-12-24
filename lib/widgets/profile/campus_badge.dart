import 'package:flutter/material.dart';

/// A simple campus label showing the school icon and campus name.
/// Matches the original clean design with just Icon + Text in white.
class CampusBadge extends StatelessWidget {
  final String campusName;
  final bool compact;

  const CampusBadge({
    super.key,
    required this.campusName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.school,
          color: Colors.white,
          size: compact ? 14 : 16,
        ),
        const SizedBox(width: 4),
        Text(
          campusName,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 12 : 14,
          ),
        ),
      ],
    );
  }
}
