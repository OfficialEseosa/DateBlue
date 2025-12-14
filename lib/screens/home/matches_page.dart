import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchesPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const MatchesPage({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF97CAEB),
      child: SafeArea(
        child: Center(
          child: Text(
            'Matches - Coming Soon',
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
