import 'package:flutter/material.dart';
import '../../screens/onboarding/models/prompt.dart';

/// A reusable category picker for prompts.
/// Shows categories in a card-based layout with emojis.
class PromptCategoryPicker extends StatelessWidget {
  final Function(String categoryName) onCategorySelected;

  const PromptCategoryPicker({
    super.key,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pick a Category',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0039A6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose what you want to talk about',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: PromptCategory.all.length,
              itemBuilder: (context, index) {
                final category = PromptCategory.all[index];
                return _buildCategoryCard(context, category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, PromptCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onCategorySelected(category.name);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  category.icon,
                  size: 26,
                  color: const Color(0xFF0039A6),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// Show this picker as a bottom sheet
  static Future<void> show({
    required BuildContext context,
    required Function(String categoryName) onCategorySelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PromptCategoryPicker(
        onCategorySelected: onCategorySelected,
      ),
    );
  }
}
