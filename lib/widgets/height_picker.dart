import 'package:flutter/material.dart';

/// Height conversion and display utilities
class HeightUtils {
  /// Convert centimeters to total inches
  static int cmToTotalInches(int cm) {
    return (cm / 2.54).round();
  }

  /// Convert total inches to centimeters
  static int totalInchesToCm(int totalInches) {
    return (totalInches * 2.54).round();
  }

  /// Convert feet and inches to centimeters
  static int feetInchesToCm(int feet, int inches) {
    return totalInchesToCm((feet * 12) + inches);
  }

  /// Convert centimeters to feet (whole number)
  static int cmToFeet(int cm) {
    final totalInches = cmToTotalInches(cm);
    return totalInches ~/ 12;
  }

  /// Convert centimeters to remaining inches (after feet)
  static int cmToInches(int cm) {
    final totalInches = cmToTotalInches(cm);
    return totalInches % 12;
  }

  /// Format height as feet'inches" string
  static String formatAsFeetInches(int cm) {
    final feet = cmToFeet(cm);
    final inches = cmToInches(cm);
    return "$feet'$inches\"";
  }

  /// Format height as cm string
  static String formatAsCm(int cm) {
    return "$cm cm";
  }

  /// Clamp feet to valid range (3-8)
  static int clampFeet(int feet) {
    if (feet < 3) return 3;
    if (feet > 8) return 8;
    return feet;
  }

  /// Clamp cm to valid range (100-250)
  static int clampCm(int cm) {
    if (cm < 100) return 100;
    if (cm > 250) return 250;
    return cm;
  }
}

/// A reusable height picker widget with unit toggle and auto-conversion
class HeightPicker extends StatefulWidget {
  final int initialHeightCm;
  final bool initialUseFeet;
  final ValueChanged<int> onHeightChanged;
  final ValueChanged<bool>? onUnitChanged;

  const HeightPicker({
    super.key,
    this.initialHeightCm = 170,
    this.initialUseFeet = true,
    required this.onHeightChanged,
    this.onUnitChanged,
  });

  @override
  State<HeightPicker> createState() => _HeightPickerState();
}

class _HeightPickerState extends State<HeightPicker> {
  late bool _useFeet;
  late int _heightCm;

  // Controllers for pickers
  late FixedExtentScrollController _feetController;
  late FixedExtentScrollController _inchesController;
  late FixedExtentScrollController _cmController;

  @override
  void initState() {
    super.initState();
    _useFeet = widget.initialUseFeet;
    _heightCm = HeightUtils.clampCm(widget.initialHeightCm);
    _initControllers();
  }

  void _initControllers() {
    final feet = HeightUtils.clampFeet(HeightUtils.cmToFeet(_heightCm));
    final inches = HeightUtils.cmToInches(_heightCm);
    
    _feetController = FixedExtentScrollController(initialItem: feet - 3);
    _inchesController = FixedExtentScrollController(initialItem: inches);
    _cmController = FixedExtentScrollController(initialItem: _heightCm - 100);
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
      _useFeet = !_useFeet;
      
      if (_useFeet) {
        // Switching TO feet - update feet/inches controllers
        final feet = HeightUtils.clampFeet(HeightUtils.cmToFeet(_heightCm));
        final inches = HeightUtils.cmToInches(_heightCm);
        
        _feetController.dispose();
        _inchesController.dispose();
        _feetController = FixedExtentScrollController(initialItem: feet - 3);
        _inchesController = FixedExtentScrollController(initialItem: inches);
      } else {
        // Switching TO cm - update cm controller
        _cmController.dispose();
        _cmController = FixedExtentScrollController(initialItem: _heightCm - 100);
      }
    });
    
    widget.onUnitChanged?.call(_useFeet);
  }

  void _updateHeightFromFeetInches(int feet, int inches) {
    _heightCm = HeightUtils.feetInchesToCm(feet, inches);
    widget.onHeightChanged(_heightCm);
  }

  void _updateHeightFromCm(int cm) {
    _heightCm = cm;
    widget.onHeightChanged(_heightCm);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Unit toggle
        _buildUnitToggle(),
        const SizedBox(height: 24),
        
        // Height picker - white background, no animations
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _useFeet ? _buildFeetInchesPicker() : _buildCmPicker(),
        ),
      ],
    );
  }

  Widget _buildUnitToggle() {
    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _useFeet ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _useFeet
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: !_useFeet ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: !_useFeet
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
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
    );
  }

  Widget _buildFeetInchesPicker() {
    final currentFeet = HeightUtils.clampFeet(HeightUtils.cmToFeet(_heightCm));
    final currentInches = HeightUtils.cmToInches(_heightCm);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Feet picker
        SizedBox(
          width: 70,
          height: 180,
          child: ListWheelScrollView.useDelegate(
            controller: _feetController,
            itemExtent: 50,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.5,
            onSelectedItemChanged: (index) {
              setState(() {
                final feet = index + 3;
                _updateHeightFromFeetInches(feet, currentInches);
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final feet = index + 3;
                if (feet < 3 || feet > 8) return null;
                
                final isSelected = feet == currentFeet;
                return Center(
                  child: Text(
                    '$feet',
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 22,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
                    ),
                  ),
                );
              },
              childCount: 6,
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
        const SizedBox(width: 16),
        // Inches picker
        SizedBox(
          width: 70,
          height: 180,
          child: ListWheelScrollView.useDelegate(
            controller: _inchesController,
            itemExtent: 50,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.5,
            onSelectedItemChanged: (index) {
              setState(() {
                _updateHeightFromFeetInches(currentFeet, index);
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index > 11) return null;
                
                final isSelected = index == currentInches;
                return Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 22,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
                    ),
                  ),
                );
              },
              childCount: 12,
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
  }

  Widget _buildCmPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          height: 180,
          child: ListWheelScrollView.useDelegate(
            controller: _cmController,
            itemExtent: 50,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.5,
            onSelectedItemChanged: (index) {
              setState(() {
                _updateHeightFromCm(index + 100);
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final cm = index + 100;
                if (cm < 100 || cm > 250) return null;
                
                final isSelected = cm == _heightCm;
                return Center(
                  child: Text(
                    '$cm',
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 22,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF0039A6) : Colors.grey,
                    ),
                  ),
                );
              },
              childCount: 151,
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
