import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_vitals_screen.dart';
import 'edit_media_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const EditProfileScreen({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userData = doc.data() ?? widget.userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userData = widget.userData;
          _isLoading = false;
        });
      }
    }
  }

  String _formatHeight(int? heightCm) {
    if (heightCm == null || heightCm == 0) return 'Add';
    // Convert cm to feet/inches for display
    final totalInches = (heightCm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  String _formatList(dynamic listData) {
    if (listData == null) return 'Add';
    if (listData is List && listData.isNotEmpty) {
      return listData.join(', ');
    }
    return 'Add';
  }

  String _formatValue(dynamic value, {String defaultValue = 'Add'}) {
    if (value == null || (value is String && value.isEmpty)) {
      return defaultValue;
    }
    return value.toString();
  }

  String _formatEthnicities(List? ethnicities) {
    if (ethnicities == null || ethnicities.isEmpty) return 'Add';
    
    return ethnicities.map((e) {
      switch (e) {
        case 'asian':
          return 'Asian';
        case 'black':
          return 'Black';
        case 'hispanic':
          return 'Hispanic/Latino';
        case 'indigenous':
          return 'Indigenous';
        case 'middle_eastern':
          return 'Middle Eastern';
        case 'pacific_islander':
          return 'Pacific Islander';
        case 'south_asian':
          return 'South Asian';
        case 'white':
          return 'White';
        default:
          return e.toString();
      }
    }).join(', ');
  }

  String _formatReligiousBeliefs(List? beliefs) {
    if (beliefs == null || beliefs.isEmpty) return 'Add';
    return beliefs.join(', ');
  }

  String _formatIntentions(dynamic intentions) {
    if (intentions == null) return 'Add';
    switch (intentions) {
      case 'long_term':
        return 'Long-term relationship';
      case 'long_open_to_short':
        return 'Long-term, open to short';
      case 'short_open_to_long':
        return 'Short-term, open to long';
      case 'short_term':
        return 'Short-term fun';
      case 'figuring_out':
        return 'Still figuring it out';
      default:
        return intentions.toString();
    }
  }

  String _formatWorkplace(Map<String, dynamic>? data) {
    final workplace = data?['workplace'];
    final jobTitle = data?['jobTitle'];
    if (workplace != null && jobTitle != null) {
      return '$jobTitle at $workplace';
    } else if (workplace != null) {
      return workplace;
    } else if (jobTitle != null) {
      return jobTitle;
    }
    return 'Add';
  }

  String _formatGenderPronouns(Map<String, dynamic>? data) {
    final gender = data?['gender'] as String?;
    final pronouns = data?['pronouns'] as String?;
    
    if (gender != null && pronouns != null) {
      // Capitalize first letter of gender
      final capitalGender = gender.isNotEmpty 
          ? '${gender[0].toUpperCase()}${gender.substring(1)}' 
          : gender;
      return '$capitalGender ($pronouns)';
    } else if (pronouns != null) {
      return pronouns;
    } else if (gender != null) {
      final capitalGender = gender.isNotEmpty 
          ? '${gender[0].toUpperCase()}${gender.substring(1)}' 
          : gender;
      return capitalGender;
    }
    return 'Add';
  }

  String _formatChildren(Map<String, dynamic>? data) {
    final children = data?['children'] as String?;
    final wantChildren = data?['wantChildren'] as String?;
    
    if (children == null && wantChildren == null) return 'Add';
    
    final parts = <String>[];
    
    // Format "Do you have children?"
    if (children != null) {
      switch (children) {
        case 'no_children':
          parts.add("Don't have children");
          break;
        case 'have_children':
          parts.add('Have children');
          break;
        default:
          parts.add(children);
      }
    }
    
    // Format "Do you want children?"
    if (wantChildren != null) {
      switch (wantChildren) {
        case 'want_children':
          parts.add('Want children');
          break;
        case 'dont_want':
          parts.add("Don't want children");
          break;
        case 'want_someday':
          parts.add('Want someday');
          break;
        case 'not_sure':
          parts.add('Not sure yet');
          break;
        case 'prefer_not_to_say':
          break; // Don't show
        default:
          parts.add(wantChildren);
      }
    }
    
    return parts.isEmpty ? 'Add' : parts.join(' • ');
  }

  String _formatHometown(Map<String, dynamic>? data) {
    final city = data?['hometownCity'] as String?;
    final state = data?['hometownState'] as String?;
    if (city != null && state != null) {
      return '$city, $state';
    } else if (city != null) {
      return city;
    }
    return 'Add';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0039A6)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF0039A6),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos Section
            _buildSectionHeader('Photos'),
            const SizedBox(height: 12),
            _buildPhotoGrid(),

            const SizedBox(height: 32),

            // Prompts Section
            _buildSectionHeader('Prompts'),
            const SizedBox(height: 12),
            _buildPromptsSection(),

            const SizedBox(height: 32),

            // Vitals Section
            _buildSectionHeader('My Vitals'),
            const SizedBox(height: 12),
            _buildVitalsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final mediaUrls = (_userData?['mediaUrls'] as List?) ?? [];
    
    return GestureDetector(
      onTap: _navigateToEditMedia,
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3 / 4,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final hasPhoto = index < mediaUrls.length;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasPhoto ? Colors.transparent : Colors.grey[300]!,
                      width: 2,
                      style: hasPhoto ? BorderStyle.none : BorderStyle.solid,
                    ),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            mediaUrls[index],
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.add,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Tap to edit photos',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditMedia() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditMediaScreen(
          user: widget.user,
          userData: _userData,
        ),
      ),
    );
    
    if (result == true) {
      _loadUserData();
    }
  }

  Widget _buildPromptsSection() {
    final prompts = (_userData?['prompts'] as List?) ?? [];
    
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
        children: [
          if (prompts.isEmpty)
            _buildEditRow(
              icon: Icons.chat_bubble_outline,
              label: 'Add prompts',
              value: 'Show off your personality',
              onTap: () => _navigateToEditVitals('prompts'),
            )
          else
            ...prompts.asMap().entries.map((entry) {
              final prompt = entry.value as Map<String, dynamic>;
              // Prompts are stored as {id: "category-question", category: "...", text: "answer"}
              // Extract question from id (format: "category-question")
              final id = prompt['id'] as String? ?? '';
              final parts = id.split('-');
              final question = parts.length > 1 ? parts.sublist(1).join('-') : id;
              final answer = prompt['text'] ?? '';
              
              return Column(
                children: [
                  if (entry.key > 0) const Divider(height: 1, indent: 56),
                  _buildEditRow(
                    icon: Icons.format_quote,
                    label: question,
                    value: answer.isEmpty ? 'Add answer' : answer,
                    onTap: () => _navigateToEditVitals('prompts'),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildVitalsSection() {
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
        children: [
          _buildEditRow(
            icon: Icons.school,
            label: 'Campus',
            value: _formatValue(_userData?['campus']),
            onTap: () => _navigateToEditVitals('campus'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.height,
            label: 'Height',
            value: _formatHeight(_userData?['heightCm']),
            onTap: () => _navigateToEditVitals('height'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.location_city,
            label: 'Hometown',
            value: _formatHometown(_userData),
            onTap: () => _navigateToEditVitals('hometown'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.work_outline,
            label: 'Work',
            value: _formatWorkplace(_userData),
            onTap: () => _navigateToEditVitals('workplace'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.people_outline,
            label: 'Ethnicity',
            value: _formatEthnicities(_userData?['ethnicities']),
            onTap: () => _navigateToEditVitals('ethnicity'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.favorite_border,
            label: 'Dating Preferences',
            value: _formatList(_userData?['datingPreferences']),
            onTap: () => _navigateToEditVitals('datingPreferences'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.person_outline,
            label: 'Gender & Pronouns',
            value: _formatGenderPronouns(_userData),
            onTap: () => _navigateToEditVitals('pronouns'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.auto_awesome,
            label: 'Sexuality',
            value: _formatValue(_userData?['sexuality']),
            onTap: () => _navigateToEditVitals('sexuality'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.church_outlined,
            label: 'Religious Beliefs',
            value: _formatReligiousBeliefs(_userData?['religiousBeliefs']),
            onTap: () => _navigateToEditVitals('religiousBeliefs'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.local_bar_outlined,
            label: 'Substance Use',
            value: _formatSubstanceUse(_userData),
            onTap: () => _navigateToEditVitals('substanceUse'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.child_care_outlined,
            label: 'Children',
            value: _formatChildren(_userData),
            onTap: () => _navigateToEditVitals('children'),
          ),
          const Divider(height: 1, indent: 56),
          _buildEditRow(
            icon: Icons.favorite,
            label: 'Dating Intentions',
            value: _formatIntentions(_userData?['intentions']),
            onTap: () => _navigateToEditVitals('intentions'),
          ),
        ],
      ),
    );
  }

  String _formatSubstanceUse(Map<String, dynamic>? data) {
    final drinking = data?['drinkingStatus'];
    final smoking = data?['smokingStatus'];
    final weed = data?['weedStatus'];
    
    final parts = <String>[];
    if (drinking != null && drinking != 'Prefer not to say') {
      parts.add('Drinks: $drinking');
    }
    if (smoking != null && smoking != 'Prefer not to say') {
      parts.add('Smoking: $smoking');
    }
    if (weed != null && weed != 'Prefer not to say') {
      parts.add('Cannabis: $weed');
    }
    
    if (parts.isEmpty) return 'Add';
    return parts.join(', ');
  }

  void _navigateToEditVitals(String field) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditVitalsScreen(
          user: widget.user,
          userData: _userData,
          initialField: field,
        ),
      ),
    );
    
    if (result == true) {
      // Reload data after edit
      _loadUserData();
    }
  }

  Widget _buildEditRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isAdded = value != 'Add';
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isAdded
                    ? const Color(0xFF0039A6).withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isAdded ? const Color(0xFF0039A6) : Colors.grey[400],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isAdded ? Colors.black87 : const Color(0xFF0039A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
