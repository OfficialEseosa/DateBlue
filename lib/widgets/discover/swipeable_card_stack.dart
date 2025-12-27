import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/profile_data.dart';
import '../profile/profile_card.dart';

/// Swipeable card stack with animations for discover page
class SwipeableCardStack extends StatefulWidget {
  final List<ProfileData> profiles;
  final Function(ProfileData) onLike;
  final Function(ProfileData) onPass;
  final VoidCallback? onEmpty;

  const SwipeableCardStack({
    super.key,
    required this.profiles,
    required this.onLike,
    required this.onPass,
    this.onEmpty,
  });

  @override
  State<SwipeableCardStack> createState() => SwipeableCardStackState();
}

class SwipeableCardStackState extends State<SwipeableCardStack> with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;
  
  Offset _dragOffset = Offset.zero;
  int _currentIndex = 0;
  
  /// Expose current index for pagination logic
  int get currentIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(_swipeController);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (_dragOffset.dx.abs() > screenWidth * 0.3 || velocity.dx.abs() > 800) {
      _animateSwipeAway(_dragOffset.dx > 0);
    } else {
      _snapBack();
    }
  }

  void _animateSwipeAway(bool isRight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final endOffset = Offset(isRight ? screenWidth * 1.5 : -screenWidth * 1.5, _dragOffset.dy);
    
    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: endOffset).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx / screenWidth * 0.3,
      end: isRight ? 0.3 : -0.3,
    ).animate(_swipeController);
    
    _swipeController.forward().then((_) => _onSwipeComplete(isRight));
  }

  void _snapBack() {
    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx / MediaQuery.of(context).size.width * 0.3,
      end: 0,
    ).animate(_swipeController);
    
    _swipeController.forward().then((_) {
      _swipeController.reset();
      setState(() => _dragOffset = Offset.zero);
    });
  }

  void _onSwipeComplete(bool isLike) {
    final profile = widget.profiles[_currentIndex];
    if (isLike) {
      widget.onLike(profile);
    } else {
      widget.onPass(profile);
    }
    
    _swipeController.reset();
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
    });
    
    if (_currentIndex >= widget.profiles.length) {
      widget.onEmpty?.call();
    }
  }

  /// Programmatic like (for button)
  void like() {
    if (_currentIndex < widget.profiles.length) {
      _animateSwipeAway(true);
    }
  }

  /// Programmatic pass (for button)
  void pass() {
    if (_currentIndex < widget.profiles.length) {
      _animateSwipeAway(false);
    }
  }

  /// Reset to show first profile (for undo)
  void reset() {
    setState(() {
      _currentIndex = 0;
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.profiles.length) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Background card (next profile)
        if (_currentIndex + 1 < widget.profiles.length)
          Positioned.fill(
            child: Transform.scale(
              scale: 0.95,
              child: Opacity(
                opacity: 0.7,
                child: ProfileCard(profile: widget.profiles[_currentIndex + 1]),
              ),
            ),
          ),
        
        // Top card (current profile)
        Positioned.fill(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: AnimatedBuilder(
              animation: _swipeController,
              builder: (context, child) {
                final offset = _swipeController.isAnimating ? _swipeAnimation.value : _dragOffset;
                final rotation = _swipeController.isAnimating
                    ? _rotationAnimation.value
                    : _dragOffset.dx / MediaQuery.of(context).size.width * 0.3;
                
                return Transform(
                  transform: Matrix4.identity()
                    ..setTranslationRaw(offset.dx, offset.dy, 0)
                    ..rotateZ(rotation),
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: Stack(
                children: [
                  ProfileCard(
                    profile: widget.profiles[_currentIndex],
                    onLike: like,
                    onPass: pass,
                  ),
                  _buildSwipeOverlay(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeOverlay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = (_dragOffset.dx / (screenWidth * 0.3)).clamp(-1.0, 1.0);
    
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // LIKE indicator
            Positioned(
              left: 30,
              top: 50,
              child: Opacity(
                opacity: progress.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: -math.pi / 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('LIKE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ),
              ),
            ),
            // NOPE indicator
            Positioned(
              right: 30,
              top: 50,
              child: Opacity(
                opacity: (-progress).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: math.pi / 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('NOPE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text('No more profiles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Check back later for more', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
