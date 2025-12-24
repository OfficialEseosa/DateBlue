import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class DatingPreferenceStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const DatingPreferenceStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<DatingPreferenceStep> createState() => _DatingPreferenceStepState();
}

class _DatingPreferenceStepState extends State<DatingPreferenceStep> {
  final Set<String> _selectedPreferences = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _preferenceOptions = [
    {'value': 'men', 'label': 'Men', 'icon': Icons.male},
    {'value': 'women', 'label': 'Women', 'icon': Icons.female},
    {'value': 'nonbinary', 'label': 'Non-binary', 'icon': Icons.transgender},
  ];

  @override
  void initState() {
    super.initState();
    final savedPreferences = widget.initialData['datingPreferences'];
    if (savedPreferences is List) {
      _selectedPreferences.addAll(savedPreferences.cast<String>());
    }
  }

  void _togglePreference(String value) {
    setState(() {
      if (_selectedPreferences.contains(value)) {
        _selectedPreferences.remove(value);
      } else {
        _selectedPreferences.add(value);
      }
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one dating preference'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'datingPreferences': _selectedPreferences.toList(),
        'onboardingStep': 6,
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
                    'Who do you want to date?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select all that apply',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Dating preference selection cards
                  ..._preferenceOptions.map((option) {
                    final isSelected = _selectedPreferences.contains(option['value']);
                    return _buildPreferenceCard(option, isSelected);
                  }),

                  const SizedBox(height: 20),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 24,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can select multiple options. Your preferences can be changed anytime in settings.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Selected count indicator with animation
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _selectedPreferences.isNotEmpty
                        ? Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedPreferences.length} ${_selectedPreferences.length == 1 ? 'preference' : 'preferences'} selected',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0039A6),
                                ),
                              ),
                            ),
                          )
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
          canContinue: _selectedPreferences.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildPreferenceCard(Map<String, dynamic> option, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => _togglePreference(option['value']!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0039A6)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option['icon'] as IconData,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Preference label
              Expanded(
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF0039A6)
                        : Colors.black87,
                  ),
                ),
              ),
              // Checkbox indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isSelected 
                      ? const Color(0xFF0039A6)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF0039A6)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected 
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
