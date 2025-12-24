import 'package:flutter/material.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';

/// A card displaying a profile prompt with question and answer.
/// Styled like Hinge prompt cards.
class ProfilePromptCard extends StatelessWidget {
  final ProfilePrompt prompt;

  const ProfilePromptCard({
    super.key,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context) {
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
          // Category indicator line
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DateBlueTheme.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Question
          Text(
            prompt.question,
            style: DateBlueTheme.promptQuestion,
          ),
          const SizedBox(height: 12),
          
          // Answer
          Text(
            prompt.text,
            style: DateBlueTheme.promptAnswer,
          ),
        ],
      ),
    );
  }
}
