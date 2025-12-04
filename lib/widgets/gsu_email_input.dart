import 'package:flutter/material.dart';

class GsuEmailInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final VoidCallback? onSubmitted;

  const GsuEmailInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.showEditButton = false,
    this.onEditPressed,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'CampusID (e.g. jdoe67)',
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                suffixText: '@student.gsu.edu',
                suffixStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted?.call(),
            ),
          ),
          if (showEditButton)
            IconButton(
              onPressed: onEditPressed,
              icon: Icon(
                Icons.edit,
                color: Colors.grey.shade600,
                size: 20,
              ),
              tooltip: 'Edit email',
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
