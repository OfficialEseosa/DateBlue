import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

/// Service for handling push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _currentUserId;
  bool _isInitialized = false;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  VoidCallback? onNotificationTap;
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }
  
  /// Request notification permissions (call after onboarding)
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }
  
  /// Initialize notifications and save FCM token (call in home page)
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;
    
    _currentUserId = userId;
    
    try {
      // Check if already authorized
      final settings = await _messaging.getNotificationSettings();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _setupMessaging(userId);
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }
  
  Future<void> _setupMessaging(String userId) async {
    // Cancel any existing subscriptions before setting up new ones
    await _cancelSubscriptions();
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFcmToken(userId, token);
      debugPrint('FCM Token saved: ${token.substring(0, 20)}...');
    }
    
    // Listen for token refresh (store subscription)
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _saveFcmToken(userId, newToken);
    });
    
    // Handle foreground messages (store subscription)
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background/terminated message taps (store subscription)
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    
    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }
  
  Future<void> _cancelSubscriptions() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    await _messageOpenedSubscription?.cancel();
    _messageOpenedSubscription = null;
  }
  
  Future<void> _saveFcmToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'notificationsEnabled': true,
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
  
  /// Disable notifications and remove token
  Future<void> disableNotifications(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'notificationsEnabled': false,
      });
      debugPrint('Notifications disabled');
    } catch (e) {
      debugPrint('Error disabling notifications: $e');
    }
  }

  Future<void> cleanup() async {
    await _cancelSubscriptions();
    _currentUserId = null;
    _isInitialized = false;
    onNotificationTap = null;
    debugPrint('NotificationService cleaned up');
  }
  
  /// Re-enable notifications after user opts back in
  Future<bool> enableNotifications(String userId) async {
    final granted = await requestPermission();
    if (granted) {
      await _setupMessaging(userId);
      return true;
    }
    return false;
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Could show an in-app notification banner here
  }
  
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('Message tapped: ${message.data}');
    final type = message.data['type'];
    if (type == 'like_received') {
      // Navigate to likes page
      onNotificationTap?.call();
    }
  }
}
