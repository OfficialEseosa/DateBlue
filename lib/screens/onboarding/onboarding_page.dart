import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_page.dart';
import 'name_step.dart';
import 'birthday_step.dart';
import 'campus_step.dart';
import 'pronouns_step.dart';
import 'sexuality_step.dart';
import 'dating_preference_step.dart';
import 'intentions_step.dart';
import 'height_step.dart';
import 'ethnicity_step.dart';
import 'children_step.dart';
import 'hometown_step.dart';
import 'workplace_step.dart';
import 'religious_beliefs_step.dart';
import 'substance_use_step.dart';
import 'photo_permission_step.dart';
import 'media_upload_step.dart';
import 'prompts_step.dart';

class OnboardingPage extends StatefulWidget {
  final User user;

  const OnboardingPage({
    super.key,
    required this.user,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  final Map<String, dynamic> _onboardingData = {};

  @override
  void initState() {
    super.initState();
    _loadOnboardingProgress();
  }

  Future<void> _loadOnboardingProgress() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['onboardingStep'] != null) {
          setState(() {
            _currentStep = data['onboardingStep'] as int;
            _onboardingData.addAll(data);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading onboarding progress: $e');
    }
  }

  void _nextStep(Map<String, dynamic> stepData) {
    setState(() {
      _onboardingData.addAll(stepData);
      _currentStep++;
    });
    
    // If we've completed step 16 (the final step), navigate to home
    if (_currentStep > 16) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(user: widget.user),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/GSU_Auburn-Ave01.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0039A6).withValues(alpha: 0.85),
                  const Color(0xFF0039A6).withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: List.generate(17, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 16 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Content
                Expanded(
                  child: _buildCurrentStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return NameStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
        );
      case 1:
        return BirthdayStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 2:
        return CampusStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 3:
        return PronounsStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 4:
        return SexualityStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 5:
        return DatingPreferenceStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 6:
        return IntentionsStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 7:
        return HeightStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 8:
        return EthnicityStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 9:
        return ChildrenStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 10:
        return HometownStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 11:
        return WorkplaceStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 12:
        return ReligiousBeliefStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 13:
        return SubstanceUseStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 14:
        return PhotoPermissionStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 15:
        return MediaUploadStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 16:
        return PromptsStep(
          user: widget.user,
          initialData: _onboardingData,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      default:
        // TODO: Navigate to home page
        return const Center(
          child: Text(
            'Onboarding complete!',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        );
    }
  }
}
