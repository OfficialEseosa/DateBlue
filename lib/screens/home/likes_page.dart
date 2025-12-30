import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/profile_data.dart';
import '../../services/discover_service.dart';
import '../../widgets/profile/expanded_profile_card.dart';
import '../../widgets/top_notification.dart';

class LikesPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const LikesPage({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> with AutomaticKeepAliveClientMixin {
  final DiscoverService _discoverService = DiscoverService();
  
  // Cache profiles to avoid N+1 reads
  final Map<String, ProfileData> _profileCache = {};
  final Set<String> _failedFetches = {}; // Track failed profile fetches
  List<String> _likerIds = [];
  bool _isLoading = true;
  
  // Stream subscription for real-time updates
  StreamSubscription<DocumentSnapshot>? _likesSubscription;
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs
  
  @override
  void initState() {
    super.initState();
    _setupLikesListener();
  }
  
  @override
  void dispose() {
    _likesSubscription?.cancel();
    super.dispose();
  }
  
  void _setupLikesListener() {
    // Listen to real-time changes on the user's document
    _likesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted) return;
      
      final data = snapshot.data();
      final receivedLikes = List<Map<String, dynamic>>.from(data?['receivedLikes'] ?? []);
      var ids = receivedLikes.map((like) => like['fromUserId'] as String).toList();
      
      // Filter out blocked users
      final blockedUsers = List<String>.from(data?['blockedUsers'] ?? []);
      ids = ids.where((id) => !blockedUsers.contains(id)).toList();
      
      // Batch fetch any new profiles
      await _batchFetchProfiles(ids);
      
      if (mounted) {
        setState(() {
          _likerIds = ids;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }
  
  Future<void> _loadLikes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      
      final data = doc.data();
      final receivedLikes = List<Map<String, dynamic>>.from(data?['receivedLikes'] ?? []);
      var ids = receivedLikes.map((like) => like['fromUserId'] as String).toList();
      
      // Filter out blocked users
      final blockedUsers = List<String>.from(data?['blockedUsers'] ?? []);
      ids = ids.where((id) => !blockedUsers.contains(id)).toList();
      
      // Batch fetch all profiles (Firestore whereIn limited to 10, so chunk)
      await _batchFetchProfiles(ids);
      
      if (mounted) {
        setState(() {
          _likerIds = ids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _batchFetchProfiles(List<String> userIds) async {
    // Filter out already cached and failed profiles
    final uncachedIds = userIds.where((id) => 
      !_profileCache.containsKey(id) && !_failedFetches.contains(id)
    ).toList();
    
    if (uncachedIds.isEmpty) return;
    
    // Firestore whereIn limited to 10 items, so chunk
    for (var i = 0; i < uncachedIds.length; i += 10) {
      final chunk = uncachedIds.skip(i).take(10).toList();
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        // Track which IDs were found
        final foundIds = <String>{};
        for (final doc in snapshot.docs) {
          final profileData = ProfileData.fromFirestore(doc.id, doc.data());
          _profileCache[doc.id] = profileData;
          foundIds.add(doc.id);
        }
        
        // Mark missing profiles as failed
        for (final id in chunk) {
          if (!foundIds.contains(id)) {
            _failedFetches.add(id);
          }
        }
      } catch (e) {
        // Mark all in chunk as failed on error
        _failedFetches.addAll(chunk);
        debugPrint('Failed to fetch profiles: $e');
      }
    }
  }
  
  Future<void> _retryFetchProfile(String userId) async {
    _failedFetches.remove(userId);
    setState(() {}); // Trigger rebuild to show loading
    await _batchFetchProfiles([userId]);
    if (mounted) setState(() {});
  }
  
  ProfileData? _getCachedProfile(String userId) {
    return _profileCache[userId];
  }
  
  Future<void> _refreshLikes() async {
    setState(() => _isLoading = true);
    await _loadLikes();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      color: const Color(0xFF97CAEB),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildLikesGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox(height: 8);
  }

  Widget _buildLikesGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_likerIds.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshLikes,
      color: const Color(0xFF0039A6),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _likerIds.length,
        itemBuilder: (context, index) {
          return _buildLikeCard(_likerIds[index]);
        },
      ),
    );
  }

  Widget _buildLikeCard(String userId) {
    final profile = _getCachedProfile(userId);
    
    // Check if fetch failed for this user
    if (_failedFetches.contains(userId)) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white.withValues(alpha: 0.7), size: 32),
              const SizedBox(height: 8),
              Text(
                'Failed to load',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _retryFetchProfile(userId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (profile == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }

    final photoUrl = profile.mediaUrls.isNotEmpty ? profile.mediaUrls.first : null;

    return GestureDetector(
      onTap: () => _showProfileAndOptions(profile),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              if (photoUrl != null)
                CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[300]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
              
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.age != null)
                        Text(
                          '${profile.age}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileAndOptions(ProfileData profile) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ExpandedProfileCard(
            profile: profile,
            isOwnProfile: false,
            onClose: () => Navigator.of(context).pop(),
            onLike: () => _likeBack(profile),
            onPass: () => _passUser(profile),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _likeBack(ProfileData profile) async {
    try {
      final isMatch = await _discoverService.recordInteraction(
        currentUserId: widget.user.uid,
        targetUserId: profile.id,
        isLike: true,
      );
      
      if (isMatch && mounted) {
        _showMatchDialog(profile);
      } else if (mounted) {
        showTopNotification(context, 'Liked ${profile.firstName}!');
      }
    } catch (e) {
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _passUser(ProfileData profile) async {
    try {
      // Record pass interaction and remove from receivedLikes
      await _discoverService.recordInteraction(
        currentUserId: widget.user.uid,
        targetUserId: profile.id,
        isLike: false,
      );
      
      // Remove this user from our receivedLikes
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get().then((doc) async {
        final data = doc.data();
        if (data == null) return;
        
        final receivedLikes = List<dynamic>.from(data['receivedLikes'] ?? []);
        final filtered = receivedLikes.where((like) {
          if (like is Map) {
            return like['fromUserId'] != profile.id;
          }
          return true;
        }).toList();
        
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
          'receivedLikes': filtered,
        });
      });
      
      if (mounted) {
        showTopNotification(context, 'Passed on ${profile.firstName}');
      }
    } catch (e) {
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    }
  }

  void _showMatchDialog(ProfileData profile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0039A6), Color(0xFF4A90D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 60),
              const SizedBox(height: 16),
              const Text("It's a Match!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('You and ${profile.firstName} liked each other!', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0039A6),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          Text(
            'No likes yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone likes you, they\'ll appear here',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
