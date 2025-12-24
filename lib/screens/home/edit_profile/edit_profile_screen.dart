import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../../models/profile_options.dart';
import '../../../widgets/top_notification.dart';
import '../../../widgets/prompts/prompts_widgets.dart';
import '../../onboarding/models/prompt.dart';
import 'widgets/edit_profile_sheets.dart';
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
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Voice prompt playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingVoice = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted && state.processingState == ProcessingState.completed) {
        setState(() => _isPlayingVoice = false);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userData = doc.data() ?? widget.userData ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userData = widget.userData ?? {};
          _isLoading = false;
        });
        showTopNotification(context, 'Error loading profile data', isError: true);
      }
    }
  }

  Future<void> _saveField(String field, dynamic value, {Map<String, dynamic>? extra}) async {
    setState(() => _isSaving = true);
    try {
      final data = {field: value, 'updatedAt': FieldValue.serverTimestamp()};
      if (extra != null) data.addAll(extra);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(data);

      setState(() {
        _userData[field] = value;
        if (extra != null) _userData.addAll(extra);
        _isSaving = false;
      });
      
      if (mounted) showTopNotification(context, 'Saved successfully');
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showTopNotification(context, 'Error saving: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF0039A6))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('PHOTOS'),
                const SizedBox(height: 12),
                _buildPhotoSection(),
                const SizedBox(height: 28),
                
                _buildSectionHeader('PROMPTS'),
                const SizedBox(height: 12),
                _buildPromptsSection(),
                const SizedBox(height: 12),
                _buildVoicePromptSection(),
                const SizedBox(height: 28),
                
                _buildSectionHeader('MY VITALS'),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
        onPressed: () => Navigator.of(context).pop(true),
      ),
      title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF0039A6), fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2),
    );
  }

  // =================== PHOTOS ===================
  Widget _buildPhotoSection() {
    final mediaUrls = (_userData['mediaUrls'] as List?) ?? [];
    
    return GestureDetector(
      onTap: _navigateToEditMedia,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 3 / 4,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final hasPhoto = index < mediaUrls.length;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: hasPhoto ? null : Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: mediaUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: Colors.grey[200]),
                            errorWidget: (_, _, _) => Icon(Icons.broken_image, color: Colors.grey[400]),
                          ),
                        )
                      : Icon(Icons.add, color: Colors.grey[400], size: 28),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('Tap to edit photos', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditMedia() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditMediaScreen(user: widget.user, userData: _userData)),
    );
    if (result == true) _loadUserData();
  }

  // =================== PROMPTS ===================
  Widget _buildPromptsSection() {
    final prompts = (_userData['prompts'] as List?) ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          if (prompts.isEmpty)
            _buildVitalRow(
              icon: Icons.chat_bubble_outline,
              label: 'Add prompts',
              value: 'Show off your personality',
              onTap: _showPromptsEditor,
            )
          else
            ...prompts.asMap().entries.map((entry) {
              final prompt = entry.value as Map<String, dynamic>;
              final question = prompt['question'] as String? ?? 'Prompt';
              final answer = prompt['text'] as String? ?? '';
              
              return Column(
                children: [
                  if (entry.key > 0) const Divider(height: 1, indent: 56),
                  _buildVitalRow(
                    icon: Icons.format_quote,
                    label: question,
                    value: answer.isEmpty ? 'Add answer' : answer,
                    onTap: () => _editPrompt(entry.key, prompt),
                  ),
                ],
              );
            }),
          if (prompts.isNotEmpty && prompts.length < 3)
            Column(
              children: [
                const Divider(height: 1, indent: 56),
                _buildVitalRow(
                  icon: Icons.add_circle_outline,
                  label: 'Add another prompt',
                  value: '${3 - prompts.length} remaining',
                  onTap: _showPromptsEditor,
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showPromptsEditor() {
    // First show category picker
    PromptCategoryPicker.show(
      context: context,
      onCategorySelected: (categoryName) {
        // Then show prompt selector for that category
        _showPromptSelectorForCategory(categoryName);
      },
    );
  }

  void _showPromptSelectorForCategory(String categoryName) {
    // Convert existing prompts to Prompt objects for the selector
    final existingPrompts = (_userData['prompts'] as List? ?? [])
        .map<Prompt?>((p) => Prompt(
              id: p['id'] ?? '',
              category: p['category'] ?? '',
              question: p['question'] ?? '',
              text: p['text'] ?? '',
            ))
        .toList();

    PromptSelector.show(
      context: context,
      categoryName: categoryName,
      selectedPrompts: existingPrompts,
      onPromptSelected: (question) {
        _addNewPrompt(categoryName, question);
      },
    );
  }

  void _addNewPrompt(String category, String question) {
    final controller = TextEditingController();
    
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditProfileSheets.buildHandle(),
              const SizedBox(height: 16),
              Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0039A6))),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Type your answer...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              EditProfileSheets.buildSaveButton(() {
                if (controller.text.trim().isEmpty) {
                  showTopNotification(context, 'Please enter an answer', isError: true);
                  return;
                }
                Navigator.pop(context);
                _savePrompt(category, question, controller.text.trim());
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _editPrompt(int index, Map<String, dynamic> prompt) {
    final controller = TextEditingController(text: prompt['text'] ?? '');
    final question = prompt['question'] as String? ?? 'Prompt';
    
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditProfileSheets.buildHandle(),
              const SizedBox(height: 16),
              Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0039A6))),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Type your answer...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePrompt(index);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: EditProfileSheets.buildSaveButton(() {
                      if (controller.text.trim().isEmpty) {
                        showTopNotification(context, 'Please enter an answer', isError: true);
                        return;
                      }
                      Navigator.pop(context);
                      _updatePrompt(index, controller.text.trim());
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePrompt(String category, String question, String text) async {
    final prompts = List<Map<String, dynamic>>.from(_userData['prompts'] ?? []);
    prompts.add({
      'id': '${category.hashCode}-${question.hashCode}',
      'category': category,
      'question': question,
      'text': text,
    });
    await _saveField('prompts', prompts);
  }

  Future<void> _updatePrompt(int index, String text) async {
    final prompts = List<Map<String, dynamic>>.from(_userData['prompts'] ?? []);
    if (index < prompts.length) {
      prompts[index]['text'] = text;
      await _saveField('prompts', prompts);
    }
  }

  Future<void> _deletePrompt(int index) async {
    final prompts = List<Map<String, dynamic>>.from(_userData['prompts'] ?? []);
    if (index < prompts.length) {
      prompts.removeAt(index);
      await _saveField('prompts', prompts);
    }
  }

  // =================== VOICE PROMPT ===================
  Widget _buildVoicePromptSection() {
    final voicePrompt = _userData['voicePrompt'] as Map<String, dynamic>?;
    
    if (voicePrompt == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: _buildVitalRow(
          icon: Icons.mic,
          label: 'Voice Prompt',
          value: 'Add a voice recording',
          onTap: () => showTopNotification(context, 'Voice prompt recording coming soon'),
        ),
      );
    }
    
    final question = voicePrompt['question'] as String? ?? 'Voice Prompt';
    final duration = voicePrompt['duration'] as int? ?? 0;
    final durationStr = '${(duration / 1000).toStringAsFixed(1)}s';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withValues(alpha: 0.08), Colors.deepOrange.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic, color: Colors.deepOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(durationStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(
                onPressed: _playVoicePrompt,
                icon: Icon(
                  _isPlayingVoice ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.deepOrange,
                  size: 40,
                ),
              ),
              IconButton(
                onPressed: _deleteVoicePrompt,
                icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _playVoicePrompt() async {
    final voicePrompt = _userData['voicePrompt'] as Map<String, dynamic>?;
    if (voicePrompt == null) return;
    
    final audioUrl = voicePrompt['audioUrl'] as String?;
    if (audioUrl == null) return;
    
    try {
      if (_isPlayingVoice) {
        await _audioPlayer.pause();
        setState(() => _isPlayingVoice = false);
      } else {
        await _audioPlayer.setUrl(audioUrl);
        setState(() => _isPlayingVoice = true);
        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() => _isPlayingVoice = false);
      showTopNotification(context, 'Error playing voice prompt', isError: true);
    }
  }

  Future<void> _deleteVoicePrompt() async {
    await _saveField('voicePrompt', null);
    showTopNotification(context, 'Voice prompt deleted');
  }

  // =================== VITALS ===================
  Widget _buildVitalsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildVitalRow(icon: Icons.school, label: 'Campus', value: _userData['campus'] ?? 'Add', onTap: _showCampusSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.height, label: 'Height', value: ProfileOptions.formatHeight(_userData['heightCm']), onTap: _showHeightSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.location_city, label: 'Hometown', value: ProfileOptions.formatHometown(_userData['hometownCity'], _userData['hometownState']), onTap: _showHometownSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.work_outline, label: 'Work', value: ProfileOptions.formatWorkplace(_userData['workplace'], _userData['jobTitle']), onTap: _showWorkplaceSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.people_outline, label: 'Ethnicity', value: ProfileOptions.formatEthnicityList(List<String>.from(_userData['ethnicities'] ?? [])), onTap: _showEthnicitySheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.favorite_border, label: 'Dating Preferences', value: ProfileOptions.formatDatingPrefList(List<String>.from(_userData['datingPreferences'] ?? [])), onTap: _showDatingPrefsSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.person_outline, label: 'Gender & Pronouns', value: ProfileOptions.formatGenderPronouns(_userData['gender'], _userData['pronouns']), onTap: _showGenderPronounsSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.auto_awesome, label: 'Sexuality', value: ProfileOptions.getSexualityLabel(_userData['sexuality']), onTap: _showSexualitySheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.church_outlined, label: 'Religious Beliefs', value: ProfileOptions.formatReligiousList(List<String>.from(_userData['religiousBeliefs'] ?? [])), onTap: _showReligionSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.local_bar_outlined, label: 'Substance Use', value: ProfileOptions.formatSubstanceUse(_userData['drinkingStatus'], _userData['smokingStatus'], _userData['weedStatus']), onTap: _showSubstanceSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.child_care_outlined, label: 'Children', value: ProfileOptions.formatChildren(_userData['children'], _userData['wantChildren']), onTap: _showChildrenSheet),
          const Divider(height: 1, indent: 56),
          _buildVitalRow(icon: Icons.favorite, label: 'Dating Intentions', value: ProfileOptions.getIntentionLabel(_userData['intentions']), onTap: _showIntentionsSheet),
        ],
      ),
    );
  }

  Widget _buildVitalRow({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    final isAdded = value != 'Add';
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isAdded ? const Color(0xFF0039A6).withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isAdded ? const Color(0xFF0039A6) : Colors.grey[400], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isAdded ? Colors.black87 : const Color(0xFF0039A6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  // =================== SHEET HANDLERS ===================
  void _showCampusSheet() => EditProfileSheets.showSingleSelect(
    context: context, title: 'Select Campus',
    options: ProfileOptions.campusOptions.map((c) => {'value': c, 'label': c}).toList(),
    currentValue: _userData['campus'],
    onSelect: (v) => _saveField('campus', v),
  );

  void _showHeightSheet() => EditProfileSheets.showHeight(
    context: context, currentHeight: _userData['heightCm'] ?? 170,
    onSave: (v) => _saveField('heightCm', v),
  );

  void _showHometownSheet() => EditProfileSheets.showHometown(
    context: context, currentCity: _userData['hometownCity'], currentState: _userData['hometownState'],
    onSave: (city, state) => _saveField('hometownCity', city, extra: {'hometownState': state}),
  );

  void _showWorkplaceSheet() => EditProfileSheets.showWorkplace(
    context: context, currentWorkplace: _userData['workplace'], currentJobTitle: _userData['jobTitle'],
    onSave: (wp, jt) => _saveField('workplace', wp, extra: {'jobTitle': jt}),
  );

  void _showEthnicitySheet() => EditProfileSheets.showMultiSelect(
    context: context, title: 'Select Ethnicity',
    options: ProfileOptions.ethnicityOptions,
    currentValues: List<String>.from(_userData['ethnicities'] ?? []),
    onSave: (v) => _saveField('ethnicities', v),
  );

  void _showDatingPrefsSheet() => EditProfileSheets.showMultiSelect(
    context: context, title: 'Dating Preferences',
    options: ProfileOptions.datingPreferenceOptions,
    currentValues: List<String>.from(_userData['datingPreferences'] ?? []),
    onSave: (v) => _saveField('datingPreferences', v),
  );

  void _showGenderPronounsSheet() => EditProfileSheets.showGenderPronouns(
    context: context, currentGender: _userData['gender'], currentPronouns: _userData['pronouns'],
    onSave: (g, p) => _saveField('gender', g, extra: {'pronouns': p}),
  );

  void _showSexualitySheet() => EditProfileSheets.showSingleSelect(
    context: context, title: 'Sexuality',
    options: ProfileOptions.sexualityOptions,
    currentValue: _userData['sexuality'],
    onSelect: (v) => _saveField('sexuality', v),
  );

  void _showReligionSheet() => EditProfileSheets.showMultiSelect(
    context: context, title: 'Religious Beliefs',
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

  void _showIntentionsSheet() => EditProfileSheets.showSingleSelect(
    context: context, title: 'Dating Intentions',
    options: ProfileOptions.intentionOptions,
    currentValue: _userData['intentions'],
    onSelect: (v) => _saveField('intentions', v),
  );
}
