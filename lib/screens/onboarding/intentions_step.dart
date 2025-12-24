import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IntentionsStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const IntentionsStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<IntentionsStep> createState() => _IntentionsStepState();
}

class _IntentionsStepState extends State<IntentionsStep> {
  String? _selectedIntention;
  bool _showOnProfile = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _intentionOptions = [
    {
      'value': 'long_term',
      'label': 'Long-term relationship',
      'icon': Icons.favorite,
      'description': 'Looking for something serious',
    },
    {
      'value': 'long_open_to_short',
      'label': 'Long-term, open to short',
      'icon': Icons.favorite_border,
      'description': 'Prefer long-term but flexible',
    },
    {
      'value': 'short_open_to_long',
      'label': 'Short-term, open to long',
      'icon': Icons.auto_awesome,
      'description': 'Starting casual, open to more',
    },
    {
      'value': 'short_term',
      'label': 'Short-term fun',
      'icon': Icons.whatshot,
      'description': 'Keeping things casual',
    },
    {
      'value': 'figuring_out',
      'label': 'Still figuring it out',
      'icon': Icons.help_outline,
      'description': 'Exploring what I want',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedIntention = widget.initialData['intentions'];
    _showOnProfile = widget.initialData['showIntentionsOnProfile'] ?? true;
  }

  Future<void> _saveAndContinue() async {
    if (_selectedIntention == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your dating intentions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'intentions': _selectedIntention,
        'showIntentionsOnProfile': _showOnProfile,
        'onboardingStep': 7,
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
                    'What are you looking for?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Let others know your dating intentions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Intentions selection cards
                  ...List.generate(_intentionOptions.length, (index) {
                    final option = _intentionOptions[index];
                    final isSelected = _selectedIntention == option['value'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIntention = option['value'];
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                              // Icon
                              Container(
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
                                  color: isSelected
                                      ? const Color(0xFF0039A6)
                                      : Colors.grey[700],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Label and description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option['label']!,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF0039A6)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['description']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  // Visibility toggle
                  Container(
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
                                'Others will see your intentions on your profile',
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
                  ),

                  const SizedBox(height: 15),

                  // Info about intentions privacy
                  if (!_showOnProfile)
                    Container(
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
                              'Your intentions will be saved but hidden from your profile. You can change this anytime in settings.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Bottom buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button
              SizedBox(
                height: 50,
                width: 50,
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Continue button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0039A6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
