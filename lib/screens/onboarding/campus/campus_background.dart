import 'package:flutter/material.dart';
import 'campus_data.dart';

/// Animated background that crossfades between campus images
class CampusBackground extends StatelessWidget {
  final CampusInfo selectedCampus;

  const CampusBackground({
    super.key,
    required this.selectedCampus,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Campus-specific background with crossfade
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
            selectedCampus.imageAsset,
            key: ValueKey(selectedCampus.name),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        
        // Gradient overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0039A6).withValues(alpha: 0.75),
                const Color(0xFF0039A6).withValues(alpha: 0.90),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
