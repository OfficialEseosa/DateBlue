import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class ReligiousBeliefStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const ReligiousBeliefStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ReligiousBeliefStep> createState() => _ReligiousBeliefStepState();
}

class _ReligiousBeliefStepState extends State<ReligiousBeliefStep> {
  List<String> _selectedReligions = [];
  bool _isLoading = false;
  bool _showOnProfile = true;

  final List<Map<String, dynamic>> _religions = [
    {'value': 'Christian', 'icon': Icons.church},
    {'value': 'Catholic', 'icon': Icons.church},
    {'value': 'Muslim', 'icon': Icons.mosque},
    {'value': 'Jewish', 'icon': Icons.star},
    {'value': 'Hindu', 'icon': Icons.temple_hindu},
    {'value': 'Buddhist', 'icon': Icons.self_improvement},
    {'value': 'Sikh', 'icon': Icons.temple_buddhist},
    {'value': 'Spiritual', 'icon': Icons.spa},
    {'value': 'Agnostic', 'icon': Icons.help_outline},
    {'value': 'Atheist', 'icon': Icons.not_interested},
    {'value': 'Other', 'icon': Icons.more_horiz},
    {'value': 'Prefer not to say', 'icon': Icons.lock_outline},
  ];

  @override
  void initState() {
    super.initState();
    final existingData = widget.initialData['religiousBeliefs'];
    if (existingData != null) {
      if (existingData is List) {
        _selectedReligions = List<String>.from(existingData);
      } else if (existingData is String) {
        _selectedReligions = [existingData];
      }
    }
    _showOnProfile = widget.initialData['showReligiousBeliefOnProfile'] ?? true;
  }

  Future<void> _saveAndContinue() async {
    if (_selectedReligions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one religious belief'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'religiousBeliefs': _selectedReligions,
        'showReligiousBeliefOnProfile': _showOnProfile,
        'onboardingStep': 13,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        widget.onNext(data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving religious belief: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skip() async {
    setState(() => _isLoading = true);

    try {
      final data = {
        'religiousBeliefs': null,
        'showReligiousBeliefOnProfile': null,
        'onboardingStep': 13,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        widget.onNext(data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error skipping: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Religious Beliefs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select all that apply (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Religious options grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _religions.length,
                    itemBuilder: (context, index) {
                      final religion = _religions[index];
                      final isSelected = _selectedReligions.contains(religion['value']);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedReligions.remove(religion['value']);
                            } else {
                              _selectedReligions.add(religion['value']);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0039A6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0039A6)
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                religion['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0039A6),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  religion['value'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

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
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Find matches who share similar values',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Visibility toggle
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: (_selectedReligions.isNotEmpty &&
                            !_selectedReligions.contains('Prefer not to say'))
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: _buildVisibilityToggle(),
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
          onSkip: _skip,
          isLoading: _isLoading,
          canContinue: _selectedReligions.isNotEmpty,
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
                  'Let others see your beliefs',
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
              setState(() => _showOnProfile = value);
            },
            activeThumbColor: const Color(0xFF0039A6),
          ),
        ],
      ),
    );
  }
}
