import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';

/// A card for playing voice prompts in the expanded profile view.
/// Shows the question, waveform visualization, and play controls.
class VoicePromptPlayerCard extends StatefulWidget {
  final ProfileVoicePrompt voicePrompt;

  const VoicePromptPlayerCard({
    super.key,
    required this.voicePrompt,
  });

  @override
  State<VoicePromptPlayerCard> createState() => _VoicePromptPlayerCardState();
}

class _VoicePromptPlayerCardState extends State<VoicePromptPlayerCard> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (widget.voicePrompt.audioUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        
        if (_audioPlayer.audioSource == null) {
          await _audioPlayer.setUrl(widget.voicePrompt.audioUrl!);
        }
        
        setState(() => _isLoading = false);
        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error playing voice prompt: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.voicePrompt.durationSeconds;
    final displayDuration = _duration.inSeconds > 0 
        ? _duration 
        : Duration(seconds: totalSeconds);
    final progress = displayDuration.inMilliseconds > 0 
        ? (_position.inMilliseconds / displayDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark background
        borderRadius: BorderRadius.circular(DateBlueTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice icon and label
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DateBlueTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Voice Prompt',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Question
          Text(
            widget.voicePrompt.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          
          // Waveform and controls row
          Row(
            children: [
              // Play button
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DateBlueTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Waveform visualization
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waveform bars
                    SizedBox(
                      height: 32,
                      child: CustomPaint(
                        painter: _WaveformPainter(
                          progress: progress,
                          activeColor: DateBlueTheme.primaryBlue,
                          inactiveColor: Colors.white24,
                          waveformData: widget.voicePrompt.waveformData,
                        ),
                        size: const Size(double.infinity, 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          _formatDuration(displayDuration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for waveform visualization
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final List<double>? waveformData;

  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.waveformData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final barSpacing = 3.0;
    final totalBarWidth = barWidth + barSpacing;
    final barCount = (size.width / totalBarWidth).floor();
    final activePaint = Paint()..color = activeColor;
    final inactivePaint = Paint()..color = inactiveColor;

    // Use real waveform data
    if (waveformData == null || waveformData!.isEmpty) return;
    
    final heights = _resampleWaveform(waveformData!, barCount);

    for (int i = 0; i < barCount; i++) {
      final x = i * totalBarWidth;
      final barHeight = size.height * heights[i].clamp(0.15, 1.0);
      final y = (size.height - barHeight) / 2;
      
      final isActive = i / barCount <= progress;
      final paint = isActive ? activePaint : inactivePaint;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  List<double> _resampleWaveform(List<double> data, int targetCount) {
    if (data.length == targetCount) return data;
    
    final result = <double>[];
    final step = data.length / targetCount;
    
    for (int i = 0; i < targetCount; i++) {
      final startIdx = (i * step).floor();
      final endIdx = ((i + 1) * step).floor().clamp(0, data.length);
      
      if (startIdx >= data.length) {
        result.add(0.3);
        continue;
      }
      
      // Average samples in this bucket
      double sum = 0;
      int count = 0;
      for (int j = startIdx; j < endIdx && j < data.length; j++) {
        sum += data[j];
        count++;
      }
      
      result.add(count > 0 ? sum / count : 0.3);
    }
    
    return result;
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveformData != waveformData;
  }
}
