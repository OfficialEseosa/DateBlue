import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home/discover_page.dart';
import 'home/likes_page.dart';
import 'home/matches_page.dart';
import 'home/profile_page.dart';
import '../services/notification_service.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    NotificationService().initialize(widget.user.uid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache main photo if available
    if (_userData?['mediaUrls'] != null &&
        (_userData!['mediaUrls'] as List).isNotEmpty) {
      final mainPhotoUrl = (_userData!['mediaUrls'] as List)[0] as String;
      precacheImage(NetworkImage(mainPhotoUrl), context);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        
        // Precache main photo immediately (await to ensure it's ready)
        if (data?['mediaUrls'] != null &&
            (data!['mediaUrls'] as List).isNotEmpty) {
          final mediaUrls = data['mediaUrls'] as List;
          final mainPhotoUrl = mediaUrls[0] as String;
          
          // Await the main photo precache so it's ready when user goes to profile
          await precacheImage(NetworkImage(mainPhotoUrl), context);
          
          // Precache other photos in background (don't await)
          for (int i = 1; i < mediaUrls.length; i++) {
            precacheImage(NetworkImage(mediaUrls[i] as String), context);
          }
        }
        
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF97CAEB),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF97CAEB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  'assets/images/GSU_Auburn-Ave01.jpg',
                  fit: BoxFit.cover,
                ),
                // Gradient overlay - fades to page color at bottom
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF97CAEB).withValues(alpha: 0.6),
                        const Color(0xFF97CAEB).withValues(alpha: 0.85),
                        const Color(0xFF97CAEB),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
                // Title - centered vertically and horizontally
                SafeArea(
                  child: Center(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Date',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Blue',
                            style: TextStyle(color: Color(0xFF0039A6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return DiscoverPage(user: widget.user, userData: _userData);
      case 1:
        return LikesPage(user: widget.user, userData: _userData);
      case 2:
        return MatchesPage(user: widget.user, userData: _userData);
      case 3:
        return ProfilePage(user: widget.user, userData: _userData);
      default:
        return DiscoverPage(user: widget.user, userData: _userData);
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AnimatedNavIcon(
                icon: Icons.explore,
                index: 0,
                isSelected: _currentIndex == 0,
                animationType: NavAnimationType.spin,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _AnimatedNavIcon(
                icon: Icons.favorite,
                index: 1,
                isSelected: _currentIndex == 1,
                animationType: NavAnimationType.pulse,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _AnimatedNavIcon(
                icon: Icons.chat_bubble,
                index: 2,
                isSelected: _currentIndex == 2,
                animationType: NavAnimationType.bounce,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _AnimatedNavIcon(
                icon: Icons.person,
                index: 3,
                isSelected: _currentIndex == 3,
                animationType: NavAnimationType.pop,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum NavAnimationType { spin, pulse, bounce, pop }

/// Animated navigation icon with unique animation per type
class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final int index;
  final bool isSelected;
  final NavAnimationType animationType;
  final VoidCallback onTap;

  const _AnimatedNavIcon({
    required this.icon,
    required this.index,
    required this.isSelected,
    required this.animationType,
    required this.onTap,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _wasSelected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.animationType == NavAnimationType.spin ? 500 : 300),
      vsync: this,
    );
    _wasSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(_AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when becoming selected (but wasn't before)
    if (widget.isSelected && !_wasSelected) {
      _controller.forward(from: 0);
    }
    _wasSelected = widget.isSelected;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? const Color(0xFF0039A6) : Colors.grey;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF0039A6).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: _getTransform(),
              child: Icon(widget.icon, color: color, size: 28),
            );
          },
        ),
      ),
    );
  }

  Matrix4 _getTransform() {
    final progress = _controller.value;
    
    switch (widget.animationType) {
      case NavAnimationType.spin:
        // Full 360° spin
        return Matrix4.identity()..rotateZ(progress * 2 * 3.14159);
      
      case NavAnimationType.pulse:
        // Pulse bigger then back
        final scale = 1.0 + (0.3 * (1 - (2 * progress - 1).abs()));
        return Matrix4.identity()..scale(scale, scale);
      
      case NavAnimationType.bounce:
        // Bounce up and down
        final bounce = -8 * (1 - (2 * progress - 1).abs());
        return Matrix4.identity()..translate(0.0, bounce);
      
      case NavAnimationType.pop:
        // Pop scale effect
        final scale = 1.0 + (0.25 * (1 - (2 * progress - 1).abs()));
        return Matrix4.identity()..scale(scale, scale);
    }
  }
}
