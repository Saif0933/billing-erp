import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
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
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final pagePadding = EdgeInsets.all(
      isMobile
          ? AppSpacing.pagePaddingMobile
          : isTablet
              ? AppSpacing.pagePaddingTablet
              : AppSpacing.pagePaddingDesktop,
    );

    final plans = const [
      _PlanDetails(
        type: PlanType.basic,
        price: '₹4,999',
        period: '/year',
        description: 'Ideal for small retail and services businesses.',
        highlight: false,
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
        highlight: true,
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
        price: 'Custom',
        period: ' quote',
        description: 'Tailored manufacturing, ERP and banking configurations.',
        highlight: false,
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
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1020
              ? 3
              : width >= 680
                  ? 2
                  : 1;

          return SingleChildScrollView(
            padding: pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPageHeader(
                      leading: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        visualDensity: VisualDensity.compact,
                        alignment: Alignment.centerLeft,
                        icon: Icon(
                          Icons.arrow_back,
                          size: 22,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        tooltip: 'Back',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/dashboard');
                          }
                        },
                      ),
                      title: 'Choose a plan',
                      description:
                          'Select the business tier that matches your transaction volume and inventory depth.',
                      breadcrumbs: const [
                        'Dashboard',
                        'Settings',
                        'Subscription',
                        'Upgrade',
                      ],
                    ),
                    LayoutBuilder(
                      builder: (context, inner) {
                        final itemWidth =
                            ((inner.maxWidth - AppSpacing.lg * (columns - 1)) /
                                    columns)
                                .floorToDouble();
                        return Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: plans.map((plan) {
                            final isCurrent = activePlan == plan.type;
                            return SizedBox(
                              width: itemWidth,
                              child: _PlanCard(
                                plan: plan,
                                isCurrent: isCurrent,
                                isDark: isDark,
                                onSelect: isCurrent
                                    ? null
                                    : () => _selectPlan(context, ref, plan),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'All paid plans include onboarding support and secure cloud backups. Taxes extra as applicable.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textLightMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectPlan(
    BuildContext context,
    WidgetRef ref,
    _PlanDetails plan,
  ) async {
    final confirm = await AppFeedback.showConfirmationDialog(
      context,
      title: 'Change Subscription',
      content:
          'Are you sure you want to change your license plan to ${plan.type.displayName}?',
    );
    if (confirm == true) {
      await ref.read(subscriptionProvider.notifier).upgradeTo(plan.type);
      if (context.mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Plan changed to ${plan.type.displayName} successfully!',
        );
        context.go('/dashboard');
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanDetails plan;
  final bool isCurrent;
  final bool isDark;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accent : AppColors.primary;
    final highlighted = plan.highlight && !isCurrent;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent || highlighted
              ? (isDark ? AppColors.accent : AppColors.primary)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isCurrent || highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: highlighted ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.highlight || isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.success.withValues(alpha: 0.14)
                    : accent.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                isCurrent ? 'Current plan' : 'Most popular',
                textAlign: TextAlign.center,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? AppColors.success : accent,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.type.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCurrent ? accent : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary,
                      ),
                    ),
                    if (plan.period.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          plan.period,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textDarkMuted
                                : AppColors.textLightMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  plan.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: isCurrent ? 'Active Plan' : 'Select Plan',
                  icon: isCurrent ? Icons.check : Icons.arrow_forward,
                  width: double.infinity,
                  onPressed: onSelect,
                  type: isCurrent
                      ? AppButtonType.secondary
                      : AppButtonType.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(
                  color: isDark ? AppColors.borderDark : AppColors.dividerLight,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTypography.bodySmall.copyWith(
                              height: 1.35,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDetails {
  final PlanType type;
  final String price;
  final String period;
  final String description;
  final bool highlight;
  final List<String> features;

  const _PlanDetails({
    required this.type,
    required this.price,
    required this.period,
    required this.description,
    required this.highlight,
    required this.features,
  });
}
