import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiService = ref.watch(notificationApiServiceProvider);
  return NotificationRepository(apiService);
});

class NotificationRepository {
  final NotificationApiService _apiService;

  NotificationRepository(this._apiService);

  Future<List<NotificationModel>> getNotifications({
    bool? isRead,
    String? type,
    int page = 1,
    int limit = 50,
  }) {
    return _apiService.getNotifications(
      isRead: isRead,
      type: type,
      page: page,
      limit: limit,
    );
  }

  Future<int> getUnreadCount() => _apiService.getUnreadCount();

  Future<bool> markAsRead(String id) => _apiService.markAsRead(id);

  Future<bool> markAllAsRead() => _apiService.markAllAsRead();

  Future<bool> registerDeviceToken({
    required String fcmToken,
    String deviceType = 'android',
  }) {
    return _apiService.registerDeviceToken(
      fcmToken: fcmToken,
      deviceType: deviceType,
    );
  }
}
