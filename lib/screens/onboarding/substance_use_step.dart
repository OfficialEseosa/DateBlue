import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _saveAndContinue() async {
    if (_drinkingStatus == null ||
        _smokingStatus == null ||
        _weedStatus == null ||
        _drugStatus == null) {
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
                fontSize: 18,
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
            return InkWell(
              onTap: () => onSelected(option),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
                    fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final hasAnsweredAll = _drinkingStatus != null &&
        _smokingStatus != null &&
        _weedStatus != null &&
        _drugStatus != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                    const SizedBox(height: 30),

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

                    const SizedBox(height: 24),

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

                    const SizedBox(height: 24),

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

                    const SizedBox(height: 24),

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
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[50]!,
                            Colors.blue[100]!.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF0039A6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your honest answers help find compatible matches with similar lifestyles',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile visibility toggle
                    if (hasAnsweredAll) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _showOnProfile
                                    ? const Color(0xFF0039A6).withValues(alpha: 0.1)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _showOnProfile
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: _showOnProfile
                                    ? const Color(0xFF0039A6)
                                    : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Show on profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0039A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
