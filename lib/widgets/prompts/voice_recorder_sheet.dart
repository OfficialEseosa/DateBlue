import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _localAudioPath;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.aac_adts
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 48000
      ..bitRate = 128000;
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
    
    // Listen to position changes
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    
    _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorderController.dispose();
    _audioPlayer.dispose();
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
      final path = '${dir.path}/voice_prompt_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorderController.record(path: path);

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _localAudioPath = null;
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
        
        if (path != null) {
          await _audioPlayer.setFilePath(path);
        }
      } catch (e) {
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_localAudioPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        // Reset to beginning if at end
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        setState(() => _isPlaying = true);
        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() => _isPlaying = false);
    }
  }

  void _discardRecording() {
    _audioPlayer.stop();
    setState(() {
      _localAudioPath = null;
      _recordingSeconds = 0;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  void _save() {
    if (_localAudioPath != null) {
      _audioPlayer.stop();
      widget.onSave(VoicePrompt(
        question: widget.question,
        localPath: _localAudioPath,
        durationSeconds: _recordingSeconds,
      ));
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds;
    return '${seconds}s';
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

          // Show different UI based on state
          if (_localAudioPath != null)
            _buildPlaybackUI()
          else
            _buildRecordingUI(),

          const SizedBox(height: 32),

          // Bottom buttons
          _buildBottomButtons(),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      children: [
        // Main recording button
        GestureDetector(
          onTap: () async {
            if (_isRecording) {
              await _stopRecording();
            } else {
              await _startRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : const Color(0xFF0039A6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : const Color(0xFF0039A6))
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
                  : const Icon(Icons.mic, color: Colors.white, size: 60),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Status text
        Text(
          _isRecording
              ? 'Tap to stop (${10 - _recordingSeconds}s left)'
              : 'Tap the button to record',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _isRecording ? Colors.red : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackUI() {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        // Audio player card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Playback controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Discard button
                  GestureDetector(
                    onTap: _discardRecording,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 26,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Play/Pause button
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0039A6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0039A6).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Duration display
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_recordingSeconds}s',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0039A6)),
                  minHeight: 6,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Success message
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Listen, re-record, or save',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _audioPlayer.stop();
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
    );
  }
}
