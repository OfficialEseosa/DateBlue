import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildrenStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const ChildrenStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ChildrenStep> createState() => _ChildrenStepState();
}

class _ChildrenStepState extends State<ChildrenStep> {
  String? _selectedChildren;
  String? _selectedWantChildren;
  bool _showOnProfile = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _childrenOptions = [
    {
      'value': 'no_children',
      'label': "Don't have children",
      'icon': Icons.person_outline,
      'description': 'No kids',
    },
    {
      'value': 'have_children',
      'label': 'Have children',
      'icon': Icons.family_restroom,
      'description': 'I am a parent',
    },
  ];

  final List<Map<String, dynamic>> _wantChildrenOptions = [
    {
      'value': 'want_children',
      'label': 'Want children',
      'icon': Icons.child_care,
      'description': 'Looking to have kids',
    },
    {
      'value': 'dont_want_children',
      'label': "Don't want children",
      'icon': Icons.do_not_disturb,
      'description': 'Not interested in having kids',
    },
    {
      'value': 'open_to_children',
      'label': 'Open to children',
      'icon': Icons.help_outline,
      'description': 'Would consider it',
    },
    {
      'value': 'not_sure',
      'label': 'Not sure yet',
      'icon': Icons.question_mark,
      'description': 'Still thinking about it',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedChildren = widget.initialData['children'];
    _selectedWantChildren = widget.initialData['wantChildren'];
    _showOnProfile = widget.initialData['showChildrenOnProfile'] ?? true;
  }

  Future<void> _saveAndContinue() async {
    if (_selectedChildren == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select if you have children'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWantChildren == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preference about having children'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'children': _selectedChildren,
        'wantChildren': _selectedWantChildren,
        'showChildrenOnProfile': _showOnProfile,
        'onboardingStep': 10,
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
                    'Family & Future',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Let others know about your family status',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Section 1: Do you have children?
                  const Text(
                    'Do you have children?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _childrenOptions.length,
                      itemBuilder: (context, index) {
                        final option = _childrenOptions[index];
                        final isSelected = _selectedChildren == option['value'];

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _childrenOptions.length - 1 ? 12.0 : 0,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedChildren == option['value']) {
                                  _selectedChildren = null;
                                } else {
                                  _selectedChildren = option['value'];
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0039A6).withOpacity(0.1)
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
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
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

                  const SizedBox(height: 30),

                  // Section 2: Do you want children?
                  const Text(
                    'Do you want children in the future?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _wantChildrenOptions.length,
                      itemBuilder: (context, index) {
                        final option = _wantChildrenOptions[index];
                        final isSelected = _selectedWantChildren == option['value'];

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _wantChildrenOptions.length - 1 ? 12.0 : 0,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedWantChildren == option['value']) {
                                  _selectedWantChildren = null;
                                } else {
                                  _selectedWantChildren = option['value'];
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0039A6).withOpacity(0.1)
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
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
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
                                'Others will see this on your profile',
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
                          activeColor: const Color(0xFF0039A6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Info about privacy
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
                              'This information will be saved but hidden from your profile. You can change this anytime in settings.',
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
                color: Colors.black.withOpacity(0.05),
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
