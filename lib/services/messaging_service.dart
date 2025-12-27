import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for messaging functionality between matched users
class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get stream of matches for the current user
  Stream<List<Map<String, dynamic>>> getMatchesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final matches = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        final otherUserId = users.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        // Fetch other user's profile
        final otherUserDoc = await _firestore
            .collection('users')
            .doc(otherUserId)
            .get();

        if (!otherUserDoc.exists) continue;

        final otherUserData = otherUserDoc.data()!;

        matches.add({
          'matchId': doc.id,
          'otherUserId': otherUserId,
          'otherUserName': otherUserData['firstName'] ?? 'User',
          'otherUserPhoto': (otherUserData['mediaUrls'] as List?)?.isNotEmpty == true
              ? otherUserData['mediaUrls'][0]
              : null,
          'lastMessage': data['lastMessage'],
          'lastMessageAt': data['lastMessageAt'],
          'createdAt': data['createdAt'],
          'voiceCallsEnabled': data['voiceCallsEnabled'] ?? {},
          'blockedBy': data['blockedBy'],
        });
      }

      return matches;
    });
  }

  /// Get stream of messages for a specific match
  Stream<List<Map<String, dynamic>>> getMessagesStream(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'messageId': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Send a text message
  Future<void> sendMessage({
    required String matchId,
    required String content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final now = FieldValue.serverTimestamp();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 30)),
    );

    // Add message to subcollection
    await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .add({
      'senderId': userId,
      'type': type,
      'content': content,
      'mediaUrl': mediaUrl,
      'timestamp': now,
      'edited': false,
      'deleted': false,
      'readBy': [userId],
      'expiresAt': expiresAt,
    });

    // Update last message on match document
    String preview = content;
    if (type == 'image') preview = '📷 Photo';
    if (type == 'audio') preview = '🎤 Voice message';
    if (preview.length > 50) preview = '${preview.substring(0, 50)}...';

    await _firestore.collection('matches').doc(matchId).update({
      'lastMessage': {
        'text': preview,
        'senderId': userId,
        'timestamp': now,
      },
      'lastMessageAt': now,
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String matchId) async {
    final userId = currentUserId;
    if (userId == null) return;

    final allMessages = await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .get();

    // Filter to unread messages in client
    final unreadMessages = allMessages.docs.where((doc) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      return !readBy.contains(userId);
    });

    if (unreadMessages.isEmpty) return;

    // Update each unread message
    final batch = _firestore.batch();
    for (final doc in unreadMessages) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }

  /// Edit a message
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final messageRef = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc(messageId);

    final messageDoc = await messageRef.get();
    if (!messageDoc.exists) throw Exception('Message not found');
    if (messageDoc.data()?['senderId'] != userId) {
      throw Exception('Cannot edit others messages');
    }

    await messageRef.update({
      'content': newContent,
      'edited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage({
    required String matchId,
    required String messageId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final messageRef = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc(messageId);

    final messageDoc = await messageRef.get();
    if (!messageDoc.exists) throw Exception('Message not found');
    if (messageDoc.data()?['senderId'] != userId) {
      throw Exception('Cannot delete others messages');
    }

    await messageRef.update({
      'deleted': true,
      'content': '',
    });
  }

  /// Get match document by ID
  Future<Map<String, dynamic>?> getMatch(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    if (!doc.exists) return null;
    return {'matchId': doc.id, ...doc.data()!};
  }

  /// Unmatch - deletes the match document
  Future<void> unmatch(String matchId) async {
    // Delete all messages first
    final messages = await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete match document
    await _firestore.collection('matches').doc(matchId).delete();
  }

  /// Block a user - deletes match and adds to blocked list
  Future<void> blockUser({
    required String matchId,
    required String blockedUserId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Add to current user's blocked list
    await _firestore.collection('users').doc(userId).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    });

    // Delete the match
    await unmatch(matchId);
  }

  /// Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    await _firestore.collection('users').doc(userId).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
    });
  }

  /// Get blocked users list
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final blockedIds = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);

    final blockedUsers = <Map<String, dynamic>>[];
    for (final blockedId in blockedIds) {
      final blockedUserDoc = await _firestore.collection('users').doc(blockedId).get();
      if (blockedUserDoc.exists) {
        final data = blockedUserDoc.data()!;
        blockedUsers.add({
          'userId': blockedId,
          'firstName': data['firstName'] ?? 'User',
          'photoUrl': (data['mediaUrls'] as List?)?.isNotEmpty == true
              ? data['mediaUrls'][0]
              : null,
        });
      }
    }
    return blockedUsers;
  }

  /// Toggle voice calls for a user
  Future<void> toggleVoiceCalls({
    required String matchId,
    required bool enabled,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    await _firestore.collection('matches').doc(matchId).update({
      'voiceCallsEnabled.$userId': enabled,
    });
  }

  /// Check if voice calls are enabled for both users
  bool areVoiceCallsEnabled(Map<String, dynamic> match, String otherUserId) {
    final userId = currentUserId;
    if (userId == null) return false;

    final voiceCallsEnabled = match['voiceCallsEnabled'] as Map<String, dynamic>? ?? {};
    return voiceCallsEnabled[userId] == true && voiceCallsEnabled[otherUserId] == true;
  }
}
