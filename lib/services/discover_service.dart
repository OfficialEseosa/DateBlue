import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for matching algorithm and candidate discovery
class DiscoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Fetches compatible profiles for the current user
  Future<List<Map<String, dynamic>>> getDiscoverCandidates({
    required String currentUserId,
    required Map<String, dynamic> currentUserData,
    int limit = 20,
  }) async {
    // Get already interacted user IDs
    final interactedIds = await _getInteractedUserIds(currentUserId);
    interactedIds.add(currentUserId); // Exclude self
    
    // Query all potential candidates
    final snapshot = await _firestore
        .collection('users')
        .where('onboardingStep', isEqualTo: 17) // Completed onboarding
        .get();
    
    // Filter and score candidates
    final candidates = <Map<String, dynamic>>[];
    
    for (final doc in snapshot.docs) {
      if (interactedIds.contains(doc.id)) continue;
      
      final data = doc.data();
      data['uid'] = doc.id;
      
      // Apply hard filters
      if (!_passesHardFilters(currentUserData, data)) continue;
      
      // Calculate compatibility score
      final score = _calculateCompatibilityScore(currentUserData, data);
      data['_score'] = score;
      
      candidates.add(data);
    }
    
    // Sort by score (descending), then shuffle within similar scores
    candidates.sort((a, b) => (b['_score'] as int).compareTo(a['_score'] as int));
    
    // Add some randomness to similar scores
    _shuffleSimilarScores(candidates);
    
    return candidates.take(limit).toList();
  }
  
  /// Gets IDs of users already interacted with (liked or passed)
  Future<Set<String>> _getInteractedUserIds(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('interactions')
        .get();
    
    return snapshot.docs.map((doc) => doc.id).toSet();
  }
  
  /// Hard filters that must pass for a profile to be shown
  bool _passesHardFilters(Map<String, dynamic> currentUser, Map<String, dynamic> candidate) {
    // Skip if no gender or dating preferences set
    final currentGender = currentUser['gender'] as String?;
    final currentDatingPrefs = List<String>.from(currentUser['datingPreferences'] ?? []);
    final candidateGender = candidate['gender'] as String?;
    final candidateDatingPrefs = List<String>.from(candidate['datingPreferences'] ?? []);
    
    if (currentGender == null || candidateGender == null) return false;
    if (currentDatingPrefs.isEmpty || candidateDatingPrefs.isEmpty) return false;
    
    // Check mutual interest based on gender and dating preferences
    final currentInterestedInCandidate = _isInterestedIn(currentGender, currentDatingPrefs, candidateGender);
    final candidateInterestedInCurrent = _isInterestedIn(candidateGender, candidateDatingPrefs, currentGender);
    
    return currentInterestedInCandidate && candidateInterestedInCurrent;
  }
  
  /// Check if a user with given gender/prefs would be interested in target gender
  bool _isInterestedIn(String myGender, List<String> myPrefs, String theirGender) {
    // Map gender to dating preference format
    // Support both formats: 'man'/'men', 'woman'/'women'
    final theirPrefFormats = _genderToPrefFormats(theirGender);
    return myPrefs.any((pref) => theirPrefFormats.contains(pref));
  }
  
  List<String> _genderToPrefFormats(String gender) {
    switch (gender) {
      case 'man': return ['men', 'man'];
      case 'woman': return ['women', 'woman'];
      case 'nonbinary': return ['nonbinary'];
      default: return [gender];
    }
  }
  
  String _genderToPref(String gender) {
    switch (gender) {
      case 'man': return 'men';
      case 'woman': return 'women';
      case 'nonbinary': return 'nonbinary';
      default: return gender;
    }
  }
  
  /// Calculate compatibility score (higher = more compatible)
  int _calculateCompatibilityScore(Map<String, dynamic> currentUser, Map<String, dynamic> candidate) {
    int score = 0;
    
    // Same campus: +10
    if (currentUser['campus'] == candidate['campus'] && currentUser['campus'] != null) {
      score += 10;
    }
    
    // Age proximity: +5 if within 3 years
    final currentDob = currentUser['dateOfBirth'];
    final candidateDob = candidate['dateOfBirth'];
    if (currentDob != null && candidateDob != null) {
      final currentAge = _calculateAge(currentDob);
      final candidateAge = _calculateAge(candidateDob);
      if ((currentAge - candidateAge).abs() <= 3) {
        score += 5;
      }
    }
    
    // Same intentions: +5
    if (currentUser['intentions'] == candidate['intentions'] && currentUser['intentions'] != null) {
      score += 5;
    }
    
    // Shared ethnicities: +3 per match
    final currentEthnicities = List<String>.from(currentUser['ethnicities'] ?? []);
    final candidateEthnicities = List<String>.from(candidate['ethnicities'] ?? []);
    final sharedEthnicities = currentEthnicities.where((e) => candidateEthnicities.contains(e)).length;
    score += sharedEthnicities * 3;
    
    // Shared religion: +2 per match
    final currentReligion = List<String>.from(currentUser['religiousBeliefs'] ?? []);
    final candidateReligion = List<String>.from(candidate['religiousBeliefs'] ?? []);
    final sharedReligion = currentReligion.where((r) => candidateReligion.contains(r)).length;
    score += sharedReligion * 2;
    
    return score;
  }
  
  int _calculateAge(dynamic dob) {
    DateTime birthDate;
    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else {
      return 0;
    }
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
  
  /// Shuffle profiles with similar scores to add variety
  void _shuffleSimilarScores(List<Map<String, dynamic>> candidates) {
    if (candidates.length < 2) return;
    
    int i = 0;
    while (i < candidates.length) {
      int j = i;
      // Find range of similar scores (within 5 points)
      while (j < candidates.length && 
             (candidates[i]['_score'] as int) - (candidates[j]['_score'] as int) <= 5) {
        j++;
      }
      // Shuffle this range
      if (j - i > 1) {
        final sublist = candidates.sublist(i, j);
        sublist.shuffle();
        for (int k = 0; k < sublist.length; k++) {
          candidates[i + k] = sublist[k];
        }
      }
      i = j;
    }
  }
  
  /// Record a like or pass interaction, returns true if it's a match
  Future<bool> recordInteraction({
    required String currentUserId,
    required String targetUserId,
    required bool isLike,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('interactions')
        .doc(targetUserId)
        .set({
      'action': isLike ? 'like' : 'pass',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // If it's a like, also add to target's receivedLikes for the Likes page
    if (isLike) {
      await _firestore.collection('users').doc(targetUserId).update({
        'receivedLikes': FieldValue.arrayUnion([{
          'fromUserId': currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        }]),
      });
      return await _checkForMatch(currentUserId, targetUserId);
    }
    return false;
  }
  
  /// Undo a recent interaction
  Future<void> undoInteraction({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // Delete the interaction
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('interactions')
        .doc(targetUserId)
        .delete();
    
    // Remove from target's receivedLikes
    final targetDoc = await _firestore.collection('users').doc(targetUserId).get();
    final receivedLikes = List<Map<String, dynamic>>.from(targetDoc.data()?['receivedLikes'] ?? []);
    receivedLikes.removeWhere((like) => like['fromUserId'] == currentUserId);
    await _firestore.collection('users').doc(targetUserId).update({
      'receivedLikes': receivedLikes,
    });
  }
  
  /// Check if target has already liked current user = match!
  Future<bool> _checkForMatch(String currentUserId, String targetUserId) async {
    final theirInteraction = await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('interactions')
        .doc(currentUserId)
        .get();
    
    if (theirInteraction.exists && theirInteraction.data()?['action'] == 'like') {
      // It's a match! Create match document for both users
      final matchId = currentUserId.compareTo(targetUserId) < 0
          ? '${currentUserId}_$targetUserId'
          : '${targetUserId}_$currentUserId';
      
      await _firestore.collection('matches').doc(matchId).set({
        'users': [currentUserId, targetUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
      });
      
      // Remove from receivedLikes since they're now matched
      await _firestore.collection('users').doc(currentUserId).update({
        'receivedLikes': FieldValue.arrayRemove([{
          'fromUserId': targetUserId,
        }]),
      });
      await _firestore.collection('users').doc(targetUserId).update({
        'receivedLikes': FieldValue.arrayRemove([{
          'fromUserId': currentUserId,
        }]),
      });
      
      return true;
    }
    return false;
  }
}
