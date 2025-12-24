import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HeightStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const HeightStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  bool _useFeet = true; // true for feet, false for cm
  bool _showOnProfile = true;
  bool _isLoading = false;

  // For feet/inches
  late FixedExtentScrollController _feetController;
  late FixedExtentScrollController _inchesController;
  int _selectedFeet = 5; // Default 5 feet
  int _selectedInches = 7; // Default 7 inches (5'7")

  // For centimeters
  late FixedExtentScrollController _cmController;
  int _selectedCm = 170; // Default 170 cm (approximately 5'7")

  @override
  void initState() {
    super.initState();
    
    // Load saved height data - stored as cm integer
    final savedHeightCm = widget.initialData['heightCm'];
    _showOnProfile = widget.initialData['showHeightOnProfile'] ?? true;

    if (savedHeightCm != null && savedHeightCm is int) {
      _selectedCm = savedHeightCm;
      // Convert cm to feet/inches for the picker
      final totalInches = (_selectedCm / 2.54).round();
      _selectedFeet = totalInches ~/ 12;
      _selectedInches = totalInches % 12;
      if (_selectedFeet < 3) _selectedFeet = 3;
      if (_selectedFeet > 8) _selectedFeet = 8;
    }

    _feetController = FixedExtentScrollController(initialItem: _selectedFeet - 3);
    _inchesController = FixedExtentScrollController(initialItem: _selectedInches);
    _cmController = FixedExtentScrollController(initialItem: _selectedCm - 100);
  }

  @override
  void dispose() {
    _feetController.dispose();
    _inchesController.dispose();
    _cmController.dispose();
    super.dispose();
  }

  void _toggleUnit() {
    setState(() {
      if (_useFeet) {
        // Convert feet/inches to cm
        final totalInches = (_selectedFeet * 12) + _selectedInches;
        _selectedCm = (totalInches * 2.54).round();
        if (_selectedCm < 100) _selectedCm = 100;
        if (_selectedCm > 250) _selectedCm = 250;
        
        // Update cm controller
        _cmController.dispose();
        _cmController = FixedExtentScrollController(initialItem: _selectedCm - 100);
      } else {
        // Convert cm to feet/inches
        final totalInches = (_selectedCm / 2.54).round();
        _selectedFeet = totalInches ~/ 12;
        _selectedInches = totalInches % 12;
        
        if (_selectedFeet < 3) _selectedFeet = 3;
        if (_selectedFeet > 8) _selectedFeet = 8;
        
        // Update feet/inches controllers
        _feetController.dispose();
        _inchesController.dispose();
        _feetController = FixedExtentScrollController(initialItem: _selectedFeet - 3);
        _inchesController = FixedExtentScrollController(initialItem: _selectedInches);
      }
      _useFeet = !_useFeet;
    });
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    try {
      // Always calculate and store height in cm
      int heightCm;
      if (_useFeet) {
        heightCm = ((_selectedFeet * 12 + _selectedInches) * 2.54).round();
      } else {
        heightCm = _selectedCm;
      }

      final data = <String, dynamic>{
        'heightCm': heightCm,
        'showHeightOnProfile': _showOnProfile,
        'onboardingStep': 8,
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

  Widget _buildPicker() {
    if (_useFeet) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feet picker
          SizedBox(
            width: 80,
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _feetController,
              itemExtent: 50,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedFeet = index + 3; // 3-8 feet
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final feet = index + 3;
                  if (feet < 3 || feet > 8) return null;
                  
                  final isSelected = feet == _selectedFeet;
                  return Center(
                    child: Text(
                      '$feet',
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 24,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
                      ),
                    ),
                  );
                },
                childCount: 6, // 3-8 feet
              ),
            ),
          ),
          const Text(
            "'",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0039A6),
            ),
          ),
          const SizedBox(width: 20),
          // Inches picker
          SizedBox(
            width: 80,
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _inchesController,
              itemExtent: 50,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedInches = index;
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index > 11) return null;
                  
                  final isSelected = index == _selectedInches;
                  return Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 24,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
                      ),
                    ),
                  );
                },
                childCount: 12, // 0-11 inches
              ),
            ),
          ),
          const Text(
            '"',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0039A6),
            ),
          ),
        ],
      );
    } else {
      // Centimeters picker
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _cmController,
              itemExtent: 50,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedCm = index + 100; // 100-250 cm
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final cm = index + 100;
                  if (cm < 100 || cm > 250) return null;
                  
                  final isSelected = cm == _selectedCm;
                  return Center(
                    child: Text(
                      '$cm',
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 24,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
                      ),
                    ),
                  );
                },
                childCount: 151, // 100-250 cm
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'cm',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0039A6),
            ),
          ),
        ],
      );
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'What is your height?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This helps with matching preferences',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Unit toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _useFeet ? null : _toggleUnit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _useFeet ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Feet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _useFeet ? FontWeight.bold : FontWeight.normal,
                                color: _useFeet ? const Color(0xFF0039A6) : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _useFeet ? _toggleUnit : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: !_useFeet ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'CM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: !_useFeet ? FontWeight.bold : FontWeight.normal,
                                color: !_useFeet ? const Color(0xFF0039A6) : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Height picker
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _buildPicker(),
                  ),

                  const SizedBox(height: 40),

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
                                'Others will see your height on your profile',
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

                  // Info about height privacy
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
                              'Your height will be saved but hidden from your profile. You can change this anytime in settings.',
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
