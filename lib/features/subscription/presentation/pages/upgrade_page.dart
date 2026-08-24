import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/subscription_models.dart';

class UpgradePage extends ConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlan = ref.watch(subscriptionProvider).plan;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final plans = [
      _PlanDetails(
        type: PlanType.basic,
        price: '₹4,999',
        period: '/year',
        description: 'Ideal for small retail and services businesses.',
        features: [
          'Billing & Invoicing',
          'Customer & Supplier directories',
          'Receipts & Payments tracking',
          'Email support',
        ],
      ),
      _PlanDetails(
        type: PlanType.premium,
        price: '₹9,999',
        period: '/year',
        description: 'Comprehensive workflow tool for growing agencies & stores.',
        features: [
          'Everything in Basic',
          'GST Filing & Auto GSTIN Check',
          'Full Double-Entry Ledger Book',
          'Inventory & Warehouse stock controls',
          'E-Invoicing & E-Way Bills generation',
          'API integrations',
          'Priority phone support',
        ],
      ),
      _PlanDetails(
        type: PlanType.enterprise,
        price: 'Custom Quote',
        period: '',
        description: 'Tailored manufacturing, ERP and banking configurations.',
        features: [
          'Everything in Premium',
          'Manufacturing & Bill of Materials',
          'Multi-warehouse synchronization',
          'Dedicated account manager',
          'Custom SLA guarantees',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: 'Select a Plan',
                  description: 'Choose the business tier matching your transaction size and inventory depth.',
                  breadcrumbs: const ['Dashboard', 'Settings', 'Subscription', 'Upgrade'],
                ),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isCurrent = activePlan == plan.type;
                    
                    return AppCard(
                      border: Border.all(
                        color: isCurrent
                            ? (isDark ? AppColors.accent : AppColors.primary)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isCurrent ? 2 : 1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            plan.type.displayName.toUpperCase(),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? (isDark ? AppColors.accent : AppColors.primary) : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                plan.price,
                                style: AppTypography.headlineMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                plan.period,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            plan.description,
                            style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: isCurrent ? 'Active Plan' : 'Select Plan',
                            onPressed: isCurrent
                                ? null
                                : () async {
                                    final confirm = await AppFeedback.showConfirmationDialog(
                                      context,
                                      title: 'Change Subscription',
                                      content: 'Are you sure you want to change your license plan to ${plan.type.displayName}?',
                                    );
                                    if (confirm == true) {
                                      await ref.read(subscriptionProvider.notifier).upgradeTo(plan.type);
                                      if (context.mounted) {
                                        AppFeedback.showSnackbar(context, message: 'Plan changed to ${plan.type.displayName} successfully!');
                                        context.go('/dashboard');
                                      }
                                    }
                                  },
                            type: isCurrent ? AppButtonType.secondary : AppButtonType.primary,
                          ),
                          const Divider(height: AppSpacing.lg),
                          Expanded(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: plan.features.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                              itemBuilder: (context, idx) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check, size: 14, color: AppColors.success),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        plan.features[idx],
                                        style: AppTypography.bodySmall,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanDetails {
  final PlanType type;
  final String price;
  final String period;
  final String description;
  final List<String> features;

  const _PlanDetails({
    required this.type,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
  });
}
