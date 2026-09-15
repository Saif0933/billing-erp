import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  IconData _getIconForType(NotificationModel item) {
    final type = item.type.toUpperCase();
    final title = item.title.toLowerCase();

    if (type == 'LOW_STOCK' || title.contains('low stock') || title.contains('out of stock')) {
      return Icons.warning_amber_rounded;
    }
    if (type == 'SUBSCRIPTION_EXPIRY' || title.contains('subscription') || title.contains('plan')) {
      return Icons.card_membership_rounded;
    }
    if (type == 'PAYMENT_RECEIVED' || title.contains('paid') || title.contains('receipt')) {
      return Icons.check_circle_outline_rounded;
    }
    if (type == 'INVOICE_GENERATED' || type == 'INVOICE_OVERDUE' || title.contains('invoice')) {
      return Icons.receipt_long_rounded;
    }
    if (title.contains('transfer') || item.referenceType == 'STOCK_TRANSFER') {
      return Icons.swap_horiz_rounded;
    }
    return Icons.notifications_active_outlined;
  }

  Color _getColorForType(NotificationModel item, bool isDark) {
    if (item.isRead) {
      return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    }

    final type = item.type.toUpperCase();
    final title = item.title.toLowerCase();

    if (type == 'LOW_STOCK' || title.contains('out of stock')) {
      return Colors.redAccent;
    }
    if (title.contains('low stock')) {
      return Colors.orangeAccent;
    }
    if (type == 'SUBSCRIPTION_EXPIRY' || title.contains('subscription')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    if (type == 'PAYMENT_RECEIVED' || title.contains('paid')) {
      return const Color(0xFF10B981); // Emerald Green
    }
    return isDark ? AppColors.accent : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final notifState = ref.watch(notificationsNotifierProvider);
    final notifications = notifState.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (notifState.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifState.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: () {
                ref.read(notificationsNotifierProvider.notifier).markAllAsRead();
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all as read'),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(notificationsNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsNotifierProvider.notifier).refresh(),
        child: notifState.isLoading && notifications.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      AppEmptyState(
                        title: 'All Caught Up!',
                        description: 'You have no new alerts or business notifications.',
                        icon: Icons.notifications_off_outlined,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      final iconColor = _getColorForType(item, isDark);

                      return InkWell(
                        onTap: () {
                          if (!item.isRead) {
                            ref.read(notificationsNotifierProvider.notifier).markAsRead(item.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AppCard(
                          backgroundColor: item.isRead
                              ? null
                              : (isDark
                                  ? AppColors.surfaceDark.withValues(alpha: 0.9)
                                  : Colors.white),
                          border: Border.all(
                            color: item.isRead
                                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                                : iconColor.withValues(alpha: 0.6),
                            width: item.isRead ? 1 : 1.8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconForType(item),
                                  color: iconColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: AppTypography.titleMedium.copyWith(
                                              fontWeight: item.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(left: 4),
                                            decoration: BoxDecoration(
                                              color: iconColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.textDarkSecondary
                                            : AppColors.textLightSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dateFormat.format(item.timestamp),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Dismiss',
                                onPressed: () {
                                  ref
                                      .read(notificationsNotifierProvider.notifier)
                                      .deleteNotification(item.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
