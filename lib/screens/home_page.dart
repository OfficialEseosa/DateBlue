import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home/discover_page.dart';
import 'home/likes_page.dart';
import 'home/matches_page.dart';
import 'home/profile_page.dart';

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
              _buildNavItem(
                icon: Icons.explore,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.favorite,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble,
                index: 2,
              ),
              _buildProfileNavItem(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return _AnimatedNavButton(
      isSelected: isSelected,
      onTap: () => setState(() => _currentIndex = index),
      child: Icon(
        icon,
        color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
        size: 28,
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final isSelected = _currentIndex == 3;
    return _AnimatedNavButton(
      isSelected: isSelected,
      onTap: () => setState(() => _currentIndex = 3),
      child: Icon(
        Icons.person,
        color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
        size: 28,
      ),
    );
  }
}

/// Animated navigation button with scale effect on tap
class _AnimatedNavButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedNavButton({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<_AnimatedNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF0039A6).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

