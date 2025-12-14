import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscoverPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const DiscoverPage({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF97CAEB),
      child: SafeArea(
        child: Center(
          child: Text(
            'Discover Page - Coming Soon',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
