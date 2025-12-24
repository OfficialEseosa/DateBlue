import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'models/prompt.dart';
import '../../widgets/onboarding_bottom_bar.dart';
import '../../widgets/prompts/prompts_widgets.dart';

class PromptsStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const PromptsStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PromptsStep> createState() => _PromptsStepState();
}

class _PromptsStepState extends State<PromptsStep> {
  final List<Prompt?> _selectedPrompts = [null, null, null];
  final Map<int, TextEditingController> _controllers = {};
  VoicePrompt? _voicePrompt;
  bool _isLoading = false;
  bool _isPlaying = false;

  // For voice playback
  late PlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _loadExistingPrompts();
    for (int i = 0; i < 3; i++) {
      _controllers[i] = TextEditingController();
    }
    _playerController = PlayerController();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _playerController.dispose();
    super.dispose();
  }

  void _loadExistingPrompts() {
    if (widget.initialData['prompts'] != null) {
      final List<dynamic> prompts = widget.initialData['prompts'];
      for (int i = 0; i < prompts.length && i < 3; i++) {
        _selectedPrompts[i] = Prompt.fromMap(prompts[i]);
        _controllers[i]?.text = prompts[i]['text'] ?? '';
      }
    }
    if (widget.initialData['voicePrompt'] != null) {
      _voicePrompt = VoicePrompt.fromMap(widget.initialData['voicePrompt']);
    }
  }

  int get _filledCount => _selectedPrompts.where((p) => p != null).length;

  void _selectPrompt(int slotIndex) {
    PromptCategoryPicker.show(
      context: context,
      onCategorySelected: (categoryName) {
        PromptSelector.show(
          context: context,
          categoryName: categoryName,
          selectedPrompts: _selectedPrompts,
          onPromptSelected: (question) {
            PromptAnswerSheet.show(
              context: context,
              question: question,
              controller: _controllers[slotIndex]!,
              onSave: () {
                setState(() {
                  _selectedPrompts[slotIndex] = Prompt(
                    id: '$categoryName-${question.hashCode}',
                    category: categoryName,
                    question: question,
                    text: _controllers[slotIndex]!.text.trim(),
                  );
                });
              },
            );
          },
        );
      },
    );
  }

  void _removePrompt(int index) {
    setState(() {
      _selectedPrompts[index] = null;
      _controllers[index]?.clear();
    });
  }

  void _showVoicePromptPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: const Color(0xFF0039A6), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Voice Prompt',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0039A6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a question and record up to 10 seconds',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: PromptTemplates.voicePrompts.length,
                itemBuilder: (context, index) {
                  final question = PromptTemplates.voicePrompts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      VoiceRecorderSheet.show(
                        context: context,
                        question: question,
                        onSave: (voicePrompt) {
                          setState(() => _voicePrompt = voicePrompt);
                        },
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF0039A6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.mic, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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

  Future<void> _playVoicePrompt() async {
    if (_voicePrompt == null) return;

    final path = _voicePrompt!.localPath ?? _voicePrompt!.audioUrl;
    if (path == null) return;

    try {
      if (_isPlaying) {
        await _playerController.stopPlayer();
        setState(() => _isPlaying = false);
      } else {
        await _playerController.preparePlayer(path: path, shouldExtractWaveform: false);
        setState(() => _isPlaying = true);
        await _playerController.startPlayer();
        _playerController.onCompletion.listen((_) {
          if (mounted) setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _saveAndContinue() async {
    final filledPrompts = _selectedPrompts.where((p) => p != null).toList();

    if (filledPrompts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete at least 1 prompt'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final promptsData = filledPrompts.map((p) => p!.toMap()).toList();

      // Upload voice prompt if exists
      Map<String, dynamic>? voicePromptData;
      if (_voicePrompt != null && _voicePrompt!.localPath != null) {
        final file = File(_voicePrompt!.localPath!);
        final ref = FirebaseStorage.instance
            .ref()
            .child('users/${widget.user.uid}/voice_prompts/voice_prompt.m4a');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        voicePromptData = {
          'question': _voicePrompt!.question,
          'audioUrl': url,
          'durationSeconds': _voicePrompt!.durationSeconds,
        };
      } else if (_voicePrompt != null && _voicePrompt!.audioUrl != null) {
        voicePromptData = _voicePrompt!.toMap();
      }

      final data = {
        'prompts': promptsData,
        if (voicePromptData != null) 'voicePrompt': voicePromptData,
        'onboardingStep': 16,
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
          SnackBar(content: Text('Error saving prompts: $e'), backgroundColor: Colors.red),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Express Yourself',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add at least 1 prompt to show off your personality',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  // Progress indicator
                  _buildProgressBadge(),

                  const SizedBox(height: 20),

                  // Text Prompts - use Expanded to fill available space
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          Expanded(
                            child: PromptSlotCard(
                              prompt: _selectedPrompts[i],
                              index: i,
                              onTap: () => _selectPrompt(i),
                              onRemove: () => _removePrompt(i),
                            ),
                          ),
                          if (i < 2) const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Voice Prompt Section
                  _buildVoicePromptSection(),
                ],
              ),
            ),
          ),
        ),
        OnboardingBottomBar(
          onBack: widget.onBack,
          onContinue: _saveAndContinue,
          isLoading: _isLoading,
          canContinue: _filledCount >= 1,
        ),
      ],
    );
  }

  Widget _buildProgressBadge() {
    final isComplete = _filledCount >= 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.edit,
            size: 18,
            color: isComplete ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 6),
          Text(
            '$_filledCount prompt${_filledCount == 1 ? '' : 's'} added',
            style: TextStyle(
              fontSize: 14,
              color: isComplete ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePromptSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.08),
            Colors.deepOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mic, color: Colors.deepOrange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Prompt',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Optional • Up to 10 seconds',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_voicePrompt != null)
            VoicePromptCard(
              voicePrompt: _voicePrompt!,
              isPlaying: _isPlaying,
              onPlay: _playVoicePrompt,
              onRemove: () => setState(() => _voicePrompt = null),
            )
          else
            GestureDetector(
              onTap: _showVoicePromptPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.orange[700], size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add Voice Recording',
                      style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600),
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
