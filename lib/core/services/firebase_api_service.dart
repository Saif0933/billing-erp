import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/navigation_keys.dart';
import '../../shared/widgets/in_app_notification_banner.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint(
    'FCM Background Message received: [${message.messageId}] ${message.notification?.title}',
  );
}

/// Android High Importance Notification Channel for Foreground Heads-Up Alerts
const AndroidNotificationChannel
highImportanceChannel = AndroidNotificationChannel(
  'taxbunny_high_importance_channel',
  'Tax Bunny Notifications',
  description:
      'High importance notifications for Tax Bunny ERP, Stock, and Subscriptions.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

/// Global instance of FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
  OverlayEntry? _currentBannerEntry;

  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  final StreamController<RemoteMessage> _messageOpenedAppController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of foreground messages
  Stream<RemoteMessage> get onMessage => _foregroundMessageController.stream;

  /// Stream of notifications that caused the app to open
  Stream<RemoteMessage> get onMessageOpenedApp =>
      _messageOpenedAppController.stream;

  /// Stream of refreshed FCM tokens
  Stream<String> get onTokenRefresh {
    if (_messaging == null) return const Stream.empty();
    return _messaging!.onTokenRefresh;
  }

  /// Initialize Firebase Core, Local Notifications, and Foreground Listeners
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

      // 4. Initialize Flutter Local Notifications for Android status bar foreground display
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Local notification tapped: ${response.payload}');
          _navigateToNotifications();
        },
      );

      // 5. Create Android High Importance Notification Channel
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(highImportanceChannel);

      // 6. Set presentation options for foreground notifications (iOS & Android)
      await _messaging?.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 7. Setup foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}',
        );
        _foregroundMessageController.add(message);

        final title =
            message.notification?.title ??
            message.data['title'] ??
            'New Notification';
        final body =
            message.notification?.body ??
            message.data['body'] ??
            message.data['message'] ??
            '';
        final type = message.data['type']?.toString();

        // A) Display in Android Status Bar Tray via FlutterLocalNotifications
        try {
          flutterLocalNotificationsPlugin.show(
            id: message.hashCode,
            title: title,
            body: body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                highImportanceChannel.id,
                highImportanceChannel.name,
                channelDescription: highImportanceChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                styleInformation: body.isNotEmpty
                    ? BigTextStyleInformation(body, contentTitle: title)
                    : null,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data['route'] ?? '/notifications',
          );
        } catch (localErr) {
          debugPrint('Error showing local notification: $localErr');
        }

        // B) Display In-App Floating Banner on active screen
        showInAppNotification(
          title: title,
          body: body,
          type: type,
          data: message.data,
          onTap: () {
            _navigateToNotifications();
          },
        );
      });

      // 8. Setup interaction when app opened from background notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened app: ${message.data}');
        _messageOpenedAppController.add(message);
        _navigateToNotifications();
      });

      // 9. Check if app was opened from a terminated state notification
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'FCM App launched from terminated state via message: ${initialMessage.data}',
        );
        _messageOpenedAppController.add(initialMessage);
      }

      // 10. Fetch initial FCM device token
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

  /// Display an animated in-app heads-up notification banner across any screen
  void showInAppNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    try {
      final overlayState = rootNavigatorKey.currentState?.overlay;
      if (overlayState == null) {
        _showScaffoldMessengerNotification(
          title: title,
          body: body,
          onTap: onTap,
        );
        return;
      }

      _currentBannerEntry?.remove();
      _currentBannerEntry = null;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => InAppNotificationBanner(
          title: title,
          body: body,
          type: type,
          duration: duration,
          onTap: () {
            entry.remove();
            _currentBannerEntry = null;
            if (onTap != null) {
              onTap();
            } else {
              _navigateToNotifications();
            }
          },
          onDismiss: () {
            if (_currentBannerEntry == entry) {
              entry.remove();
              _currentBannerEntry = null;
            }
          },
        ),
      );

      _currentBannerEntry = entry;
      overlayState.insert(entry);
    } catch (e) {
      debugPrint('[FirebaseApiService] Notice inserting in-app banner: $e');
      _showScaffoldMessengerNotification(
        title: title,
        body: body,
        onTap: onTap,
      );
    }
  }

  /// Fallback floating SnackBar notification
  void _showScaffoldMessengerNotification({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    try {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF1E293B),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: const Color(0xFF38BDF8),
            onPressed: () {
              if (onTap != null) {
                onTap();
              } else {
                _navigateToNotifications();
              }
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {}
  }

  /// Display a modal in-app dialog for critical alerts
  Future<void> showInAppModalNotification({
    required String title,
    required String message,
    String? type,
    String actionLabel = 'View Details',
    VoidCallback? onAction,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onAction != null) {
                  onAction();
                } else {
                  _navigateToNotifications();
                }
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  /// Helper to navigate directly to notifications screen
  void _navigateToNotifications() {
    try {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        GoRouter.of(context).push('/notifications');
      }
    } catch (e) {
      debugPrint('[FirebaseApiService] Navigation notice: $e');
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
      debugPrint(
        'User granted notification permission: ${settings.authorizationStatus}',
      );

      // Also request Android local notification permissions for Android 13+
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

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
    _currentBannerEntry?.remove();
    _currentBannerEntry = null;
    _foregroundMessageController.close();
    _messageOpenedAppController.close();
  }
}
