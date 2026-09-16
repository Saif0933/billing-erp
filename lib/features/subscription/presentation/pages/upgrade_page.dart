import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../data/models/subscription_dto.dart';
import '../providers/subscription_provider.dart';

class UpgradePage extends ConsumerStatefulWidget {
  const UpgradePage({super.key});

  @override
  ConsumerState<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends ConsumerState<UpgradePage> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Load fresh plans and current subscription when entering the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(availablePlansProvider.notifier).fetchPlans();
      ref.read(subscriptionProvider.notifier).loadSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(availablePlansProvider);
    final activeSub = ref.watch(subscriptionProvider);
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

    final isYearly = plansState.billingCycle == 'YEARLY';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1060
              ? 3
              : width >= 700
              ? 2
              : 1;

          return SingleChildScrollView(
            padding: pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUpgradeHeader(
                      context: context,
                      isDark: isDark,
                      isMobile: isMobile,
                      onRefresh: () {
                        ref
                            .read(availablePlansProvider.notifier)
                            .fetchPlans();
                        ref
                            .read(subscriptionProvider.notifier)
                            .loadSubscription();
                      },
                    ),

                    // Billing Cycle Toggle (Monthly vs Yearly)
                    Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BillingCycleTab(
                                title: 'Monthly billing',
                                isSelected: !isYearly,
                                isDark: isDark,
                                onTap: () => ref
                                    .read(availablePlansProvider.notifier)
                                    .setBillingCycle('MONTHLY'),
                              ),
                              _BillingCycleTab(
                                title: 'Annual billing',
                                badge: 'Save ~17%',
                                isSelected: isYearly,
                                isDark: isDark,
                                onTap: () => ref
                                    .read(availablePlansProvider.notifier)
                                    .setBillingCycle('YEARLY'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Loading / Error / Plans content
                    if (plansState.isLoading && plansState.plans.isEmpty) ...[
                      const SizedBox(height: 80),
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                      Text(
                        'Loading available plans...',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                      const SizedBox(height: 80),
                    ] else if (plansState.error != null &&
                        plansState.plans.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: AppRadius.mdBorder,
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Unable to load subscription plans',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              plansState.error ?? 'Unknown error occurred',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textDarkMuted
                                    : AppColors.textLightMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppButton(
                              label: 'Retry',
                              icon: Icons.refresh,
                              onPressed: () => ref
                                  .read(availablePlansProvider.notifier)
                                  .fetchPlans(),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      LayoutBuilder(
                        builder: (context, inner) {
                          final itemWidth =
                              ((inner.maxWidth -
                                          AppSpacing.lg * (columns - 1)) /
                                      columns)
                                  .floorToDouble();

                          final plans = plansState.plans;

                          return Wrap(
                            spacing: AppSpacing.lg,
                            runSpacing: AppSpacing.lg,
                            children: plans.map((plan) {
                              final isCurrent =
                                  (activeSub.planId != null &&
                                      activeSub.planId == plan.id) ||
                                  activeSub.displayName.toLowerCase() ==
                                      plan.name.toLowerCase();

                              return SizedBox(
                                width: itemWidth,
                                child: _DynamicPlanCard(
                                  plan: plan,
                                  isYearly: isYearly,
                                  isCurrent: isCurrent,
                                  isDark: isDark,
                                  isProcessing: _isProcessing,
                                  onSelect: isCurrent
                                      ? null
                                      : () => _confirmAndSubscribe(plan),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'All plans include automatic database backups, multi-user role permissions, and full GST compliance. Taxes extra as applicable.',
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

  Future<void> _confirmAndSubscribe(SubscriptionPlanDto plan) async {
    final plansState = ref.read(availablePlansProvider);
    final cycle = plansState.billingCycle;
    final isYearly = cycle == 'YEARLY';
    final price = isYearly ? plan.priceYearly : plan.priceMonthly;
    final formattedPrice = '₹${NumberFormat('#,##0').format(price)}';
    final periodText = isYearly ? '/year' : '/month';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Confirm Plan Purchase',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are upgrading your organization to:',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${plan.name} Tier',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (plan.tagline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    plan.tagline,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Billing Cycle',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            isYearly ? 'Annual' : 'Monthly',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seats / Users',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            'Up to ${plan.maxUsers} Users',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Invoices',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            '${NumberFormat('#,##0').format(plan.maxInvoicesPerMonth)} /mo',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$formattedPrice$periodText',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Immediate activation. Your subscription will renew automatically at the end of the billing cycle.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Confirm & Activate',
              icon: Icons.check_circle_outline,
              type: AppButtonType.primary,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        await ref
            .read(subscriptionProvider.notifier)
            .purchasePlan(planId: plan.id, billingCycle: cycle);

        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: '🎉 Successfully subscribed to ${plan.name} plan!',
          );
          context.go('/subscription');
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: 'Failed to purchase plan: $e',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Widget _buildUpgradeHeader({
    required BuildContext context,
    required bool isDark,
    required bool isMobile,
    required VoidCallback onRefresh,
  }) {
    final primaryTextColor =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.textDarkMuted : AppColors.textLightMuted;
    final borderColor =
        isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBreadcrumbItem('Dashboard', false, isDark),
                _buildBreadcrumbSeparator(isDark),
                _buildBreadcrumbItem('Settings', false, isDark),
                _buildBreadcrumbSeparator(isDark),
                _buildBreadcrumbItem('Subscription', false, isDark),
                _buildBreadcrumbSeparator(isDark),
                _buildBreadcrumbItem('Upgrade', true, isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/subscription');
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle Block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a plan',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select the business tier that matches your transaction volume, users, and ERP features.',
                      style: TextStyle(
                        fontSize: isMobile ? 12.5 : 13.5,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Refresh Button
              Tooltip(
                message: 'Refresh Plans',
                child: InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String title, bool isLast, bool isDark) {
    if (isLast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF10B981),
          ),
        ),
      );
    }
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
      ),
    );
  }

  Widget _buildBreadcrumbSeparator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 14,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
    );
  }
}

class _BillingCycleTab extends StatelessWidget {
  final String title;
  final String? badge;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BillingCycleTab({
    required this.title,
    this.badge,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF10B981) : const Color(0xFF0F172A))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DynamicPlanCard extends StatelessWidget {
  final SubscriptionPlanDto plan;
  final bool isYearly;
  final bool isCurrent;
  final bool isDark;
  final bool isProcessing;
  final VoidCallback? onSelect;

  const _DynamicPlanCard({
    required this.plan,
    required this.isYearly,
    required this.isCurrent,
    required this.isDark,
    required this.isProcessing,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = plan.isPopular && !isCurrent;
    final price = isYearly ? plan.priceYearly : plan.priceMonthly;
    final formattedPrice = '₹${NumberFormat('#,##0').format(price)}';
    final periodText = isYearly ? '/year' : '/month';

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor =
        isDark ? AppColors.textDarkMuted : AppColors.textLightMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF10B981)
              : highlighted
                  ? const Color(0xFF10B981).withValues(alpha: 0.8)
                  : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          width: isCurrent || highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent || highlighted
                ? const Color(0xFF10B981)
                    .withValues(alpha: isDark ? 0.18 : 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: highlighted ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.isPopular || isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                gradient: isCurrent
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.2),
                          const Color(0xFF059669).withValues(alpha: 0.12),
                        ],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCurrent
                        ? Icons.check_circle_rounded
                        : Icons.star_rounded,
                    size: 15,
                    color: isCurrent ? const Color(0xFF10B981) : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCurrent ? 'Current active plan' : 'Most Popular Choice',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isCurrent ? const Color(0xFF10B981) : Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isCurrent
                              ? const Color(0xFF10B981)
                              : primaryTextColor,
                        ),
                      ),
                    ),
                    if (isYearly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Billed Yearly',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formattedPrice,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      periodText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
                if (plan.tagline.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    plan.tagline,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Button CTA
                if (isCurrent)
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color:
                              isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active Plan',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: isProcessing ? null : onSelect,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isProcessing) ...[
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Select ${plan.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),
                Divider(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Key limits
                _PlanLimitRow(
                  icon: Icons.people_outline_rounded,
                  text: 'Up to ${plan.maxUsers} Team Members',
                  isDark: isDark,
                ),
                _PlanLimitRow(
                  icon: Icons.receipt_long_outlined,
                  text:
                      '${NumberFormat('#,##0').format(plan.maxInvoicesPerMonth)} Invoices / Month',
                  isDark: isDark,
                ),
                _PlanLimitRow(
                  icon: Icons.cloud_done_outlined,
                  text:
                      '${plan.storageLimitGb.toStringAsFixed(0)} GB Cloud Storage',
                  isDark: isDark,
                ),

                const SizedBox(height: AppSpacing.xs),
                Divider(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Included Features
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: primaryTextColor,
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

class _PlanLimitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _PlanLimitRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
