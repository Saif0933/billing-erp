import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../data/models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'not_01',
      title: 'Subscription Renewal Warning',
      description: 'Your trial plan expires in 2 days. Upgrade to Premium to avoid service limits.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationModel(
      id: 'not_02',
      title: 'Low Stock Alert',
      description: 'Product "Premium Tax Booklets" has fallen below the safety stock margin of 10 items.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: false,
    ),
    NotificationModel(
      id: 'not_03',
      title: 'Invoice Paid',
      description: 'Invoice INV-2026-0001 for ₹12,500.00 has been marked as PAID by Acme Corp.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        title: n.title,
        description: n.description,
        timestamp: n.timestamp,
        isRead: true,
      )).toList();
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const AppEmptyState(
              title: 'All Caught Up!',
              description: 'You have no new alerts or business updates.',
              icon: Icons.notifications_off_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = _notifications[index];
                
                return AppCard(
                  backgroundColor: item.isRead
                      ? null
                      : (isDark ? AppColors.surfaceDark.withOpacity(0.8) : Colors.white),
                  border: Border.all(
                    color: item.isRead
                        ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                        : (isDark ? AppColors.accent : AppColors.primary),
                    width: item.isRead ? 1 : 1.5,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.title.contains('Subscription')
                            ? Icons.card_membership
                            : item.title.contains('Low Stock')
                                ? Icons.warning_amber_outlined
                                : Icons.receipt_long,
                        color: item.isRead
                            ? Colors.grey
                            : (isDark ? AppColors.accent : AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateFormat.format(item.timestamp),
                              style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteNotification(item.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
