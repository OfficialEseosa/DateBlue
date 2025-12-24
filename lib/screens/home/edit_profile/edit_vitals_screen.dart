import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/city_autocomplete_field.dart';

class EditVitalsScreen extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;
  final String initialField;

  const EditVitalsScreen({
    super.key,
    required this.user,
    this.userData,
    required this.initialField,
  });

  @override
  State<EditVitalsScreen> createState() => _EditVitalsScreenState();
}

class _EditVitalsScreenState extends State<EditVitalsScreen> {
  bool _isLoading = false;
  bool _hasChanges = false;
  
  // Field values
  String? _selectedCampus;
  int _heightCm = 170; // Store height in cm, convert for display
  String? _hometownCity;
  String? _hometownState;
  String? _workplace;
  String? _jobTitle;
  List<String> _ethnicity = [];
  List<String> _datingPreferences = [];
  String? _gender;
  String? _pronouns;
  String? _sexuality;
  String? _religiousBeliefs;
  String? _smoking;
  String? _drinking;
  String? _marijuana;
  String? _children;
  String? _wantChildren;
  String? _intentions;
  
  // Visibility toggles
  bool _showHeightOnProfile = true;
  bool _showEthnicityOnProfile = true;
  bool _showWorkplaceOnProfile = true;
  bool _showSexualityOnProfile = true;
  bool _showPronounsOnProfile = true;
  bool _showReligiousOnProfile = true;
  bool _showSubstanceOnProfile = true;
  bool _showChildrenOnProfile = true;

  final List<String> _campusOptions = [
    'Atlanta Campus',
    'Alpharetta Campus', 
    'Clarkston Campus',
    'Decatur Campus',
    'Dunwoody Campus',
    'Newton Campus',
  ];

  final List<String> _ethnicityOptions = [
    'Black/African American',
    'White/Caucasian',
    'Hispanic/Latino',
    'Asian',
    'Middle Eastern',
    'Native American',
    'Pacific Islander',
    'Mixed/Multiracial',
    'Other',
  ];

  final List<String> _datingPreferenceOptions = [
    'Men',
    'Women',
    'Non-binary',
    'Everyone',
  ];

  final List<String> _genderOptions = [
    'man',
    'woman',
    'nonbinary',
  ];

  final List<String> _pronounOptions = [
    'he/him',
    'she/her',
    'they/them',
    'other',
  ];

  final List<String> _sexualityOptions = [
    'Straight',
    'Gay',
    'Lesbian',
    'Bisexual',
    'Pansexual',
    'Asexual',
    'Queer',
    'Questioning',
    'Other',
  ];

  final List<String> _religiousOptions = [
    'Agnostic',
    'Atheist',
    'Buddhist',
    'Catholic',
    'Christian',
    'Hindu',
    'Jewish',
    'Muslim',
    'Spiritual',
    'Other',
    'Prefer not to say',
  ];

  final List<String> _substanceOptions = [
    'Never',
    'Rarely',
    'Sometimes',
    'Often',
  ];

  // "Do you have children?" options
  final List<String> _hasChildrenOptions = [
    'no_children',
    'have_children',
  ];

  // "Do you want children?" options
  final List<String> _wantChildrenOptions = [
    'want_children',
    'dont_want_children',
    'open_to_children',
    'not_sure',
  ];

  final List<String> _intentionsOptions = [
    'Long-term relationship',
    'Short-term relationship',
    'Casual dating',
    'New friends',
    'Still figuring it out',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = widget.userData;
    if (data == null) return;

    // All fields use strict, single types
    _selectedCampus = data['campus'] as String?;
    _heightCm = data['heightCm'] as int? ?? 170;
    _hometownCity = data['hometownCity'] as String?;
    _hometownState = data['hometownState'] as String?;
    _workplace = data['workplace'] as String?;
    _jobTitle = data['jobTitle'] as String?;
    _ethnicity = List<String>.from(data['ethnicities'] ?? []);
    _datingPreferences = List<String>.from(data['datingPreferences'] ?? []);
    _gender = data['gender'] as String?;
    _pronouns = data['pronouns'] as String?;
    _sexuality = data['sexuality'] as String?;
    
    // religiousBeliefs is always List<String>
    final beliefs = data['religiousBeliefs'] as List?;
    _religiousBeliefs = beliefs != null && beliefs.isNotEmpty ? beliefs.first as String : null;
    
    // Substance use - all String
    _smoking = data['smokingStatus'] as String?;
    _drinking = data['drinkingStatus'] as String?;
    _marijuana = data['weedStatus'] as String?;
    
    // Children - two separate String fields
    _children = data['children'] as String?;
    _wantChildren = data['wantChildren'] as String?;
    _intentions = data['intentions'] as String?;
    
    // Visibility toggles - all bool
    _showHeightOnProfile = data['showHeightOnProfile'] as bool? ?? true;
    _showEthnicityOnProfile = data['showEthnicityOnProfile'] as bool? ?? true;
    _showWorkplaceOnProfile = data['showWorkplaceOnProfile'] as bool? ?? true;
    _showSexualityOnProfile = data['showSexualityOnProfile'] as bool? ?? true;
    _showPronounsOnProfile = data['showPronounsOnProfile'] as bool? ?? true;
    _showReligiousOnProfile = data['showReligiousBeliefOnProfile'] as bool? ?? true;
    _showSubstanceOnProfile = data['showSubstanceUseOnProfile'] as bool? ?? true;
    _showChildrenOnProfile = data['showChildrenOnProfile'] as bool? ?? true;
  }

