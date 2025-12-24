import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class PhotoPermissionStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const PhotoPermissionStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PhotoPermissionStep> createState() => _PhotoPermissionStepState();
}

class _PhotoPermissionStepState extends State<PhotoPermissionStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    widget.onNext({});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Camera Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera,
                          size: 60,
                          color: Color(0xFF0039A6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Main Text
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'Time to show off\nhow a real Panther\nlooks like!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0039A6),
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Add photos and videos to your profile to help others get to know you better',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Permission Info Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'You can add up to 6 photos or videos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        OnboardingBottomBar(
          onBack: widget.onBack,
          onContinue: _handleContinue,
          continueText: 'Add Photos & Videos',
        ),
      ],
    );
  }
}
