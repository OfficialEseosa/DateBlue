import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class WorkplaceStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const WorkplaceStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<WorkplaceStep> createState() => _WorkplaceStepState();
}

class _WorkplaceStepState extends State<WorkplaceStep> {
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  bool _isLoading = false;
  bool _showOnProfile = true;

  @override
  void initState() {
    super.initState();
    _workplaceController.text = widget.initialData['workplace'] ?? '';
    _jobTitleController.text = widget.initialData['jobTitle'] ?? '';
    _showOnProfile = widget.initialData['showWorkplaceOnProfile'] ?? true;
  }

  @override
  void dispose() {
    _workplaceController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _workplaceController.text.trim().isNotEmpty &&
      _jobTitleController.text.trim().isNotEmpty;

  Future<void> _saveAndContinue() async {
    final workplace = _workplaceController.text.trim();
    final jobTitle = _jobTitleController.text.trim();

    // Validate: either both filled or both empty
    if ((workplace.isNotEmpty && jobTitle.isEmpty) ||
        (workplace.isEmpty && jobTitle.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill both workplace and job title, or leave both empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'workplace': workplace.isNotEmpty ? workplace : null,
        'jobTitle': jobTitle.isNotEmpty ? jobTitle : null,
        'showWorkplaceOnProfile': workplace.isNotEmpty ? _showOnProfile : null,
        'onboardingStep': 12,
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
            content: Text('Error saving workplace: $e'),
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
        'workplace': null,
        'jobTitle': null,
        'showWorkplaceOnProfile': null,
        'onboardingStep': 12,
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
                    'Work',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Where do you work? (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Workplace Field
                  _buildTextField(
                    controller: _workplaceController,
                    hint: 'Company or organization name',
                    icon: Icons.business,
                  ),

                  const SizedBox(height: 16),

                  // Job Title Field
                  _buildTextField(
                    controller: _jobTitleController,
                    hint: 'Your job title or role',
                    icon: Icons.work,
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
                            'Share your profession to help find compatible matches',
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
                    child: _hasContent
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
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: controller.text.isNotEmpty
              ? const Color(0xFF0039A6)
              : Colors.grey[300]!,
          width: controller.text.isNotEmpty ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF0039A6),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        onChanged: (value) => setState(() {}),
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
                  'Let others see where you work',
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