  Future<void> _saveField(String field, dynamic value, {Map<String, dynamic>? additionalData}) async {
    setState(() => _isLoading = true);
    
    try {
      final data = <String, dynamic>{
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (additionalData != null) {
        data.addAll(additionalData);
      }
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(data);
      
      setState(() {
        _hasChanges = true;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          title: Text(
            _getFieldTitle(widget.initialField),
            style: const TextStyle(
              color: Color(0xFF0039A6),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0039A6)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildFieldEditor(widget.initialField),
              ),
      ),
    );
  }

  String _getFieldTitle(String field) {
    switch (field) {
      case 'campus': return 'Campus';
      case 'height': return 'Height';
      case 'hometown': return 'Hometown';
      case 'workplace': return 'Work';
      case 'ethnicity': return 'Ethnicity';
      case 'datingPreferences': return 'Dating Preferences';
      case 'pronouns': return 'Gender & Pronouns';
      case 'sexuality': return 'Sexuality';
      case 'religiousBeliefs': return 'Religious Beliefs';
      case 'substanceUse': return 'Substance Use';
      case 'children': return 'Children';
      case 'intentions': return 'Dating Intentions';
      case 'prompts': return 'Profile Prompts';
      default: return 'Edit';
    }
  }

  Widget _buildFieldEditor(String field) {
    switch (field) {
      case 'campus':
        return _buildSingleSelectEditor(
          options: _campusOptions,
          selectedValue: _selectedCampus,
          onSelect: (value) {
            setState(() => _selectedCampus = value);
            _saveField('campus', value);
          },
        );
      case 'height':
        return _buildHeightEditor();
      case 'hometown':
        return _buildHometownEditor();
      case 'workplace':
        return _buildWorkplaceEditor();
      case 'ethnicity':
        return _buildMultiSelectEditor(
          options: _ethnicityOptions,
          selectedValues: _ethnicity,
          showOnProfile: _showEthnicityOnProfile,
          onToggleVisibility: (value) {
            setState(() => _showEthnicityOnProfile = value);
            _saveField('showEthnicityOnProfile', value);
          },
          onSelect: (values) {
            setState(() => _ethnicity = values);
            _saveField('ethnicities', values, additionalData: {
              'showEthnicityOnProfile': _showEthnicityOnProfile,
            });
          },
        );
      case 'datingPreferences':
        return _buildMultiSelectEditor(
          options: _datingPreferenceOptions,
          selectedValues: _datingPreferences,
          onSelect: (values) {
            setState(() => _datingPreferences = values);
            _saveField('datingPreferences', values);
          },
        );
      case 'pronouns':
        return _buildGenderPronounsEditor();
      case 'sexuality':
        return _buildSingleSelectEditor(
          options: _sexualityOptions,
          selectedValue: _sexuality,
          showOnProfile: _showSexualityOnProfile,
          onToggleVisibility: (value) {
            setState(() => _showSexualityOnProfile = value);
            _saveField('showSexualityOnProfile', value);
          },
          onSelect: (value) {
            setState(() => _sexuality = value);
            _saveField('sexuality', value, additionalData: {
              'showSexualityOnProfile': _showSexualityOnProfile,
            });
          },
        );
      case 'religiousBeliefs':
        return _buildSingleSelectEditor(
          options: _religiousOptions,
          selectedValue: _religiousBeliefs,
          showOnProfile: _showReligiousOnProfile,
          onToggleVisibility: (value) {
            setState(() => _showReligiousOnProfile = value);
            _saveField('showReligiousBeliefOnProfile', value);
          },
          onSelect: (value) {
            setState(() => _religiousBeliefs = value);
            _saveField('religiousBeliefs', [value], additionalData: {
              'showReligiousBeliefOnProfile': _showReligiousOnProfile,
            });
          },
        );
      case 'substanceUse':
        return _buildSubstanceEditor();
      case 'children':
        return _buildChildrenEditor();
      case 'intentions':
        return _buildSingleSelectEditor(
          options: _intentionsOptions,
          selectedValue: _intentions,
          onSelect: (value) {
            setState(() => _intentions = value);
            _saveField('intentions', value);
          },
        );
      case 'prompts':
        return _buildPromptsEditor();
      default:
        return const Center(child: Text('Editor not available'));
    }
  }

  Widget _buildSingleSelectEditor({
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelect,
    bool? showOnProfile,
    Function(bool)? onToggleVisibility,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return Column(
                children: [
                  if (options.indexOf(option) > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  InkWell(
                    onTap: () => onSelect(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? const Color(0xFF0039A6) : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF0039A6),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        if (showOnProfile != null && onToggleVisibility != null) ...[
          const SizedBox(height: 20),
          _buildVisibilityToggle(showOnProfile, onToggleVisibility),
        ],
      ],
    );
  }

  Widget _buildMultiSelectEditor({
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onSelect,
    bool? showOnProfile,
    Function(bool)? onToggleVisibility,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);
              return Column(
                children: [
                  if (options.indexOf(option) > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  InkWell(
                    onTap: () {
                      final newValues = List<String>.from(selectedValues);
                      if (isSelected) {
                        newValues.remove(option);
                      } else {
                        newValues.add(option);
                      }
                      onSelect(newValues);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0039A6) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0039A6) : Colors.grey[400]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? const Color(0xFF0039A6) : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        if (showOnProfile != null && onToggleVisibility != null) ...[
          const SizedBox(height: 20),
          _buildVisibilityToggle(showOnProfile, onToggleVisibility),
        ],
      ],
    );
  }

  Widget _buildVisibilityToggle(bool showOnProfile, Function(bool) onToggle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: showOnProfile
                  ? const Color(0xFF0039A6).withOpacity(0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              showOnProfile ? Icons.visibility : Icons.visibility_off,
              color: showOnProfile ? const Color(0xFF0039A6) : Colors.grey[600],
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
                Text(
                  showOnProfile ? 'Visible to others' : 'Hidden from profile',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: showOnProfile,
            onChanged: onToggle,
            activeColor: const Color(0xFF0039A6),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightEditor() {
    // Convert cm to feet/inches for display
    final totalInches = (_heightCm / 2.54).round();
    int feet = totalInches ~/ 12;
    int inches = totalInches % 12;
    if (feet < 4) feet = 4;
    if (feet > 7) feet = 7;
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Display as feet'inches" and also cm
              Text(
                "$feet'$inches\"",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0039A6),
                ),
              ),
              Text(
                '($_heightCm cm)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Feet', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListWheelScrollView(
                            itemExtent: 40,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(initialItem: feet - 4),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                final newFeet = index + 4;
                                _heightCm = ((newFeet * 12 + inches) * 2.54).round();
                              });
                            },
                            children: List.generate(4, (index) => Center(
                              child: Text(
                                '${index + 4}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: (index + 4) == feet ? FontWeight.bold : FontWeight.normal,
                                  color: (index + 4) == feet ? const Color(0xFF0039A6) : Colors.grey,
                                ),
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Inches', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListWheelScrollView(
                            itemExtent: 40,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(initialItem: inches),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _heightCm = ((feet * 12 + index) * 2.54).round();
                              });
                            },
                            children: List.generate(12, (index) => Center(
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: index == inches ? FontWeight.bold : FontWeight.normal,
                                  color: index == inches ? const Color(0xFF0039A6) : Colors.grey,
                                ),
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveField('heightCm', _heightCm, additionalData: {
                    'showHeightOnProfile': _showHeightOnProfile,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0039A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildVisibilityToggle(_showHeightOnProfile, (value) {
          setState(() => _showHeightOnProfile = value);
          _saveField('showHeightOnProfile', value);
        }),
      ],
    );
  }

  Widget _buildWorkplaceEditor() {
    final workplaceController = TextEditingController(text: _workplace);
    final jobTitleController = TextEditingController(text: _jobTitle);
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: workplaceController,
                decoration: InputDecoration(
                  labelText: 'Company or Organization',
                  prefixIcon: const Icon(Icons.business, color: Color(0xFF0039A6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0039A6), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: jobTitleController,
                decoration: InputDecoration(
                  labelText: 'Job Title',
                  prefixIcon: const Icon(Icons.work, color: Color(0xFF0039A6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0039A6), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final workplace = workplaceController.text.trim();
                    final jobTitle = jobTitleController.text.trim();
                    _saveField('workplace', workplace.isNotEmpty ? workplace : null, additionalData: {
                      'jobTitle': jobTitle.isNotEmpty ? jobTitle : null,
                      'showWorkplaceOnProfile': _showWorkplaceOnProfile,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0039A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildVisibilityToggle(_showWorkplaceOnProfile, (value) {
          setState(() => _showWorkplaceOnProfile = value);
          _saveField('showWorkplaceOnProfile', value);
        }),
      ],
    );
  }

  Widget _buildSubstanceEditor() {
    return Column(
      children: [
        // Smoking
        _buildSubstanceSection(
          title: 'Smoking',
          icon: Icons.smoking_rooms,
          selectedValue: _smoking,
          onSelect: (value) {
            setState(() => _smoking = value);
          },
        ),
        const SizedBox(height: 16),
        
        // Drinking
        _buildSubstanceSection(
          title: 'Drinking',
          icon: Icons.local_bar,
          selectedValue: _drinking,
          onSelect: (value) {
            setState(() => _drinking = value);
          },
        ),
        const SizedBox(height: 16),
        
        // Cannabis
        _buildSubstanceSection(
          title: 'Cannabis',
          icon: Icons.grass,
          selectedValue: _marijuana,
          onSelect: (value) {
            setState(() => _marijuana = value);
          },
        ),
        
        const SizedBox(height: 20),
        
        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _saveField('smokingStatus', _smoking, additionalData: {
              'drinkingStatus': _drinking,
              'weedStatus': _marijuana,
              'showSubstanceOnProfile': _showSubstanceOnProfile,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0039A6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        
        const SizedBox(height: 20),
        _buildVisibilityToggle(_showSubstanceOnProfile, (value) {
          setState(() => _showSubstanceOnProfile = value);
          _saveField('showSubstanceOnProfile', value);
        }),
      ],
    );
  }

  Widget _buildSubstanceSection({
    required String title,
    required IconData icon,
    required String? selectedValue,
    required Function(String) onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0039A6)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...(_substanceOptions).map((option) {
            final isSelected = selectedValue == option;
            return InkWell(
              onTap: () => onSelect(option),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? const Color(0xFF0039A6) : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, color: Color(0xFF0039A6), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPromptsEditor() {
    final prompts = List<Map<String, dynamic>>.from(
      widget.userData?['prompts'] ?? [],
    );

    final promptCategories = {
      'About Me': [
        'My simple pleasures',
        'I geek out on',
        'A life goal of mine',
        'Most spontaneous thing I\'ve done',
        'Green flags I look for',
      ],
      'Let\'s Chat About': [
        'The key to my heart is',
        'We\'ll get along if',
        'I want someone who',
        'Dating me is like',
        'My love language is',
      ],
      'My Ideal Date': [
        'Perfect first date',
        'Ideal Sunday morning',
        'Weekend plans',
        'Dream vacation spot',
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current prompts
        if (prompts.isNotEmpty) ...[
          const Text(
            'YOUR PROMPTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...prompts.asMap().entries.map((entry) {
            final prompt = entry.value;
            final id = prompt['id'] as String? ?? '';
            final parts = id.split('-');
            final question = parts.length > 1 ? parts.sublist(1).join('-') : id;
            final answer = prompt['text'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      answer.isEmpty ? 'Tap to add answer' : answer,
                      style: TextStyle(
                        fontSize: 16,
                        color: answer.isEmpty ? const Color(0xFF0039A6) : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _editPrompt(entry.key, prompt),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0039A6),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[200],
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _deletePrompt(entry.key),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Add new prompt
        if (prompts.length < 3) ...[
          const Text(
            'ADD A PROMPT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...promptCategories.entries.map((category) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      category.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0039A6),
                      ),
                    ),
                  ),
                  ...category.value.map((question) {
                    // Check if this prompt is already used
                    final isUsed = prompts.any((p) {
                      final id = p['id'] as String? ?? '';
                      return id.contains(question);
                    });
                    
                    if (isUsed) return const SizedBox.shrink();
                    
                    return InkWell(
                      onTap: () => _addPrompt(category.key, question),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                question,
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF0039A6),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You have added all 3 prompts!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _addPrompt(String category, String question) async {
    final controller = TextEditingController();
    
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          question,
          style: const TextStyle(fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(
            hintText: 'Your answer...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0039A6),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (answer != null && answer.isNotEmpty) {
      final prompts = List<Map<String, dynamic>>.from(
        widget.userData?['prompts'] ?? [],
      );
      
      prompts.add({
        'id': '${category.toLowerCase().replaceAll(' ', '_')}-$question',
        'category': category,
        'text': answer,
      });

      await _saveField('prompts', prompts);
      setState(() {});
    }
  }

  void _editPrompt(int index, Map<String, dynamic> prompt) async {
    final controller = TextEditingController(text: prompt['text'] ?? '');
    final id = prompt['id'] as String? ?? '';
    final parts = id.split('-');
    final question = parts.length > 1 ? parts.sublist(1).join('-') : id;
    
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          question,
          style: const TextStyle(fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(
            hintText: 'Your answer...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0039A6),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (answer != null && answer.isNotEmpty) {
      final prompts = List<Map<String, dynamic>>.from(
        widget.userData?['prompts'] ?? [],
      );
      
      if (index < prompts.length) {
        prompts[index]['text'] = answer;
        await _saveField('prompts', prompts);
        setState(() {});
      }
    }
  }

  void _deletePrompt(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prompt'),
        content: const Text('Are you sure you want to delete this prompt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prompts = List<Map<String, dynamic>>.from(
        widget.userData?['prompts'] ?? [],
      );
      
      if (index < prompts.length) {
        prompts.removeAt(index);
        await _saveField('prompts', prompts);
        setState(() {});
      }
    }
  }

  Widget _buildGenderPronounsEditor() {
    String _formatGender(String? value) {
      switch (value) {
        case 'man': return 'Man';
        case 'woman': return 'Woman';
        case 'nonbinary': return 'Non-binary';
        default: return value ?? '';
      }
    }

    String _formatPronoun(String? value) {
      switch (value) {
        case 'he/him': return 'He/Him';
        case 'she/her': return 'She/Her';
        case 'they/them': return 'They/Them';
        case 'other': return 'Other';
        default: return value ?? '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What is your gender?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _genderOptions.map((option) {
                  final isSelected = _gender == option;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _gender = option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0039A6) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0039A6) : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _formatGender(option),
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
        
        const SizedBox(height: 20),
        
        // Pronouns section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What are your pronouns?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _pronounOptions.map((option) {
                  final isSelected = _pronouns == option;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _pronouns = option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0039A6) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0039A6) : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _formatPronoun(option),
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
        
        const SizedBox(height: 20),
        
        // Visibility toggle
        _buildVisibilityToggle(_showPronounsOnProfile, (value) {
          setState(() => _showPronounsOnProfile = value);
          _saveField('showPronounsOnProfile', value);
        }),
        
        const SizedBox(height: 20),
        
        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _saveField('gender', _gender, additionalData: {
                'pronouns': _pronouns,
                'showPronounsOnProfile': _showPronounsOnProfile,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0039A6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenEditor() {
    String _formatHasChildren(String? value) {
      switch (value) {
        case 'no_children': return "Don't have children";
        case 'have_children': return 'Have children';
        default: return value ?? '';
      }
    }

    String _formatWantChildren(String? value) {
      switch (value) {
        case 'want_children': return 'Want children';
        case 'dont_want_children': return "Don't want children";
        case 'open_to_children': return 'Open to children';
        case 'not_sure': return 'Not sure yet';
        default: return value ?? '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Do you have children?" section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Do you have children?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _hasChildrenOptions.map((option) {
                  final isSelected = _children == option;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _children = option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0039A6) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0039A6) : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _formatHasChildren(option),
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
        
        const SizedBox(height: 20),
        
        // "Do you want children?" section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Do you want children?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _wantChildrenOptions.map((option) {
                  final isSelected = _wantChildren == option;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _wantChildren = option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0039A6) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0039A6) : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _formatWantChildren(option),
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
        
        const SizedBox(height: 20),
        
        // Visibility toggle
        _buildVisibilityToggle(_showChildrenOnProfile, (value) {
          setState(() => _showChildrenOnProfile = value);
          _saveField('showChildrenOnProfile', value);
        }),
        
        const SizedBox(height: 20),
        
        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _saveField('children', _children, additionalData: {
                'wantChildren': _wantChildren,
                'showChildrenOnProfile': _showChildrenOnProfile,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0039A6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildHometownEditor() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where did you grow up?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              CityAutocompleteField(
                initialCity: _hometownCity,
                initialState: _hometownState,
                onCitySelected: (city, state) {
                  setState(() {
                    _hometownCity = city;
                    _hometownState = state;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_hometownCity != null && _hometownState != null) ? () async {
                    await _saveField('hometownCity', _hometownCity, additionalData: {
                      'hometownState': _hometownState,
                      'showHometownOnProfile': true,
                    });
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0039A6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
