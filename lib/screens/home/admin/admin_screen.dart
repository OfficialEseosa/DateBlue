import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/top_notification.dart';
import '../../../models/profile_options.dart';
import 'edit_test_user_screen.dart';
import 'dart:math';

/// Admin screen for creating sample/test users for discovery page testing
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isCreating = false;
  int _createdCount = 0;
  
  // Sample data for generating test users
  static const _firstNames = [
    'Alex', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Jamie', 'Avery',
    'Quinn', 'Blake', 'Cameron', 'Drew', 'Emery', 'Finley', 'Harper', 'Hayden',
    'Jesse', 'Kendall', 'Logan', 'Madison', 'Nico', 'Parker', 'Reese', 'Sage',
    'Skyler', 'Sydney', 'Tatum', 'Charlie', 'Dakota', 'Devon', 'Ellis', 'Gray',
  ];
  
  static const _campuses = [
    'Atlanta Campus', 'Alpharetta Campus', 'Clarkston Campus',
    'Decatur Campus', 'Dunwoody Campus', 'Newton Campus',
  ];
  
  static const _genders = ['man', 'woman', 'nonbinary'];
  static const _pronounsList = ['he/him', 'she/her', 'they/them'];
  static const _sexualities = ['straight', 'gay', 'bisexual', 'pansexual'];
  static const _intentions = ['long_term', 'long_open_to_short', 'short_open_to_long', 'figuring_out'];
  static const _ethnicities = ['asian', 'black', 'hispanic', 'white', 'middle_eastern', 'south_asian'];
  static const _religions = ['Christian', 'Catholic', 'Muslim', 'Jewish', 'Spiritual', 'Agnostic', 'Atheist'];
  static const _drinkingOptions = ['Never', 'Rarely', 'Socially', 'Regularly'];
  static const _smokingOptions = ['Never', 'Occasionally', 'Regularly'];
  
  static const _promptQuestions = [
    "I'm looking for...",
    "If loving this is wrong, I don't want to be right...",
    "My simple pleasures...",
    "A life goal of mine...",
    "I geek out on...",
    "My biggest date fail...",
    "Never have I ever...",
    "Best travel story...",
  ];
  
  static const _promptAnswers = [
    "Someone who loves deep conversations and spontaneous adventures",
    "Late night drives with good music",
    "Coffee in the morning, sunset walks, and trying new restaurants",
    "To travel to at least 20 countries before I'm 40",
    "Marvel movies, astronomy, and cooking shows",
    "Accidentally spilled soup on my date... twice",
    "Been skydiving, but it's on my bucket list!",
    "Got lost in Tokyo for 6 hours and found the best ramen shop",
  ];
  
  static const _samplePhotoUrls = [
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
    'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
  ];

  final Random _random = Random();

  T _randomChoice<T>(List<T> list) => list[_random.nextInt(list.length)];
  
  List<T> _randomChoices<T>(List<T> list, int count) {
    final shuffled = List<T>.from(list)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  int _randomBetween(int min, int max) => min + _random.nextInt(max - min + 1);

  Map<String, dynamic> _generateTestUser(int index) {
    final gender = _randomChoice(_genders);
    final age = _randomBetween(18, 28);
    final now = DateTime.now();
    final birthDate = DateTime(now.year - age, _randomBetween(1, 12), _randomBetween(1, 28));
    
    final photos = _randomChoices(_samplePhotoUrls, _randomBetween(2, 4));
    
    final promptCount = _randomBetween(1, 2);
    final promptIndices = _randomChoices(List.generate(_promptQuestions.length, (i) => i), promptCount);
    final prompts = promptIndices.map((i) => {
      'id': '${_promptQuestions[i].hashCode}',
      'category': 'About Me',
      'question': _promptQuestions[i],
      'text': _promptAnswers[i],
    }).toList();

    return {
      'uid': 'test_user_$index',
      'email': 'testuser$index@dateblue.test',
      'isTestUser': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'onboardingStep': 17,
      'isVerified': true,
      'firstName': _randomChoice(_firstNames),
      'dateOfBirth': Timestamp.fromDate(birthDate),
      'campus': _randomChoice(_campuses),
      'gender': gender,
      'pronouns': gender == 'man' ? 'he/him' : (gender == 'woman' ? 'she/her' : _randomChoice(_pronounsList)),
      'sexuality': _randomChoice(_sexualities),
      'datingPreferences': _randomChoices(['men', 'women'], _randomBetween(1, 2)),
      'intentions': _randomChoice(_intentions),
      'ethnicities': _randomChoices(_ethnicities, _randomBetween(1, 2)),
      'religiousBeliefs': [_randomChoice(_religions)],
      'heightCm': _randomBetween(155, 195),
      'hometownCity': 'Atlanta',
      'hometownState': 'GA',
      'drinkingStatus': _randomChoice(_drinkingOptions),
      'smokingStatus': _randomChoice(_smokingOptions),
      'children': 'no_children',
      'wantChildren': _randomChoice(['want_children', 'open_to_children', 'not_sure']),
      'mediaUrls': photos,
      'prompts': prompts,
    };
  }

  Future<void> _createTestUsers(int count) async {
    setState(() { _isCreating = true; _createdCount = 0; });

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < count; i++) {
        final userData = _generateTestUser(DateTime.now().millisecondsSinceEpoch + i);
        final docRef = FirebaseFirestore.instance.collection('users').doc(userData['uid']);
        batch.set(docRef, userData);
        setState(() => _createdCount = i + 1);
      }
      await batch.commit();
      if (mounted) showTopNotification(context, 'Created $count test users!');
    } catch (e) {
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteAllTestUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Test Users'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete All')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isCreating = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('isTestUser', isEqualTo: true).get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) { batch.delete(doc.reference); }
      await batch.commit();
      if (mounted) showTopNotification(context, 'Deleted ${snapshot.docs.length} test users');
    } catch (e) {
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)), onPressed: () => Navigator.pop(context)),
        title: const Text('Admin Tools', style: TextStyle(color: Color(0xFF0039A6), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('Admin area - Dev only', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500))),
              ]),
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('CREATE TEST USERS'),
            const SizedBox(height: 12),
            _buildCard([
              _buildActionButton(icon: Icons.person_add, label: 'Create 5 Test Users', onTap: () => _createTestUsers(5)),
              const Divider(height: 1, indent: 56),
              _buildActionButton(icon: Icons.group_add, label: 'Create 10 Test Users', onTap: () => _createTestUsers(10)),
              const Divider(height: 1, indent: 56),
              _buildActionButton(icon: Icons.groups, label: 'Create 20 Test Users', onTap: () => _createTestUsers(20)),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionHeader('MANAGE'),
            const SizedBox(height: 12),
            _buildCard([
              _buildActionButton(icon: Icons.delete_forever, label: 'Delete All Test Users', color: Colors.red, onTap: _deleteAllTestUsers),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionHeader('SIMULATE LIKE'),
            const SizedBox(height: 12),
            _buildCard([
              _buildActionButton(icon: Icons.favorite, label: 'Test User Likes Real User', color: Colors.pink, onTap: _showSimulateLikeDialog),
            ]),
            
            if (_isCreating) ...[
              const SizedBox(height: 24),
              Center(child: Column(children: [
                const CircularProgressIndicator(color: Color(0xFF0039A6)),
                const SizedBox(height: 8),
                Text('Creating... $_createdCount', style: TextStyle(color: Colors.grey[600])),
              ])),
            ],
            
            const SizedBox(height: 24),
            _buildSectionHeader('TEST USERS'),
            const SizedBox(height: 12),
            _buildTestUsersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2));

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
    child: Column(children: children),
  );

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color color = const Color(0xFF0039A6)}) {
    return InkWell(
      onTap: _isCreating ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color))),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _buildTestUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('isTestUser', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('No test users yet', style: TextStyle(color: Colors.grey[500]))),
          );
        }

        return _buildCard(
          docs.asMap().entries.map((entry) {
            final data = entry.value.data() as Map<String, dynamic>;
            final userId = entry.value.id;
            final name = data['firstName'] ?? 'Unknown';
            final gender = ProfileOptions.getGenderLabel(data['gender']);
            final campus = data['campus'] ?? '';
            final photoUrl = (data['mediaUrls'] as List?)?.isNotEmpty == true ? data['mediaUrls'][0] : null;

            return Column(children: [
              if (entry.key > 0) const Divider(height: 1, indent: 70),
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditTestUserScreen(userId: userId, userData: data)));
                  if (result == true) setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: photoUrl != null
                          ? CachedNetworkImage(imageUrl: photoUrl, width: 50, height: 50, fit: BoxFit.cover, placeholder: (_, __) => Container(width: 50, height: 50, color: Colors.grey[200]), errorWidget: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.person)))
                          : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('$gender • $campus', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ])),
                    Icon(Icons.edit, color: Colors.grey[400], size: 20),
                  ]),
                ),
              ),
            ]);
          }).toList(),
        );
      },
    );
  }

  void _showSimulateLikeDialog() {
    String? selectedTestUserId;
    String? selectedRealUserId;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Simulate Like'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Test User (who will like):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('isTestUser', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final testUsers = snapshot.data!.docs;
                    return DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select test user'),
                      value: selectedTestUserId,
                      items: testUsers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(value: doc.id, child: Text(data['firstName'] ?? doc.id));
                      }).toList(),
                      onChanged: (value) => setDialogState(() => selectedTestUserId = value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('Select Real User (who will receive like):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('isTestUser', isNotEqualTo: true).limit(20).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final realUsers = snapshot.data!.docs.where((d) => d.data() is Map && (d.data() as Map)['isTestUser'] != true).toList();
                    return DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select real user'),
                      value: selectedRealUserId,
                      items: realUsers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(value: doc.id, child: Text('${data['firstName'] ?? 'Unknown'} (${data['googleEmail'] ?? doc.id})'));
                      }).toList(),
                      onChanged: (value) => setDialogState(() => selectedRealUserId = value),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedTestUserId != null && selectedRealUserId != null
                  ? () async {
                      Navigator.pop(context);
                      await _simulateLike(selectedTestUserId!, selectedRealUserId!);
                    }
                  : null,
              child: const Text('Simulate Like'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulateLike(String fromUserId, String toUserId) async {
    try {
      // Create the interaction
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .collection('interactions')
          .doc(toUserId)
          .set({
        'action': 'like',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Add to receivedLikes
      await FirebaseFirestore.instance.collection('users').doc(toUserId).update({
        'receivedLikes': FieldValue.arrayUnion([{
          'fromUserId': fromUserId,
          'timestamp': DateTime.now().toIso8601String(),
        }]),
      });
      
      if (mounted) showTopNotification(context, 'Like simulated successfully!');
    } catch (e) {
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    }
  }
}

