import 'package:flutter/material.dart';
import '../../../../models/profile_options.dart';
import '../../../../widgets/height_picker.dart';
import '../../../../widgets/city_autocomplete_field.dart';

/// Bottom sheet utilities for edit profile
class EditProfileSheets {
  static const _primaryColor = Color(0xFF0039A6);

  // =================== SHEET HANDLES & TITLES ===================
  static Widget buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static Widget buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor),
      ),
    );
  }

  static Widget buildSaveButton(VoidCallback onPressed, {String label = 'Save'}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  static Widget buildOptionTile({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: isSelected ? _primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // =================== SINGLE SELECT SHEET ===================
  static void showSingleSelect({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> options,
    required String? currentValue,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            buildHandle(),
            buildTitle(title),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options[index];
                  final isSelected = currentValue == opt['value'];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(opt['value']);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _primaryColor : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (opt['icon'] != null) ...[
                            Icon(opt['icon'], color: isSelected ? _primaryColor : Colors.grey[600], size: 22),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              opt['label'],
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected ? _primaryColor : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: _primaryColor, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== MULTI SELECT SHEET ===================
  static void showMultiSelect({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> options,
    required List<String> currentValues,
    required Function(List<String>) onSave,
  }) {
    final selected = List<String>.from(currentValues);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              buildHandle(),
              buildTitle(title),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    final isSelected = selected.contains(opt['value']);
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          if (isSelected) {
                            selected.remove(opt['value']);
                          } else {
                            selected.add(opt['value']);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _primaryColor : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt['label'],
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSelected ? _primaryColor : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                              color: isSelected ? _primaryColor : Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: buildSaveButton(() {
                  Navigator.pop(context);
                  onSave(selected);
                }, label: 'Save (${selected.length} selected)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== HEIGHT SHEET ===================
  static void showHeight({
    required BuildContext context,
    required int currentHeight,
    required Function(int) onSave,
  }) {
    int heightCm = currentHeight;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              buildHandle(),
              buildTitle('Select Height'),
              Expanded(
                child: HeightPicker(
                  initialHeightCm: heightCm,
                  onHeightChanged: (cm) => heightCm = cm,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: buildSaveButton(() {
                  Navigator.pop(context);
                  onSave(heightCm);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== HOMETOWN SHEET ===================
  static void showHometown({
    required BuildContext context,
    required String? currentCity,
    required String? currentState,
    required Function(String city, String state) onSave,
  }) {
    String city = currentCity ?? '';
    String state = currentState ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildHandle(),
              buildTitle('Hometown'),
              const SizedBox(height: 20),
              CityAutocompleteField(
                initialCity: city,
                initialState: state,
                onCitySelected: (c, s) {
                  city = c;
                  state = s;
                },
              ),
              const SizedBox(height: 20),
              buildSaveButton(() {
                Navigator.pop(context);
                onSave(city, state);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // =================== WORKPLACE SHEET ===================
  static void showWorkplace({
    required BuildContext context,
    required String? currentWorkplace,
    required String? currentJobTitle,
    required Function(String workplace, String jobTitle) onSave,
  }) {
    final workplaceController = TextEditingController(text: currentWorkplace ?? '');
    final jobTitleController = TextEditingController(text: currentJobTitle ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildHandle(),
              buildTitle('Work'),
              const SizedBox(height: 20),
              TextField(
                controller: jobTitleController,
                decoration: InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: workplaceController,
                decoration: InputDecoration(
                  labelText: 'Company/Workplace',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              buildSaveButton(() {
                Navigator.pop(context);
                onSave(workplaceController.text, jobTitleController.text);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // =================== GENDER & PRONOUNS SHEET ===================
  static void showGenderPronouns({
    required BuildContext context,
    required String? currentGender,
    required String? currentPronouns,
    required Function(String? gender, String? pronouns) onSave,
  }) {
    String? gender = currentGender;
    String? pronouns = currentPronouns;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              buildHandle(),
              buildTitle('Gender & Pronouns'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ProfileOptions.genderOptions.map((opt) {
                          final isSelected = gender == opt['value'];
                          return GestureDetector(
                            onTap: () => setSheetState(() => gender = opt['value']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryColor : Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                opt['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text('Pronouns', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ProfileOptions.pronounOptions.map((opt) {
                          final isSelected = pronouns == opt['value'];
                          return GestureDetector(
                            onTap: () => setSheetState(() => pronouns = opt['value']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryColor : Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                opt['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: buildSaveButton(() {
                  Navigator.pop(context);
                  onSave(gender, pronouns);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== SUBSTANCE USE SHEET ===================
  static void showSubstanceUse({
    required BuildContext context,
    required String? drinking,
    required String? smoking,
    required String? weed,
    required Function(String? drinking, String? smoking, String? weed) onSave,
  }) {
    String? d = drinking;
    String? s = smoking;
    String? w = weed;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              buildHandle(),
              buildTitle('Substance Use'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubstanceCategory('Drinking', ProfileOptions.drinkingOptions, d, (v) => setSheetState(() => d = v)),
                      const SizedBox(height: 20),
                      _buildSubstanceCategory('Smoking', ProfileOptions.smokingOptions, s, (v) => setSheetState(() => s = v)),
                      const SizedBox(height: 20),
                      _buildSubstanceCategory('Cannabis', ProfileOptions.weedOptions, w, (v) => setSheetState(() => w = v)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: buildSaveButton(() {
                  Navigator.pop(context);
                  onSave(d, s, w);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSubstanceCategory(String title, List<String> options, String? selected, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // =================== CHILDREN SHEET ===================
  static void showChildren({
    required BuildContext context,
    required String? hasChildren,
    required String? wantsChildren,
    required Function(String? has, String? wants) onSave,
  }) {
    String? has = hasChildren;
    String? wants = wantsChildren;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              buildHandle(),
              buildTitle('Children'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Do you have children?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 12),
                      ...ProfileOptions.hasChildrenOptions.map((opt) => buildOptionTile(
                        label: opt['label'],
                        isSelected: has == opt['value'],
                        onTap: () => setSheetState(() => has = opt['value']),
                      )),
                      const SizedBox(height: 20),
                      Text('Do you want children?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 12),
                      ...ProfileOptions.wantChildrenOptions.map((opt) => buildOptionTile(
                        label: opt['label'],
                        isSelected: wants == opt['value'],
                        onTap: () => setSheetState(() => wants = opt['value']),
                      )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: buildSaveButton(() {
                  Navigator.pop(context);
                  onSave(has, wants);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
