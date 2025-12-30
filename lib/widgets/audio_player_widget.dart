import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_colors.dart';

/// Widget for playing audio messages with waveform visualization
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final Duration? duration;
  final bool isMine;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.duration,
    this.isMine = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final duration = await _audioPlayer.setUrl(widget.audioUrl);
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? widget.duration ?? Duration.zero;
          _isLoading = false;
        });
      }
      
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
          if (state.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMine ? Colors.white : AppColors.gsuBlue;
    final bgColor = widget.isMine ? AppColors.gsuBlue : Colors.grey[100];
    final textColor = widget.isMine ? Colors.white70 : Colors.grey[600];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: color,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Seekable progress slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seekable slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.2),
                    thumbColor: color,
                    overlayColor: color.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _totalDuration.inMilliseconds > 0
                        ? _position.inMilliseconds.toDouble().clamp(0, _totalDuration.inMilliseconds.toDouble())
                        : 0,
                    max: _totalDuration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: _isLoading ? null : (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                
                // Duration
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_totalDuration)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Mic icon
          Icon(
            Icons.mic,
            color: color.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }
}
