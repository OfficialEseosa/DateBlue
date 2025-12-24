import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';

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
    },
    {
      'value': 'have_children',
      'label': 'Have children',
      'icon': Icons.family_restroom,
    },
  ];

  final List<Map<String, dynamic>> _wantChildrenOptions = [
    {
      'value': 'want_children',
      'label': 'Want children',
      'icon': Icons.child_care,
    },
    {
      'value': 'dont_want_children',
      'label': "Don't want",
      'icon': Icons.do_not_disturb,
    },
    {
      'value': 'open_to_children',
      'label': 'Open to it',
      'icon': Icons.help_outline,
    },
    {
      'value': 'not_sure',
      'label': 'Not sure yet',
      'icon': Icons.question_mark,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Family & Future',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let others know about your family plans',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Section 1: Do you have children?
                  const Text(
                    'Do you have children?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Horizontal options for "have children"
                  Row(
                    children: _childrenOptions.map((option) {
                      final isSelected = _selectedChildren == option['value'];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: option == _childrenOptions.last ? 0 : 12,
                          ),
                          child: _buildOptionCard(option, isSelected, () {
                            setState(() {
                              _selectedChildren = option['value'];
                            });
                          }),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Do you want children?
                  const Text(
                    'Do you want children?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 2x2 Grid for "want children" options
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildWantChildrenOption(_wantChildrenOptions[0])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildWantChildrenOption(_wantChildrenOptions[1])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildWantChildrenOption(_wantChildrenOptions[2])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildWantChildrenOption(_wantChildrenOptions[3])),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Visibility toggle
                  _buildVisibilityToggle(),
                  
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        OnboardingBottomBar(
          onBack: widget.onBack,
          onContinue: _saveAndContinue,
          isLoading: _isLoading,
          canContinue: _selectedChildren != null && _selectedWantChildren != null,
        ),
      ],
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0039A6)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option['icon'] as IconData,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
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
    );
  }

  Widget _buildWantChildrenOption(Map<String, dynamic> option) {
    final isSelected = _selectedWantChildren == option['value'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWantChildren = option['value'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0039A6)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                option['icon'] as IconData,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option['label']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0039A6)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Others will see your family preferences',
                  style: TextStyle(
                    fontSize: 12,
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
