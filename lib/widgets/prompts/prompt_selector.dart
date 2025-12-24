import 'package:flutter/material.dart';
import '../../screens/onboarding/models/prompt.dart';

/// A reusable prompt selector showing prompts for a category.
/// User taps to select a prompt, then enters their answer.
class PromptSelector extends StatelessWidget {
  final String categoryName;
  final List<Prompt?> selectedPrompts;
  final Function(String question) onPromptSelected;

  const PromptSelector({
    super.key,
    required this.categoryName,
    required this.selectedPrompts,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final prompts = PromptTemplates.prompts[categoryName] ?? [];

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
          Text(
            categoryName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0039A6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to complete the sentence',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: prompts.length,
              itemBuilder: (context, index) {
                final promptText = prompts[index];
                final isSelected = selectedPrompts.any(
                  (p) => p?.question == promptText,
                );

                return GestureDetector(
                  onTap: isSelected
                      ? null
                      : () {
                          Navigator.pop(context);
                          onPromptSelected(promptText);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey[100] : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.grey[300]!
                            : const Color(0xFF0039A6).withValues(alpha: 0.3),
                        width: isSelected ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            promptText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.grey[500] : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Colors.green[400], size: 22)
                        else
                          Icon(Icons.edit, color: Colors.grey[400], size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show this selector as a bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String categoryName,
    required List<Prompt?> selectedPrompts,
    required Function(String question) onPromptSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PromptSelector(
        categoryName: categoryName,
        selectedPrompts: selectedPrompts,
        onPromptSelected: onPromptSelected,
      ),
    );
  }
}
