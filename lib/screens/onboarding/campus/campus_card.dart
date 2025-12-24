import 'package:flutter/material.dart';
import 'campus_data.dart';

/// Individual campus selection card - simple text with selection indicator
class CampusCard extends StatelessWidget {
  final CampusInfo campus;
  final bool isSelected;
  final VoidCallback onTap;

  const CampusCard({
    super.key,
    required this.campus,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0039A6).withValues(alpha: 0.1)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0039A6)
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Campus name
                Expanded(
                  child: Text(
                    campus.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF0039A6)
                          : Colors.black87,
                    ),
                  ),
                ),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? const Color(0xFF0039A6)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF0039A6)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected 
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

