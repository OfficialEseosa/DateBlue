import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for caching chat messages and images locally
class MessageCacheService {
  static const String _messagesBoxName = 'messages';
  static const String _syncMetaBoxName = 'sync_meta';
  
  static bool _initialized = false;
  
  /// Initialize Hive for message caching
  static Future<void> init() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    await Hive.openBox<Map>(_messagesBoxName);
    await Hive.openBox<dynamic>(_syncMetaBoxName);
    _initialized = true;
  }
  
  /// Recursively sanitize a value for Hive storage
  /// Converts Timestamps and other Firebase types to primitives
  static dynamic _sanitizeValue(dynamic value) {
    if (value == null) return null;
    
    // Handle Timestamp
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    
    // Handle Map
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitizeValue(v)));
    }
    
    // Handle List
    if (value is List) {
      return value.map((v) => _sanitizeValue(v)).toList();
    }
    
    // Primitives (String, int, double, bool) pass through
    return value;
  }
  
  /// Get cached messages for a match
  static List<Map<String, dynamic>> getCachedMessages(String matchId) {
    final box = Hive.box<Map>(_messagesBoxName);
    final key = 'match_$matchId';
    final cached = box.get(key);
    
    if (cached == null) return [];
    
    final messages = cached['messages'] as List<dynamic>? ?? [];
    return messages.map((m) => Map<String, dynamic>.from(m as Map)).toList();
  }
  
  /// Cache messages for a match
  static Future<void> cacheMessages(String matchId, List<Map<String, dynamic>> messages) async {
    try {
      final box = Hive.box<Map>(_messagesBoxName);
      final key = 'match_$matchId';
      
      // Sanitize all messages (convert Timestamps to ints, etc.)
      final cacheableMessages = messages.map((m) {
        return _sanitizeValue(m) as Map<String, dynamic>;
      }).toList();
      
      await box.put(key, {
        'messages': cacheableMessages,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silently fail caching - not critical
      print('MessageCacheService: Failed to cache messages: $e');
    }
  }
  
  /// Get last sync time for a match
  static DateTime? getLastSyncTime(String matchId) {
    final box = Hive.box<dynamic>(_syncMetaBoxName);
    final key = 'last_sync_$matchId';
    final timestamp = box.get(key) as int?;
    
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  /// Update last sync time for a match
  static Future<void> updateSyncTime(String matchId) async {
    final box = Hive.box<dynamic>(_syncMetaBoxName);
    final key = 'last_sync_$matchId';
    await box.put(key, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Clear all cached messages for a match
  static Future<void> clearMatchCache(String matchId) async {
    final messagesBox = Hive.box<Map>(_messagesBoxName);
    final syncBox = Hive.box<dynamic>(_syncMetaBoxName);
    
    await messagesBox.delete('match_$matchId');
    await syncBox.delete('last_sync_$matchId');
  }
  
  /// Clear all caches
  static Future<void> clearAll() async {
    final messagesBox = Hive.box<Map>(_messagesBoxName);
    final syncBox = Hive.box<dynamic>(_syncMetaBoxName);
    
    await messagesBox.clear();
    await syncBox.clear();
  }
}
