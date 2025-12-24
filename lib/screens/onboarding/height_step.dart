import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';
import '../../widgets/height_picker.dart';

class HeightStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const HeightStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  bool _showOnProfile = true;
  bool _isLoading = false;
  int _heightCm = 170;

  @override
  void initState() {
    super.initState();
    
    final savedHeightCm = widget.initialData['heightCm'];
    _showOnProfile = widget.initialData['showHeightOnProfile'] ?? true;

    if (savedHeightCm != null && savedHeightCm is int) {
      _heightCm = HeightUtils.clampCm(savedHeightCm);
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'heightCm': _heightCm,
        'showHeightOnProfile': _showOnProfile,
        'onboardingStep': 8,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(data);

      if (mounted) {
        widget.onNext(data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'What is your height?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps with matching preferences',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Height picker
                  Expanded(
                    child: Center(
                      child: HeightPicker(
                        initialHeightCm: _heightCm,
                        initialUseFeet: true,
                        onHeightChanged: (cm) {
                          setState(() => _heightCm = cm);
                        },
                      ),
                    ),
                  ),
                  
                  // Visibility toggle
                  _buildVisibilityToggle(),
                  
                  // Privacy info
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: !_showOnProfile
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildPrivacyInfo(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        OnboardingBottomBar(
          onBack: widget.onBack,
          onContinue: _saveAndContinue,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Show on profile',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Others will see your height',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _showOnProfile,
            onChanged: (value) {
              setState(() => _showOnProfile = value);
            },
            activeThumbColor: const Color(0xFF0039A6),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your height will be saved but hidden from your profile.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
