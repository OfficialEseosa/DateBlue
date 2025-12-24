import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class SubstanceUseStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const SubstanceUseStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<SubstanceUseStep> createState() => _SubstanceUseStepState();
}

class _SubstanceUseStepState extends State<SubstanceUseStep> {
  String? _drinkingStatus;
  String? _smokingStatus;
  String? _weedStatus;
  String? _drugStatus;
  bool _isLoading = false;
  bool _showOnProfile = true;

  final List<String> _drinkingOptions = [
    'Never',
    'Rarely',
    'Socially',
    'Regularly',
    'Prefer not to say',
  ];

  final List<String> _smokingOptions = [
    'Never',
    'Occasionally',
    'Regularly',
    'Trying to quit',
    'Prefer not to say',
  ];

  final List<String> _weedOptions = [
    'Never',
    'Occasionally',
    'Regularly',
    'Prefer not to say',
  ];

  final List<String> _drugOptions = [
    'Never',
    'Occasionally',
    'Regularly',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _drinkingStatus = widget.initialData['drinkingStatus'];
    _smokingStatus = widget.initialData['smokingStatus'];
    _weedStatus = widget.initialData['weedStatus'];
    _drugStatus = widget.initialData['drugStatus'];
    _showOnProfile = widget.initialData['showSubstanceUseOnProfile'] ?? true;
  }

  bool get _hasAnsweredAll =>
      _drinkingStatus != null &&
      _smokingStatus != null &&
      _weedStatus != null &&
      _drugStatus != null;

  Future<void> _saveAndContinue() async {
    if (!_hasAnsweredAll) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'drinkingStatus': _drinkingStatus,
        'smokingStatus': _smokingStatus,
        'weedStatus': _weedStatus,
        'drugStatus': _drugStatus,
        'showSubstanceUseOnProfile': _showOnProfile,
        'onboardingStep': 14,
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
            content: Text('Error saving: $e'),
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
                    'Lifestyle',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Help others understand your lifestyle choices',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Drinking
                  _buildQuestionSection(
                    title: 'Do you drink?',
                    icon: Icons.local_bar,
                    options: _drinkingOptions,
                    selectedValue: _drinkingStatus,
                    onSelected: (value) {
                      setState(() => _drinkingStatus = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Smoking
                  _buildQuestionSection(
                    title: 'Do you smoke tobacco?',
                    icon: Icons.smoking_rooms,
                    options: _smokingOptions,
                    selectedValue: _smokingStatus,
                    onSelected: (value) {
                      setState(() => _smokingStatus = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Weed
                  _buildQuestionSection(
                    title: 'Do you smoke weed?',
                    icon: Icons.local_florist,
                    options: _weedOptions,
                    selectedValue: _weedStatus,
                    onSelected: (value) {
                      setState(() => _weedStatus = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Drugs
                  _buildQuestionSection(
                    title: 'Do you use drugs?',
                    icon: Icons.medication,
                    options: _drugOptions,
                    selectedValue: _drugStatus,
                    onSelected: (value) {
                      setState(() => _drugStatus = value);
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
                            'Your honest answers help find compatible matches',
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
                    child: _hasAnsweredAll
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
          isLoading: _isLoading,
          canContinue: _hasAnsweredAll,
        ),
      ],
    );
  }

  Widget _buildQuestionSection({
    required String title,
    required IconData icon,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0039A6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0039A6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0039A6)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
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
                  'Let others see your lifestyle choices',
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
