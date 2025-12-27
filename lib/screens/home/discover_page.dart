import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../models/profile_data.dart';
import '../../services/discover_service.dart';
import '../../widgets/discover/swipeable_card_stack.dart';
import '../../widgets/discover/filter_sheet.dart';
import '../../widgets/top_notification.dart';

class DiscoverPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const DiscoverPage({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with AutomaticKeepAliveClientMixin {
  final DiscoverService _discoverService = DiscoverService();
  final GlobalKey<SwipeableCardStackState> _cardStackKey = GlobalKey();
  
  List<ProfileData> _profiles = [];
  Map<String, dynamic> _filters = {};
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String? _error;
  
  // Undo functionality
  ProfileData? _lastSwipedProfile;
  Timer? _undoTimer;
  int _undoSecondsLeft = 0;
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _loadProfilesIfNeeded();
  }
  
  void _loadProfilesIfNeeded() {
    if (!_hasLoadedOnce) {
      _loadProfiles();
    }
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfiles({bool forceRefresh = false}) async {
    if (widget.userData == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please complete your profile first';
      });
      return;
    }

    if (forceRefresh || !_hasLoadedOnce) {
      _discoverService.resetPagination();
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final candidates = await _discoverService.getDiscoverCandidates(
        currentUserId: widget.user.uid,
        currentUserData: widget.userData!,
        filters: _filters,
      );

      final profiles = candidates.map((data) {
        return ProfileData.fromFirestore(data['uid'], data);
      }).toList();

      setState(() {
        _profiles = profiles;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading profiles: $e';
      });
    }
  }

  void _startUndoTimer(ProfileData profile, bool wasLike) {
    _undoTimer?.cancel();
    setState(() {
      _lastSwipedProfile = profile;
      _undoSecondsLeft = 15;
    });
    
    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_undoSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _lastSwipedProfile = null;
          _undoSecondsLeft = 0;
        });
      } else {
        setState(() => _undoSecondsLeft--);
      }
    });
  }

  Future<void> _undo() async {
    if (_lastSwipedProfile == null) return;
    
    _undoTimer?.cancel();
    final profile = _lastSwipedProfile!;
    
    try {
      await _discoverService.undoInteraction(
        currentUserId: widget.user.uid,
        targetUserId: profile.id,
      );
      
      // Re-insert profile at the front
      setState(() {
        _profiles.insert(0, profile);
        _lastSwipedProfile = null;
        _undoSecondsLeft = 0;
      });
      
      // Reset card stack to show the profile
      _cardStackKey.currentState?.reset();
      
      if (mounted) showTopNotification(context, 'Undo successful');
    } catch (e) {
      if (mounted) showTopNotification(context, 'Could not undo', isError: true);
    }
  }

  void _loadMoreIfNeeded() {
    // When we're running low on profiles, load more
    final remaining = _profiles.length - (_cardStackKey.currentState?.currentIndex ?? 0);
    if (remaining <= 5 && _discoverService.hasMoreCandidates && !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (widget.userData == null) return;
    
    try {
      final moreCandidates = await _discoverService.loadMoreCandidates(
        currentUserId: widget.user.uid,
      );
      
      if (moreCandidates.isNotEmpty) {
        final moreProfiles = moreCandidates.map((data) {
          return ProfileData.fromFirestore(data['uid'], data);
        }).toList();
        
        setState(() {
          _profiles.addAll(moreProfiles);
        });
      }
    } catch (e) {
      debugPrint('Error loading more profiles: $e');
    }
  }

  Future<void> _onLike(ProfileData profile) async {
    _startUndoTimer(profile, true);
    _loadMoreIfNeeded();
    
    try {
      final isMatch = await _discoverService.recordInteraction(
        currentUserId: widget.user.uid,
        targetUserId: profile.id,
        isLike: true,
      );
      
      if (isMatch && mounted) {
        _showMatchDialog(profile);
      }
    } catch (e) {
      if (mounted) showTopNotification(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _onPass(ProfileData profile) async {
    _startUndoTimer(profile, false);
    _loadMoreIfNeeded();
    
    try {
      await _discoverService.recordInteraction(
        currentUserId: widget.user.uid,
        targetUserId: profile.id,
        isLike: false,
      );
    } catch (e) {
      // Silent fail for pass
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
                child: const Text('Keep Swiping', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters() {
    FilterSheet.show(
      context: context,
      currentFilters: _filters,
      onApply: (filters) {
        setState(() => _filters = filters);
        _loadProfiles(forceRefresh: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      color: const Color(0xFF97CAEB),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Card content with same size as profile page
              Positioned.fill(child: _buildContent()),
              // Header overlay - positioned inside the padded area
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildHeader(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool canUndo = _undoSecondsLeft > 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Filter button (left) - same style as profile page buttons
        _buildIconButton(
          icon: Icons.tune,
          onTap: _showFilters,
        ),
        // Undo button (right)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUndo) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_undoSecondsLeft',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            _buildIconButton(
              icon: Icons.undo,
              onTap: canUndo ? _undo : null,
              isEnabled: canUndo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: isEnabled ? 0.3 : 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: isEnabled ? 1.0 : 0.5),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProfiles, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('No profiles found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 8),
            Text('Check back later!', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    return SwipeableCardStack(
      key: _cardStackKey,
      profiles: _profiles,
      onLike: _onLike,
      onPass: _onPass,
      onEmpty: () => setState(() {}),
    );
  }
}
