import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikesPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const LikesPage({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF97CAEB),
      child: SafeArea(
        child: Center(
          child: Text(
            'People who liked you - Coming Soon',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
