import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM Background Message received: [${message.messageId}] ${message.notification?.title}');
}

/// Provider for FirebaseApiService
final firebaseApiServiceProvider = Provider<FirebaseApiService>((ref) {
  return FirebaseApiService();
});

/// Stream provider for foreground FCM messages
final foregroundFcmStreamProvider = StreamProvider<RemoteMessage>((ref) {
  final service = ref.watch(firebaseApiServiceProvider);
  return service.onMessage;
});

/// Future provider for retrieving the device FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(firebaseApiServiceProvider);
  return service.getFcmToken();
});

class FirebaseApiService {
  FirebaseMessaging? _messaging;
  bool _isInitialized = false;

  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  final StreamController<RemoteMessage> _messageOpenedAppController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of foreground messages
  Stream<RemoteMessage> get onMessage => _foregroundMessageController.stream;

  /// Stream of notifications that caused the app to open
  Stream<RemoteMessage> get onMessageOpenedApp => _messageOpenedAppController.stream;

  /// Stream of refreshed FCM tokens
  Stream<String> get onTokenRefresh {
    if (_messaging == null) return const Stream.empty();
    return _messaging!.onTokenRefresh;
  }

  /// Initialize Firebase Core and Firebase Messaging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core default app
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request permissions for iOS / Android 13+
      await requestPermission();

      // 4. Set presentation options for foreground notifications
      await _messaging?.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Setup foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}');
        _foregroundMessageController.add(message);
      });

      // 6. Setup interaction when app opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened app: ${message.data}');
        _messageOpenedAppController.add(message);
      });

      // 7. Check if app was opened from a terminated state notification
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App launched from terminated state via message: ${initialMessage.data}');
        _messageOpenedAppController.add(initialMessage);
      }

      // 8. Fetch initial FCM device token
      final token = await getFcmToken();
      if (token != null) {
        debugPrint('FCM Registration Token: $token');
      }

      _isInitialized = true;
    } catch (e, st) {
      debugPrint('FirebaseApiService initialization notice: $e');
      if (kDebugMode) {
        debugPrint(st.toString());
      }
    }
  }

  /// Request notification permissions (required for iOS and Android 13+)
  Future<NotificationSettings?> requestPermission() async {
    if (_messaging == null) return null;
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('User granted notification permission: ${settings.authorizationStatus}');
      return settings;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return null;
    }
  }

  /// Get active FCM registration token for push notifications
  Future<String?> getFcmToken() async {
    if (_messaging == null) return null;
    try {
      final token = await _messaging!.getToken();
      return token;
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
      return null;
    }
  }

  /// Subscribe device to a notification topic (e.g. 'billing_updates', 'offers')
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe device from a notification topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Delete current FCM token (e.g., on user logout)
  Future<void> deleteToken() async {
    if (_messaging == null) return;
    try {
      await _messaging!.deleteToken();
      debugPrint('FCM Token deleted successfully');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _foregroundMessageController.close();
    _messageOpenedAppController.close();
  }
}
