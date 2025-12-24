import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class PronounsStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const PronounsStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PronounsStep> createState() => _PronounsStepState();
}

class _PronounsStepState extends State<PronounsStep> {
  String? _selectedGender;
  String? _selectedPronouns;
  bool _showOnProfile = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _genderOptions = [
    {'value': 'man', 'label': 'Man', 'icon': Icons.male},
    {'value': 'woman', 'label': 'Woman', 'icon': Icons.female},
    {'value': 'nonbinary', 'label': 'Non-binary', 'icon': Icons.transgender},
  ];

  final List<Map<String, dynamic>> _pronounOptions = [
    {'value': 'he/him', 'label': 'He/Him', 'icon': Icons.person},
    {'value': 'she/her', 'label': 'She/Her', 'icon': Icons.person_outline},
    {'value': 'they/them', 'label': 'They/Them', 'icon': Icons.people_outline},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialData['gender'];
    _selectedPronouns = widget.initialData['pronouns'];
    _showOnProfile = widget.initialData['showPronounsOnProfile'] ?? true;
  }

  Future<void> _saveAndContinue() async {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPronouns == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your pronouns'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'gender': _selectedGender,
        'pronouns': _selectedPronouns,
        'showPronounsOnProfile': _showOnProfile,
        'onboardingStep': 4,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Tell us about yourself',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Help others know how to refer to you',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Gender selection
                  const Text(
                    'What is your gender?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildGenderOptions(),

                  // Pronouns selection (animated appearance)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _selectedGender != null
                        ? _buildPronounsSection()
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 30),

                  // Visibility toggle
                  _buildVisibilityToggle(),

                  const SizedBox(height: 15),

                  // Info about pronoun privacy
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: !_showOnProfile
                        ? _buildPrivacyInfo()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
        OnboardingBottomBar(
          onBack: widget.onBack,
          onContinue: _saveAndContinue,
          isLoading: _isLoading,
          canContinue: _selectedGender != null && _selectedPronouns != null,
        ),
      ],
    );
  }

  Widget _buildGenderOptions() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _genderOptions.length,
        itemBuilder: (context, index) {
          final option = _genderOptions[index];
          final isSelected = _selectedGender == option['value'];

          return Padding(
            padding: EdgeInsets.only(
              right: index < _genderOptions.length - 1 ? 12.0 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedGender == option['value']) {
                    _selectedGender = null;
                  } else {
                    _selectedGender = option['value'];
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0039A6).withValues(alpha: 0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0039A6)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFF0039A6)
                          : Colors.grey[700],
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF0039A6)
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPronounsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text(
          'What are your pronouns?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _pronounOptions.length,
            itemBuilder: (context, index) {
              final option = _pronounOptions[index];
              final isSelected = _selectedPronouns == option['value'];

              return Padding(
                padding: EdgeInsets.only(
                  right: index < _pronounOptions.length - 1 ? 12.0 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedPronouns == option['value']) {
                        _selectedPronouns = null;
                      } else {
                        _selectedPronouns = option['value'];
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0039A6).withValues(alpha: 0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0039A6)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          color: isSelected
                              ? const Color(0xFF0039A6)
                              : Colors.grey[700],
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0039A6)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Others will see your pronouns on your profile',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _showOnProfile,
            onChanged: (value) {
              setState(() {
                _showOnProfile = value;
              });
            },
            activeThumbColor: const Color(0xFF0039A6),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your pronouns will be saved but hidden from your profile. You can change this anytime in settings.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
