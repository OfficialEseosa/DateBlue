import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final FocusNode _workplaceFocusNode = FocusNode();
  final FocusNode _jobTitleFocusNode = FocusNode();
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
    _workplaceFocusNode.dispose();
    _jobTitleFocusNode.dispose();
    super.dispose();
  }

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
    final hasContent = _workplaceController.text.trim().isNotEmpty &&
        _jobTitleController.text.trim().isNotEmpty;

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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _workplaceFocusNode.hasFocus
                              ? const Color(0xFF0039A6)
                              : Colors.grey[300]!,
                          width: _workplaceFocusNode.hasFocus ? 2 : 1,
                        ),
                        boxShadow: [
                          if (_workplaceFocusNode.hasFocus)
                            BoxShadow(
                              color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: TextField(
                        controller: _workplaceController,
                        focusNode: _workplaceFocusNode,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Company or organization name',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: const Icon(
                            Icons.business,
                            color: Color(0xFF0039A6),
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
                    ),

                    const SizedBox(height: 16),

                    // Job Title Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _jobTitleFocusNode.hasFocus
                              ? const Color(0xFF0039A6)
                              : Colors.grey[300]!,
                          width: _jobTitleFocusNode.hasFocus ? 2 : 1,
                        ),
                        boxShadow: [
                          if (_jobTitleFocusNode.hasFocus)
                            BoxShadow(
                              color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: TextField(
                        controller: _jobTitleController,
                        focusNode: _jobTitleFocusNode,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Your job title or role',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: const Icon(
                            Icons.work,
                            color: Color(0xFF0039A6),
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
                              'Share your profession to help find compatible matches',
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
                    if (hasContent) ...[
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
                      ),
                    ],
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
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: _isLoading ? null : _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _isLoading ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
