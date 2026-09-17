import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/notification_model.dart';

/// Provider for NotificationApiService
final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationApiService(apiClient);
});

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService(this._apiClient);

  /// 1. Fetch paginated notifications for current business
  Future<List<NotificationModel>> getNotifications({
    bool? isRead,
    String? type,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (isRead != null) {
        query['isRead'] = isRead.toString();
      }
      if (type != null && type.trim().isNotEmpty) {
        query['type'] = type.trim();
      }

      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: query,
      );

      final data = response.data;
      List<dynamic> rawItems = [];

      if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data;
        if (payload is Map<String, dynamic> && payload['items'] is List) {
          rawItems = payload['items'] as List<dynamic>;
        } else if (payload is List) {
          rawItems = payload;
        } else if (data['items'] is List) {
          rawItems = data['items'] as List<dynamic>;
        }
      } else if (data is List) {
        rawItems = data;
      }

      return rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('[NotificationApiService] Error fetching notifications: $e');
      rethrow;
    }
  }

  /// 2. Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data;
        if (payload is Map<String, dynamic> && payload['unreadCount'] != null) {
          return int.tryParse(payload['unreadCount'].toString()) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('[NotificationApiService] Error fetching unread count: $e');
      return 0;
    }
  }

  /// 3. Mark single notification as read
  Future<bool> markAsRead(String id) async {
    try {
      await _apiClient.patch(ApiEndpoints.notificationMarkRead(id));
      return true;
    } catch (e) {
      debugPrint('[NotificationApiService] Error marking notification as read: $e');
      return false;
    }
  }

  /// 4. Mark all notifications for business as read
  Future<bool> markAllAsRead() async {
    try {
      await _apiClient.patch(ApiEndpoints.notificationsMarkAllRead);
      return true;
    } catch (e) {
      debugPrint('[NotificationApiService] Error marking all notifications as read: $e');
      return false;
    }
  }

  /// 5. Register device FCM token in the backend database
  Future<bool> registerDeviceToken({
    required String fcmToken,
    String deviceType = 'android',
    String? userId,
    String? businessId,
  }) async {
    if (fcmToken.trim().isEmpty) return false;

    try {
      final payload = <String, dynamic>{
        'token': fcmToken.trim(),
        'deviceType': deviceType,
      };
      if (userId != null && userId.isNotEmpty) {
        payload['userId'] = userId;
      }
      if (businessId != null && businessId.isNotEmpty) {
        payload['businessId'] = businessId;
      }

      final response = await _apiClient.post(
        ApiEndpoints.notificationsToken,
        data: payload,
      );
      debugPrint('[NotificationApiService] FCM token registered on backend: ${response.statusCode}');
      return true;
    } catch (e) {
      debugPrint('[NotificationApiService] Notice registering FCM token on backend: $e');
      return false;
    }
  }

  /// Deactivate device FCM token on logout
  Future<bool> deactivateDeviceToken({
    required String fcmToken,
  }) async {
    if (fcmToken.trim().isEmpty) return false;

    try {
      final response = await _apiClient.delete(
        ApiEndpoints.notificationsToken,
        data: {'token': fcmToken.trim()},
      );
      debugPrint('[NotificationApiService] FCM token deactivated on backend: ${response.statusCode}');
      return true;
    } catch (e) {
      debugPrint('[NotificationApiService] Notice deactivating FCM token on backend: $e');
      return false;
    }
  }

  /// 6. Send test push notification
  Future<Map<String, dynamic>?> sendTestNotification({
    required String title,
    required String message,
    String type = 'SYSTEM_ALERT',
    String? token,
  }) async {
    try {
      final payload = <String, dynamic>{
        'title': title,
        'message': message,
        'type': type,
      };
      if (token != null && token.isNotEmpty) {
        payload['token'] = token;
      }

      final response = await _apiClient.post(
        ApiEndpoints.notificationsTestSend,
        data: payload,
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[NotificationApiService] Error sending test notification: $e');
      rethrow;
    }
  }
}
