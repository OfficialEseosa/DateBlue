import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';

/// Bottom sheet for recording audio messages with preview before sending
class AudioRecorderSheet extends StatefulWidget {
  final Function(File audioFile, Duration duration) onRecordComplete;
  
  const AudioRecorderSheet({
    super.key,
    required this.onRecordComplete,
  });

  @override
  State<AudioRecorderSheet> createState() => _AudioRecorderSheetState();
}

class _AudioRecorderSheetState extends State<AudioRecorderSheet> {
  late RecorderController _recorderController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecording = false; // Recording finished, showing preview
  bool _isPlaying = false;
  String? _recordedPath;
  Duration _duration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.aac_adts
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 48000
      ..bitRate = 128000;
    
    // Listen to playback state
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      }
    });
    
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _playbackPosition = pos);
    });
    
    // Start recording automatically when sheet opens
    _startRecording();
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _recorderController.record(path: path);
      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _recordedPath = path;
        _duration = Duration.zero;
      });
      
      // Update duration every 100ms
      _updateDuration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _updateDuration() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _isRecording && !_isPaused) {
        setState(() {
          _duration += const Duration(milliseconds: 100);
        });
        _updateDuration();
      }
    });
  }

  Future<void> _pauseRecording() async {
    await _recorderController.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorderController.record();
    setState(() => _isPaused = false);
    _updateDuration();
  }

  Future<void> _stopRecording() async {
    final path = await _recorderController.stop();
    if (path != null && mounted) {
      await _audioPlayer.setFilePath(path);
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasRecording = true;
        _recordedPath = path;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_playbackPosition >= _duration && _duration > Duration.zero) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    }
  }

  Future<void> _reRecord() async {
    await _audioPlayer.stop();
    if (_recordedPath != null) {
      try {
        await File(_recordedPath!).delete();
      } catch (_) {}
    }
    await _startRecording();
  }

  Future<void> _send() async {
    if (_recordedPath != null && _duration.inSeconds >= 1) {
      await _audioPlayer.stop();
      widget.onRecordComplete(File(_recordedPath!), _duration);
      Navigator.pop(context);
    }
  }

  Future<void> _cancel() async {
    await _recorderController.stop();
    await _audioPlayer.stop();
    if (_recordedPath != null) {
      try {
        await File(_recordedPath!).delete();
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_hasRecording)
              _buildPreviewUI()
            else
              _buildRecordingUI(),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isPaused ? Colors.orange : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isPaused ? 'Paused' : 'Recording...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Duration
        Text(
          _formatDuration(_duration),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 48,
            fontWeight: FontWeight.w300,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 24),
        
        // Waveform
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AudioWaveforms(
            recorderController: _recorderController,
            size: Size(MediaQuery.of(context).size.width - 80, 60),
            waveStyle: WaveStyle(
              waveColor: AppColors.gsuBlue,
              extendWaveform: true,
              showMiddleLine: false,
              spacing: 4,
              waveThickness: 3,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Cancel button
            IconButton(
              onPressed: _cancel,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            
            // Pause/Resume button
            IconButton(
              onPressed: _isPaused ? _resumeRecording : _pauseRecording,
              icon: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            
            // Done (stop) button
            IconButton(
              onPressed: _duration.inSeconds >= 1 ? _stopRecording : null,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _duration.inSeconds >= 1 ? Colors.green : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Hint
        Text(
          'Record at least 1 second',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPreviewUI() {
    final progress = _duration.inMilliseconds > 0
        ? _playbackPosition.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    
    return Column(
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Preview your recording',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Playback card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Play button and duration
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.gsuBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDuration(_playbackPosition),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'of ${_formatDuration(_duration)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress bar (seekable)
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: AppColors.gsuBlue,
                  inactiveTrackColor: Colors.grey[600],
                  thumbColor: AppColors.gsuBlue,
                  overlayColor: AppColors.gsuBlue.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final position = Duration(
                      milliseconds: (value * _duration.inMilliseconds).toInt(),
                    );
                    _audioPlayer.seek(position);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Bottom buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Delete / Cancel
            IconButton(
              onPressed: _cancel,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
            ),
            
            // Re-record
            IconButton(
              onPressed: _reRecord,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 28),
              ),
            ),
            
            // Send
            IconButton(
              onPressed: _send,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gsuBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Delete', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text('Re-record', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text('Send', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
