import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for matching algorithm and candidate discovery
class DiscoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store last document for pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMoreCandidates = true;
  Set<String>? _cachedInteractedIds;
  Map<String, dynamic>? _cachedCurrentUserData;
  
  /// Resets pagination state (call when filters change or on refresh)
  void resetPagination() {
    _lastDocument = null;
    _hasMoreCandidates = true;
    _cachedInteractedIds = null;
    _cachedCurrentUserData = null;
  }
  
  /// Whether there are more candidates to load
  bool get hasMoreCandidates => _hasMoreCandidates;
  
  // Cached filters for pagination
  Map<String, dynamic>? _cachedFilters;
  
  /// Fetches compatible profiles for the current user with pagination
  Future<List<Map<String, dynamic>>> getDiscoverCandidates({
    required String currentUserId,
    required Map<String, dynamic> currentUserData,
    Map<String, dynamic>? filters,
    int pageSize = 20,
    bool loadMore = false,
  }) async {
    // Reset cache if this is a fresh load
    if (!loadMore) {
      resetPagination();
      _cachedFilters = filters;
    }
    
    if (!_hasMoreCandidates && loadMore) {
      return [];
    }
    
    final activeFilters = _cachedFilters ?? filters ?? {};
    
    // Get already interacted user IDs (cache for pagination)
    _cachedInteractedIds ??= await _getInteractedUserIds(currentUserId);
    final interactedIds = _cachedInteractedIds!;
    interactedIds.add(currentUserId); // Exclude self
    
    _cachedCurrentUserData = currentUserData;
    
    // Build paginated query
    Query query = _firestore
        .collection('users')
        .where('onboardingStep', isEqualTo: 17) // Completed onboarding
        .limit(pageSize * 3); // Fetch extra to account for filtering
    
    if (_lastDocument != null && loadMore) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    
    if (snapshot.docs.isEmpty) {
      _hasMoreCandidates = false;
      return [];
    }
    
    // Update last document for next page
    _lastDocument = snapshot.docs.last;
    
    // Filter and score candidates
    final candidates = <Map<String, dynamic>>[];
    
    for (final doc in snapshot.docs) {
      if (interactedIds.contains(doc.id)) continue;
      
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      
      // Apply hard filters
      if (!_passesHardFilters(currentUserData, data)) continue;
      
      // Apply user-defined filters
      if (!_passesUserFilters(data, activeFilters)) continue;
      
      // Calculate compatibility score
      final score = _calculateCompatibilityScore(currentUserData, data);
      data['_score'] = score;
      
      candidates.add(data);
      
      // Stop once we have enough valid candidates
      if (candidates.length >= pageSize) break;
    }
    
    // If we got fewer than requested and no more docs, we've reached the end
    if (candidates.length < pageSize && snapshot.docs.length < pageSize * 3) {
      _hasMoreCandidates = false;
    }
    
    // Sort by score (descending), then shuffle within similar scores
    candidates.sort((a, b) => (b['_score'] as int).compareTo(a['_score'] as int));
    
    // Add some randomness to similar scores
    _shuffleSimilarScores(candidates);
    
    return candidates;
  }
  
  /// Load more candidates (convenience method)
  Future<List<Map<String, dynamic>>> loadMoreCandidates({
    required String currentUserId,
  }) async {
    if (_cachedCurrentUserData == null) {
      debugPrint('Cannot load more without initial data');
      return [];
    }
    
    return getDiscoverCandidates(
      currentUserId: currentUserId,
      currentUserData: _cachedCurrentUserData!,
      loadMore: true,
    );
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
  
  /// User-defined filters (age range, campus, lifestyle, etc.)
  bool _passesUserFilters(Map<String, dynamic> candidate, Map<String, dynamic> filters) {
    if (filters.isEmpty) return true;
    
    // Age range filter
    if (filters.containsKey('minAge') || filters.containsKey('maxAge')) {
      final candidateAge = _calculateAge(candidate);
      if (candidateAge != null) {
        final minAge = filters['minAge'] as int? ?? 18;
        final maxAge = filters['maxAge'] as int? ?? 100;
        if (candidateAge < minAge || candidateAge > maxAge) return false;
      }
    }
    
    // Campus filter (multi-select)
    if (filters.containsKey('campuses')) {
      final selectedCampuses = List<String>.from(filters['campuses'] ?? []);
      if (selectedCampuses.isNotEmpty) {
        final candidateCampus = candidate['campus'] as String?;
        if (candidateCampus == null || !selectedCampuses.contains(candidateCampus)) {
          return false;
        }
      }
    }
    
    // Children preference filter
    if (filters.containsKey('children')) {
      final selectedOptions = List<String>.from(filters['children'] ?? []);
      if (selectedOptions.isNotEmpty) {
        final candidateChildren = candidate['children'] as String?;
        if (candidateChildren == null || !selectedOptions.contains(candidateChildren)) {
          return false;
        }
      }
    }
    
    // Smoking filter
    if (filters.containsKey('smoking')) {
      final selectedOptions = List<String>.from(filters['smoking'] ?? []);
      if (selectedOptions.isNotEmpty) {
        final candidateSmoking = candidate['smoking'] as String?;
        if (candidateSmoking == null || !selectedOptions.contains(candidateSmoking)) {
          return false;
        }
      }
    }
    
    // Drinking filter
    if (filters.containsKey('drinking')) {
      final selectedOptions = List<String>.from(filters['drinking'] ?? []);
      if (selectedOptions.isNotEmpty) {
        final candidateDrinking = candidate['drinking'] as String?;
        if (candidateDrinking == null || !selectedOptions.contains(candidateDrinking)) {
          return false;
        }
      }
    }
    
    // Religion filter
    if (filters.containsKey('religion')) {
      final selectedOptions = List<String>.from(filters['religion'] ?? []);
      if (selectedOptions.isNotEmpty) {
        final candidateReligion = candidate['religion'] as String?;
        if (candidateReligion == null || !selectedOptions.contains(candidateReligion)) {
          return false;
        }
      }
    }
    
    // Ethnicity filter
    if (filters.containsKey('ethnicity')) {
      final selectedOptions = List<String>.from(filters['ethnicity'] ?? []);
      if (selectedOptions.isNotEmpty) {
        final candidateEthnicity = candidate['ethnicity'] as String?;
        if (candidateEthnicity == null || !selectedOptions.contains(candidateEthnicity)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  int? _calculateAge(Map<String, dynamic> candidate) {
    final birthday = candidate['birthday'] ?? candidate['dateOfBirth'];
    if (birthday == null) return null;
    
    DateTime? birthDate;
    if (birthday is Timestamp) {
      birthDate = birthday.toDate();
    } else if (birthday is String) {
      birthDate = DateTime.tryParse(birthday);
    }
    
    if (birthDate == null) return null;
    
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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
  
  /// Calculate compatibility score (higher = more compatible)
  int _calculateCompatibilityScore(Map<String, dynamic> currentUser, Map<String, dynamic> candidate) {
    int score = 0;
    
    // Same campus: +10
    if (currentUser['campus'] == candidate['campus'] && currentUser['campus'] != null) {
      score += 10;
    }
    
    // Age proximity: +5 if within 3 years
    final currentAge = _calculateAge(currentUser);
    final candidateAge = _calculateAge(candidate);
    if (currentAge != null && candidateAge != null) {
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
    
    // Note: receivedLikes updates and match detection are now handled
    // server-side by Cloud Function (onInteractionCreated)
    // Return false here - the client will check for matches separately
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
}
