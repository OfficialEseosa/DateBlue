import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campus/campus_data.dart';
import 'campus/campus_card.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class CampusStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const CampusStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CampusStep> createState() => _CampusStepState();
}

class _CampusStepState extends State<CampusStep> {
  CampusInfo? _selectedCampus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSelection();
  }

  void _loadInitialSelection() {
    final savedCampusName = widget.initialData['campus'] as String?;
    if (savedCampusName != null) {
      _selectedCampus = campusList.firstWhere(
        (c) => c.name == savedCampusName,
        orElse: () => campusList.first,
      );
    } else {
      // Default to Atlanta Campus (first in the list)
      _selectedCampus = campusList.first;
    }
  }

  void _selectCampus(CampusInfo campus) {
    setState(() {
      _selectedCampus = campus;
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selectedCampus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your campus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'campus': _selectedCampus!.name,
        'onboardingStep': 3,
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
          child: _buildContent(),
        ),
        OnboardingBottomBar(
          onBack: widget.onBack,
          onContinue: _saveAndContinue,
          isLoading: _isLoading,
          canContinue: _selectedCampus != null,
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Header with animated background preview
          _buildHeader(),
          
          // Campus list
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: campusList.map((campus) => CampusCard(
                  campus: campus,
                  isSelected: _selectedCampus?.name == campus.name,
                  onTap: () => _selectCampus(campus),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated campus image preview
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Selected campus image with crossfade
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Image.asset(
                    _selectedCampus!.imageAsset,
                    key: ValueKey(_selectedCampus!.name),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // Campus name overlay
                Positioned(
                  bottom: 16,
                  left: 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _selectedCampus!.name,
                      key: ValueKey(_selectedCampus!.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
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
        
        // Title section
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Which campus are you at?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0039A6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your primary GSU location',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
