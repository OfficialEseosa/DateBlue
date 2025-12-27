import 'package:flutter/material.dart';
import '../../models/profile_options.dart';

/// Professional filter sheet for discover preferences
class FilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;

  const FilterSheet({
    super.key,
    required this.currentFilters,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> currentFilters,
    required Function(Map<String, dynamic>) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        currentFilters: currentFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  // Filter state
  late int _minAge;
  late int _maxAge;
  late List<String> _selectedCampuses;
  late List<String> _selectedHasChildren;
  late List<String> _selectedWantsChildren;
  late List<String> _selectedSmoking;
  late List<String> _selectedDrinking;
  late List<String> _selectedReligion;
  late List<String> _selectedEthnicity;
  
  // Expansion state
  final Map<String, bool> _expanded = {
    'age': true,
    'campus': false,
    'hasChildren': false,
    'wantsChildren': false,
    'smoking': false,
    'drinking': false,
    'religion': false,
    'ethnicity': false,
  };

  @override
  void initState() {
    super.initState();
    _minAge = widget.currentFilters['minAge'] ?? 18;
    _maxAge = widget.currentFilters['maxAge'] ?? 40;
    _selectedCampuses = List<String>.from(widget.currentFilters['campuses'] ?? []);
    _selectedHasChildren = List<String>.from(widget.currentFilters['hasChildren'] ?? []);
    _selectedWantsChildren = List<String>.from(widget.currentFilters['wantsChildren'] ?? []);
    _selectedSmoking = List<String>.from(widget.currentFilters['smoking'] ?? []);
    _selectedDrinking = List<String>.from(widget.currentFilters['drinking'] ?? []);
    _selectedReligion = List<String>.from(widget.currentFilters['religion'] ?? []);
    _selectedEthnicity = List<String>.from(widget.currentFilters['ethnicity'] ?? []);
  }

  int get _activeFilterCount {
    int count = 0;
    if (_minAge != 18 || _maxAge != 40) count++;
    if (_selectedCampuses.isNotEmpty) count++;
    if (_selectedHasChildren.isNotEmpty) count++;
    if (_selectedWantsChildren.isNotEmpty) count++;
    if (_selectedSmoking.isNotEmpty) count++;
    if (_selectedDrinking.isNotEmpty) count++;
    if (_selectedReligion.isNotEmpty) count++;
    if (_selectedEthnicity.isNotEmpty) count++;
    return count;
  }

  void _reset() {
    setState(() {
      _minAge = 18;
      _maxAge = 40;
      _selectedCampuses = [];
      _selectedHasChildren = [];
      _selectedWantsChildren = [];
      _selectedSmoking = [];
      _selectedDrinking = [];
      _selectedReligion = [];
      _selectedEthnicity = [];
    });
  }

  void _apply() {
    widget.onApply({
      'minAge': _minAge,
      'maxAge': _maxAge,
      'campuses': _selectedCampuses,
      'hasChildren': _selectedHasChildren,
      'wantsChildren': _selectedWantsChildren,
      'smoking': _selectedSmoking,
      'drinking': _selectedDrinking,
      'religion': _selectedReligion,
      'ethnicity': _selectedEthnicity,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _reset,
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: _activeFilterCount > 0 ? const Color(0xFF0039A6) : Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Filters',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_activeFilterCount > 0)
                      Text(
                        '$_activeFilterCount active',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        
        // Age Range Section
        _buildExpandableSection(
          key: 'age',
          title: 'Age Range',
          subtitle: '$_minAge - $_maxAge years',
          icon: Icons.cake_outlined,
          isActive: _minAge != 18 || _maxAge != 40,
          content: _buildAgeRangeContent(),
        ),
        
        // Campus Section
        _buildExpandableSection(
          key: 'campus',
          title: 'Campus',
          subtitle: _selectedCampuses.isEmpty 
              ? 'All campuses' 
              : '${_selectedCampuses.length} selected',
          icon: Icons.school_outlined,
          isActive: _selectedCampuses.isNotEmpty,
          content: _buildMultiSelectContent(
            options: ProfileOptions.campusOptions,
            selected: _selectedCampuses,
            displayTransform: (s) => s.replaceAll(' Campus', ''),
          ),
        ),
        
        // Has Children Section
        _buildExpandableSection(
          key: 'hasChildren',
          title: 'Has Children',
          subtitle: _selectedHasChildren.isEmpty 
              ? 'Any' 
              : '${_selectedHasChildren.length} selected',
          icon: Icons.family_restroom_outlined,
          isActive: _selectedHasChildren.isNotEmpty,
          content: _buildMapSelectContent(
            options: ProfileOptions.hasChildrenOptions,
            selected: _selectedHasChildren,
          ),
        ),
        
        // Wants Children Section
        _buildExpandableSection(
          key: 'wantsChildren',
          title: 'Wants Children',
          subtitle: _selectedWantsChildren.isEmpty 
              ? 'Any' 
              : '${_selectedWantsChildren.length} selected',
          icon: Icons.child_care_outlined,
          isActive: _selectedWantsChildren.isNotEmpty,
          content: _buildMapSelectContent(
            options: ProfileOptions.wantChildrenOptions,
            selected: _selectedWantsChildren,
          ),
        ),
        
        // Smoking Section
        _buildExpandableSection(
          key: 'smoking',
          title: 'Smoking',
          subtitle: _selectedSmoking.isEmpty 
              ? 'Any' 
              : '${_selectedSmoking.length} selected',
          icon: Icons.smoke_free_outlined,
          isActive: _selectedSmoking.isNotEmpty,
          content: _buildMultiSelectContent(
            options: ProfileOptions.smokingOptions,
            selected: _selectedSmoking,
          ),
        ),
        
        // Drinking Section
        _buildExpandableSection(
          key: 'drinking',
          title: 'Drinking',
          subtitle: _selectedDrinking.isEmpty 
              ? 'Any' 
              : '${_selectedDrinking.length} selected',
          icon: Icons.local_bar_outlined,
          isActive: _selectedDrinking.isNotEmpty,
          content: _buildMultiSelectContent(
            options: ProfileOptions.drinkingOptions,
            selected: _selectedDrinking,
          ),
        ),
        
        // Religion Section
        _buildExpandableSection(
          key: 'religion',
          title: 'Religion',
          subtitle: _selectedReligion.isEmpty 
              ? 'Any' 
              : '${_selectedReligion.length} selected',
          icon: Icons.church_outlined,
          isActive: _selectedReligion.isNotEmpty,
          content: _buildMultiSelectContent(
            options: ProfileOptions.religionOptions,
            selected: _selectedReligion,
          ),
        ),
        
        // Ethnicity Section
        _buildExpandableSection(
          key: 'ethnicity',
          title: 'Ethnicity',
          subtitle: _selectedEthnicity.isEmpty 
              ? 'Any' 
              : '${_selectedEthnicity.length} selected',
          icon: Icons.people_outline,
          isActive: _selectedEthnicity.isNotEmpty,
          content: _buildMultiSelectContent(
            options: ProfileOptions.ethnicityOptionsList,
            selected: _selectedEthnicity,
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Widget content,
  }) {
    final isExpanded = _expanded[key] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0039A6).withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF0039A6).withValues(alpha: 0.3) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded[key] = !isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? const Color(0xFF0039A6).withValues(alpha: 0.15) 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? const Color(0xFF0039A6) : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isActive ? const Color(0xFF0039A6) : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAgeInput('Min', _minAge, (v) => setState(() => _minAge = v)),
            Container(
              width: 20,
              height: 2,
              color: Colors.grey[300],
            ),
            _buildAgeInput('Max', _maxAge, (v) => setState(() => _maxAge = v)),
          ],
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
          min: 18,
          max: 60,
          divisions: 42,
          activeColor: const Color(0xFF0039A6),
          inactiveColor: Colors.grey[300],
          onChanged: (values) => setState(() {
            _minAge = values.start.round();
            _maxAge = values.end.round();
          }),
        ),
      ],
    );
  }

  Widget _buildAgeInput(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectContent({
    required List<String> options,
    required List<String> selected,
    String Function(String)? displayTransform,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        final displayText = displayTransform?.call(option) ?? option;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selected.remove(option);
              } else {
                selected.add(option);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0039A6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF0039A6) : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF0039A6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Text(
              displayText,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build multi-select from Map options with value/label pairs
  /// Displays labels but stores values in selected list
  Widget _buildMapSelectContent({
    required List<Map<String, dynamic>> options,
    required List<String> selected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final value = option['value'] as String;
        final label = option['label'] as String;
        final isSelected = selected.contains(value);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selected.remove(value);
              } else {
                selected.add(value);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0039A6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF0039A6) : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF0039A6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0039A6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              _activeFilterCount > 0 
                  ? 'Apply ${_activeFilterCount} Filter${_activeFilterCount > 1 ? 's' : ''}'
                  : 'Show All',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
