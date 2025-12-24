import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/profile_options.dart';
import '../../../widgets/top_notification.dart';
import '../edit_profile/widgets/edit_profile_sheets.dart';

/// Edit screen for test users - reuses EditProfileSheets
class EditTestUserScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditTestUserScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<EditTestUserScreen> createState() => _EditTestUserScreenState();
}

class _EditTestUserScreenState extends State<EditTestUserScreen> {
  late Map<String, dynamic> _userData;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
  }

  Future<void> _saveField(String field, dynamic value, {Map<String, dynamic>? extra}) async {
    setState(() => _isSaving = true);
    try {
      final data = {field: value, 'updatedAt': FieldValue.serverTimestamp()};
      if (extra != null) data.addAll(extra);
      
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(data);

      setState(() {
        _userData[field] = value;
        if (extra != null) _userData.addAll(extra);
        _isSaving = false;
      });
      
      if (mounted) showTopNotification(context, 'Saved');
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test User'),
        content: Text('Delete ${_userData['firstName']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).delete();
      if (mounted) {
        showTopNotification(context, 'User deleted');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _userData['firstName'] ?? 'Test User',
          style: const TextStyle(color: Color(0xFF0039A6), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteUser,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('BASIC INFO'),
                const SizedBox(height: 12),
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                
                _buildSectionHeader('IDENTITY'),
                const SizedBox(height: 12),
                _buildIdentitySection(),
                const SizedBox(height: 24),
                
                _buildSectionHeader('VITALS'),
                const SizedBox(height: 12),
                _buildVitalsSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2));
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    final isSet = value != 'Add' && value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isSet ? const Color(0xFF0039A6).withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSet ? const Color(0xFF0039A6) : Colors.grey[400], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  Text(value.isEmpty ? 'Add' : value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isSet ? Colors.black87 : const Color(0xFF0039A6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  // =================== BASIC INFO ===================
  Widget _buildBasicInfoSection() {
    return _buildCard([
      _buildRow(icon: Icons.person, label: 'First Name', value: _userData['firstName'] ?? '', onTap: _showNameSheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.cake, label: 'Age', value: _getAge(), onTap: () => showTopNotification(context, 'Age is calculated from birth date')),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.school, label: 'Campus', value: _userData['campus'] ?? 'Add', onTap: _showCampusSheet),
    ]);
  }

  String _getAge() {
    final dob = _userData['dateOfBirth'];
    if (dob == null) return 'Add';
    final birthDate = dob is Timestamp ? dob.toDate() : DateTime.now();
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    return '$age years old';
  }

  void _showNameSheet() {
    final controller = TextEditingController(text: _userData['firstName'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditProfileSheets.buildHandle(),
              EditProfileSheets.buildTitle('First Name'),
              const SizedBox(height: 20),
              TextField(controller: controller, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              EditProfileSheets.buildSaveButton(() { Navigator.pop(context); _saveField('firstName', controller.text); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showCampusSheet() => EditProfileSheets.showSingleSelect(
    context: context, title: 'Campus',
    options: ProfileOptions.campusOptions.map((c) => {'value': c, 'label': c}).toList(),
    currentValue: _userData['campus'],
    onSelect: (v) => _saveField('campus', v),
  );

  // =================== IDENTITY ===================
  Widget _buildIdentitySection() {
    return _buildCard([
      _buildRow(icon: Icons.person_outline, label: 'Gender', value: ProfileOptions.getGenderLabel(_userData['gender']), onTap: _showGenderSheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.auto_awesome, label: 'Sexuality', value: ProfileOptions.getSexualityLabel(_userData['sexuality']), onTap: _showSexualitySheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.favorite, label: 'Dating Prefs', value: ProfileOptions.formatDatingPrefList(List<String>.from(_userData['datingPreferences'] ?? [])), onTap: _showDatingPrefsSheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.favorite_border, label: 'Intentions', value: ProfileOptions.getIntentionLabel(_userData['intentions']), onTap: _showIntentionsSheet),
    ]);
  }

  void _showGenderSheet() => EditProfileSheets.showGenderPronouns(
    context: context, currentGender: _userData['gender'], currentPronouns: _userData['pronouns'],
    onSave: (g, p) => _saveField('gender', g, extra: {'pronouns': p}),
  );

  void _showSexualitySheet() => EditProfileSheets.showSingleSelect(
    context: context, title: 'Sexuality',
    options: ProfileOptions.sexualityOptions,
    currentValue: _userData['sexuality'],
    onSelect: (v) => _saveField('sexuality', v),
  );

  void _showDatingPrefsSheet() => EditProfileSheets.showMultiSelect(
    context: context, title: 'Dating Preferences',
    options: ProfileOptions.datingPreferenceOptions,
    currentValues: List<String>.from(_userData['datingPreferences'] ?? []),
    onSave: (v) => _saveField('datingPreferences', v),
  );

  void _showIntentionsSheet() => EditProfileSheets.showSingleSelect(
    context: context, title: 'Intentions',
    options: ProfileOptions.intentionOptions,
    currentValue: _userData['intentions'],
    onSelect: (v) => _saveField('intentions', v),
  );

  // =================== VITALS ===================
  Widget _buildVitalsSection() {
    return _buildCard([
      _buildRow(icon: Icons.height, label: 'Height', value: ProfileOptions.formatHeight(_userData['heightCm']), onTap: _showHeightSheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.people_outline, label: 'Ethnicity', value: ProfileOptions.formatEthnicityList(List<String>.from(_userData['ethnicities'] ?? [])), onTap: _showEthnicitySheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.church_outlined, label: 'Religion', value: ProfileOptions.formatReligiousList(List<String>.from(_userData['religiousBeliefs'] ?? [])), onTap: _showReligionSheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.local_bar, label: 'Substances', value: ProfileOptions.formatSubstanceUse(_userData['drinkingStatus'], _userData['smokingStatus'], _userData['weedStatus']), onTap: _showSubstanceSheet),
      const Divider(height: 1, indent: 56),
      _buildRow(icon: Icons.child_care, label: 'Children', value: ProfileOptions.formatChildren(_userData['children'], _userData['wantChildren']), onTap: _showChildrenSheet),
    ]);
  }

  void _showHeightSheet() => EditProfileSheets.showHeight(
    context: context, currentHeight: _userData['heightCm'] ?? 170,
    onSave: (v) => _saveField('heightCm', v),
  );

  void _showEthnicitySheet() => EditProfileSheets.showMultiSelect(
    context: context, title: 'Ethnicity',
    options: ProfileOptions.ethnicityOptions,
    currentValues: List<String>.from(_userData['ethnicities'] ?? []),
    onSave: (v) => _saveField('ethnicities', v),
  );

  void _showReligionSheet() => EditProfileSheets.showMultiSelect(
    context: context, title: 'Religion',
    options: ProfileOptions.religiousOptions.map((r) => {'value': r['value'], 'label': r['value']}).toList(),
    currentValues: List<String>.from(_userData['religiousBeliefs'] ?? []),
    onSave: (v) => _saveField('religiousBeliefs', v),
  );

  void _showSubstanceSheet() => EditProfileSheets.showSubstanceUse(
    context: context, drinking: _userData['drinkingStatus'], smoking: _userData['smokingStatus'], weed: _userData['weedStatus'],
    onSave: (d, s, w) => _saveField('drinkingStatus', d, extra: {'smokingStatus': s, 'weedStatus': w}),
  );

  void _showChildrenSheet() => EditProfileSheets.showChildren(
    context: context, hasChildren: _userData['children'], wantsChildren: _userData['wantChildren'],
    onSave: (has, wants) => _saveField('children', has, extra: {'wantChildren': wants}),
  );
}
