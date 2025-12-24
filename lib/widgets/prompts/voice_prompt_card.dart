import 'package:flutter/material.dart';
import '../../screens/onboarding/models/prompt.dart';

/// A reusable card displaying a saved voice prompt with playback controls.
class VoicePromptCard extends StatelessWidget {
  final VoicePrompt voicePrompt;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const VoicePromptCard({
    super.key,
    required this.voicePrompt,
    required this.isPlaying,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.green[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voicePrompt.question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${voicePrompt.durationSeconds}s recording',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 20, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
