import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/subscription_models.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Subscriptions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: 'Subscription Status',
                  description: 'Manage your SaaS billing details and feature licenses.',
                  breadcrumbs: const ['Dashboard', 'Settings', 'Subscription'],
                ),
                
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.plan.displayName.toUpperCase(),
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark ? AppColors.accent : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: sub.status == SubscriptionStatus.active || sub.status == SubscriptionStatus.trial
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sub.status.name.toUpperCase(),
                                      style: TextStyle(
                                        color: sub.status == SubscriptionStatus.active || sub.status == SubscriptionStatus.trial
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          AppButton(
                            label: 'Change Plan',
                            onPressed: () => context.push('/upgrade'),
                            type: AppButtonType.primary,
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.xl),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Start Date',
                              dateFormat.format(sub.startDate),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              'Expiry / Renewal Date',
                              dateFormat.format(sub.endDate),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      if (sub.status == SubscriptionStatus.trial) ...[
                        Text(
                          'Your trial expires in ${sub.endDate.difference(DateTime.now()).inDays} days. Upgrade to avoid access interruption.',
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Enabled Modules',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sub.allowedFeatures.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final feature = sub.allowedFeatures.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(Icons.check, color: AppColors.success, size: 18),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              feature.name.toUpperCase(),
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Simulated Sandbox Testing Controls',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    AppButton(
                      label: 'Expire License',
                      onPressed: () => ref.read(subscriptionProvider.notifier).simulateExpiry(),
                      type: AppButtonType.danger,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      label: 'Reset to Trial',
                      onPressed: () => ref.read(subscriptionProvider.notifier).resetToTrial(),
                      type: AppButtonType.secondary,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
