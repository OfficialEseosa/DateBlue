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
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });

        if (_userData?['mediaUrls'] != null &&
            (_userData!['mediaUrls'] as List).isNotEmpty) {
          final mainPhotoUrl = (_userData!['mediaUrls'] as List)[0] as String;
          precacheImage(NetworkImage(mainPhotoUrl), context);
        }
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
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/GSU_Auburn-Ave01.jpg',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF97CAEB).withOpacity(0.7),
                      const Color(0xFF97CAEB).withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ],
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
            color: Colors.black.withOpacity(0.1),
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
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final isSelected = _currentIndex == 3;
    return InkWell(
      onTap: () => setState(() => _currentIndex = 3),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          Icons.person,
          color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
