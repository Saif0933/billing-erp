import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_api_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_api_service.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationApiService _apiService;
  final Ref _ref;

  NotificationsNotifier(this._apiService, this._ref)
      : super(const NotificationsState(isLoading: true)) {
    loadNotifications();
    _listenToForegroundFcm();
    _syncFcmTokenWithBackend();
  }

  /// Listen to real-time FCM foreground messages
  void _listenToForegroundFcm() {
    try {
      final fcmService = _ref.read(firebaseApiServiceProvider);
      fcmService.onMessage.listen((remoteMessage) {
        debugPrint('[NotificationsNotifier] Incoming FCM message: ${remoteMessage.notification?.title}');
        final title = remoteMessage.notification?.title ?? 'Notification';
        final body = remoteMessage.notification?.body ?? '';
        final type = remoteMessage.data['type'] ?? 'SYSTEM_ALERT';

        final newNotif = NotificationModel(
          id: remoteMessage.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: body,
          timestamp: DateTime.now(),
          isRead: false,
          type: type,
        );

        state = state.copyWith(
          notifications: [newNotif, ...state.notifications],
          unreadCount: state.unreadCount + 1,
        );
      });
    } catch (e) {
      debugPrint('[NotificationsNotifier] Foreground listener notice: $e');
    }
  }

  /// Synchronize FCM device token with backend
  Future<void> _syncFcmTokenWithBackend() async {
    try {
      final fcmService = _ref.read(firebaseApiServiceProvider);
      final token = await fcmService.getFcmToken();
      if (token != null && token.isNotEmpty) {
        await _apiService.registerDeviceToken(fcmToken: token);
      }
    } catch (e) {
      debugPrint('[NotificationsNotifier] Token sync notice: $e');
    }
  }

  /// Load real notifications from backend
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _apiService.getNotifications(limit: 50);
      final unread = items.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: items,
        unreadCount: unread,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[NotificationsNotifier] Error loading notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    // Optimistically update local state
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );

    await _apiService.markAsRead(id);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: 0,
    );

    await _apiService.markAllAsRead();
  }

  /// Delete or dismiss notification locally
  void deleteNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }
}

/// Main Provider for Notifications State
final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiService = ref.watch(notificationApiServiceProvider);
  return NotificationsNotifier(apiService, ref);
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsNotifierProvider).unreadCount;
});
