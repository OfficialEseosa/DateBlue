import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class EthnicityStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const EthnicityStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<EthnicityStep> createState() => _EthnicityStepState();
}

class _EthnicityStepState extends State<EthnicityStep> {
  final Set<String> _selectedEthnicities = {};
  bool _showOnProfile = true;
  bool _isLoading = false;

  // Simple list without icons - cleaner look
  final List<Map<String, dynamic>> _ethnicityOptions = [
    {'value': 'asian', 'label': 'Asian'},
    {'value': 'black', 'label': 'Black / African Descent'},
    {'value': 'hispanic', 'label': 'Hispanic / Latino'},
    {'value': 'indigenous', 'label': 'Indigenous / Native'},
    {'value': 'middle_eastern', 'label': 'Middle Eastern'},
    {'value': 'pacific_islander', 'label': 'Pacific Islander'},
    {'value': 'south_asian', 'label': 'South Asian'},
    {'value': 'white', 'label': 'White / Caucasian'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    final savedEthnicities = widget.initialData['ethnicities'];
    if (savedEthnicities is List) {
      _selectedEthnicities.addAll(savedEthnicities.cast<String>());
    }
    _showOnProfile = widget.initialData['showEthnicityOnProfile'] ?? true;
  }

  void _toggleEthnicity(String value) {
    setState(() {
      if (_selectedEthnicities.contains(value)) {
        _selectedEthnicities.remove(value);
      } else {
        _selectedEthnicities.add(value);
      }
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selectedEthnicities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ethnicity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'ethnicities': _selectedEthnicities.toList(),
        'showEthnicityOnProfile': _showOnProfile,
        'onboardingStep': 9,
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
                    'What is your ethnicity?',
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
                  const SizedBox(height: 24),

                  // Ethnicity selection cards - clean design without icons
                  ..._ethnicityOptions.map((option) {
                    final isSelected = _selectedEthnicities.contains(option['value']);
                    return _buildEthnicityCard(option, isSelected);
                  }),

                  const SizedBox(height: 24),

                  // Visibility toggle
                  _buildVisibilityToggle(),

                  const SizedBox(height: 12),

                  // Selected count indicator
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _selectedEthnicities.isNotEmpty
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
                                '${_selectedEthnicities.length} ${_selectedEthnicities.length == 1 ? 'ethnicity' : 'ethnicities'} selected',
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

                  const SizedBox(height: 12),

                  // Privacy info
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
          canContinue: _selectedEthnicities.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildEthnicityCard(Map<String, dynamic> option, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GestureDetector(
        onTap: () => _toggleEthnicity(option['value']!),
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
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Ethnicity label
              Expanded(
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0039A6)
                        : Colors.black87,
                  ),
                ),
              ),
              // Checkbox indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
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
                        size: 16,
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
                  'Others will see your ethnicity on your profile',
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
              'Your ethnicity will be saved but hidden from your profile. You can change this anytime in settings.',
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
