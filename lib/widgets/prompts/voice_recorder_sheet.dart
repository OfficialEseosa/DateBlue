import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../screens/onboarding/models/prompt.dart';

/// A reusable voice recorder widget for voice prompts.
class VoiceRecorderSheet extends StatefulWidget {
  final String question;
  final Function(VoicePrompt voicePrompt) onSave;

  const VoiceRecorderSheet({
    super.key,
    required this.question,
    required this.onSave,
  });

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();

  /// Show this recorder as a bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String question,
    required Function(VoicePrompt voicePrompt) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecorderSheet(
        question: question,
        onSave: onSave,
      ),
    );
  }
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  late RecorderController _recorderController;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _localAudioPath;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorderController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_prompt_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorderController.record(path: path);

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingSeconds++);

        if (_recordingSeconds >= 10) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    if (_isRecording) {
      try {
        final path = await _recorderController.stop();
        setState(() {
          _localAudioPath = path;
          _isRecording = false;
        });
      } catch (e) {
        setState(() => _isRecording = false);
      }
    }
  }

  void _save() {
    if (_localAudioPath != null) {
      widget.onSave(VoicePrompt(
        question: widget.question,
        localPath: _localAudioPath,
        durationSeconds: _recordingSeconds,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0039A6),
            ),
          ),
          const SizedBox(height: 30),

          // Main recording button - the big circle
          GestureDetector(
            onTap: () async {
              if (_isRecording) {
                await _stopRecording();
              } else if (_localAudioPath == null) {
                await _startRecording();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red
                    : (_localAudioPath != null
                        ? Colors.green
                        : const Color(0xFF0039A6)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording
                            ? Colors.red
                            : (_localAudioPath != null
                                ? Colors.green
                                : const Color(0xFF0039A6)))
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isRecording
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop, color: Colors.white, size: 50),
                          const SizedBox(height: 4),
                          Text(
                            '${_recordingSeconds}s',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : (_localAudioPath != null
                        ? const Icon(Icons.check, color: Colors.white, size: 60)
                        : const Icon(Icons.mic, color: Colors.white, size: 60)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Status text
          Text(
            _isRecording
                ? 'Tap to stop (${10 - _recordingSeconds}s left)'
                : (_localAudioPath != null 
                    ? 'Recording complete!' 
                    : 'Tap the button to record'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _isRecording 
                  ? Colors.red 
                  : (_localAudioPath != null ? Colors.green[700] : Colors.grey[600]),
            ),
          ),

          const SizedBox(height: 32),

          // Bottom buttons - Cancel and Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _stopRecording();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _localAudioPath != null ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: _localAudioPath != null ? Colors.white : Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
