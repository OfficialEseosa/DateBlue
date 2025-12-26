import 'package:flutter/material.dart';
import '../../models/profile_options.dart';

/// Filter sheet for discover preferences
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
  late List<String> _selectedCampuses;
  late RangeValues _ageRange;

  @override
  void initState() {
    super.initState();
    _selectedCampuses = List<String>.from(widget.currentFilters['campuses'] ?? []);
    _ageRange = widget.currentFilters['ageRange'] ?? const RangeValues(18, 30);
  }

  void _reset() {
    setState(() {
      _selectedCampuses = [];
      _ageRange = const RangeValues(18, 30);
    });
  }

  void _apply() {
    widget.onApply({
      'campuses': _selectedCampuses,
      'ageRange': _ageRange,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          TextButton(
            onPressed: _reset,
            child: Text('Reset', style: TextStyle(color: Colors.grey[600])),
          ),
          const Expanded(
            child: Text(
              'Filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age Range
          _buildSectionTitle('Age Range'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_ageRange.start.round()}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${_ageRange.end.round()}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 40,
            divisions: 22,
            activeColor: const Color(0xFF0039A6),
            onChanged: (values) => setState(() => _ageRange = values),
          ),
          
          const SizedBox(height: 24),
          
          // Campus Filter
          _buildSectionTitle('Campus'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProfileOptions.campusOptions.map((campus) {
              final isSelected = _selectedCampuses.contains(campus);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCampuses.remove(campus);
                    } else {
                      _selectedCampuses.add(campus);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0039A6) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0039A6) : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    campus.replaceAll(' Campus', ''),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
    );
  }

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0039A6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
