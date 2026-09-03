import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/platform_admin_provider.dart';
import '../widgets/platform_plan_card.dart';

class PlatformAdminSubscriptionPage extends ConsumerWidget {
  const PlatformAdminSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(platformAdminProvider);
    final notifier = ref.read(platformAdminProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;

              final titleSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SaaS Subscription & Pricing Tiers',
                    style: TextStyle(
                      fontSize: isSmall ? 18 : 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure recurring subscription tiers, billing cycles, quotas, and feature entitlements.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              );

              final createTierButton = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                label: const Text('Add Plan Tier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: () {
                  AppFeedback.showSnackbar(context, message: 'Tier configuration modal will open.');
                },
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 12),
                    createTierButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleSection,
                  createTierButton,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Plan Revenue Breakdown Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECURRING REVENUE BY SUBSCRIPTION TIER',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 600;

                    final starterBlock = _buildTierRevenueBlock('Starter Tier', '42 Tenants', '₹ 41,958 / mo', const Color(0xFF2563EB), isDark);
                    final growthBlock = _buildTierRevenueBlock('Growth Tier', '68 Tenants', '₹ 1,69,932 / mo', const Color(0xFF15803D), isDark);
                    final enterpriseBlock = _buildTierRevenueBlock('Enterprise Tier', '38 Tenants', '₹ 2,65,962 / mo', const Color(0xFF6D28D9), isDark);

                    if (isSmall) {
                      return Column(
                        children: [
                          starterBlock,
                          const SizedBox(height: 10),
                          growthBlock,
                          const SizedBox(height: 10),
                          enterpriseBlock,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: starterBlock),
                        const SizedBox(width: 12),
                        Expanded(child: growthBlock),
                        const SizedBox(width: 12),
                        Expanded(child: enterpriseBlock),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Plan Tier Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width < 900) {
                return Column(
                  children: state.plans.map((plan) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlatformPlanCard(
                        plan: plan,
                        onEdit: () {
                          AppFeedback.showSnackbar(context, message: 'Editing ${plan.name} Tier...');
                        },
                        onViewSubscribers: () {
                          notifier.setPlanFilter(plan.name);
                          notifier.setNavTab('organizations');
                        },
                      ),
                    );
                  }).toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: state.plans.map((plan) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: PlatformPlanCard(
                        plan: plan,
                        onEdit: () {
                          AppFeedback.showSnackbar(context, message: 'Editing ${plan.name} Tier...');
                        },
                        onViewSubscribers: () {
                          notifier.setPlanFilter(plan.name);
                          notifier.setNavTab('organizations');
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTierRevenueBlock(
    String title,
    String tenants,
    String mrr,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                tenants,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mrr,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
