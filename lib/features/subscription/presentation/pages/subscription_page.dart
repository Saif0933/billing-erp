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
import '../../../../shared/widgets/app_cards.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/subscription_models.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();
    final daysLeft = sub.endDate.difference(now).inDays;
    final totalDays = sub.endDate.difference(sub.startDate).inDays;
    final progress = totalDays <= 0
        ? 0.0
        : (1 - (daysLeft / totalDays)).clamp(0.0, 1.0);
    final statusColor = _statusColor(sub.status);
    final pagePadding = EdgeInsets.all(
      isMobile
          ? AppSpacing.pagePaddingMobile
          : isTablet
              ? AppSpacing.pagePaddingTablet
              : AppSpacing.pagePaddingDesktop,
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth;
          final metricColumns = contentWidth >= 1100
              ? 4
              : contentWidth >= 700
                  ? 2
                  : 1;
          final featureColumns = contentWidth >= 1100
              ? 3
              : contentWidth >= 700
                  ? 2
                  : 1;

          return SingleChildScrollView(
            padding: pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
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
                      title: 'Billing & Subscription',
                      description:
                          'Review your current license, renewal dates, and included modules.',
                      breadcrumbs: const [
                        'Dashboard',
                        'Settings',
                        'Subscription',
                      ],
                      actions: isMobile
                          ? const []
                          : [
                              AppButton(
                                label: 'Change Plan',
                                icon: Icons.upgrade_outlined,
                                onPressed: () =>
                                    context.push('/upgrade'),
                                type: AppButtonType.primary,
                              ),
                            ],
                    ),
                    _PlanHeroCard(
                      sub: sub,
                      isDark: isDark,
                      isMobile: isMobile,
                      daysLeft: daysLeft,
                      progress: progress,
                      statusColor: statusColor,
                      onChangePlan: () => context.push('/upgrade'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _MetricGrid(
                      columns: metricColumns,
                      spacing: AppSpacing.md,
                      children: [
                        _MetricTile(
                          isDark: isDark,
                          icon: Icons.event_available_outlined,
                          label: 'Start date',
                          value: dateFormat.format(sub.startDate),
                        ),
                        _MetricTile(
                          isDark: isDark,
                          icon: Icons.autorenew,
                          label: daysLeft < 0
                              ? 'Expired on'
                              : 'Renewal / expiry',
                          value: dateFormat.format(sub.endDate),
                        ),
                        _MetricTile(
                          isDark: isDark,
                          icon: Icons.timelapse_outlined,
                          label: 'Days remaining',
                          value: daysLeft < 0 ? 'Expired' : '$daysLeft days',
                          accent: daysLeft <= 7 ? AppColors.warning : null,
                        ),
                        _MetricTile(
                          isDark: isDark,
                          icon: Icons.extension_outlined,
                          label: 'Modules included',
                          value: '${sub.allowedFeatures.length}',
                          subtitle:
                              'of ${SubscriptionFeature.values.length} available',
                        ),
                      ],
                    ),
                    if (sub.status == SubscriptionStatus.trial ||
                        sub.status == SubscriptionStatus.expired ||
                        sub.status == SubscriptionStatus.pastDue) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _StatusBanner(sub: sub, daysLeft: daysLeft, isDark: isDark),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'License modules',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Features included in ${sub.plan.displayName}. Locked items require a higher plan.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FeatureGrid(
                      columns: featureColumns,
                      spacing: AppSpacing.sm,
                      subscription: sub,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SandboxCard(
                      isDark: isDark,
                      isMobile: isMobile,
                      onExpire: () =>
                          ref.read(subscriptionProvider.notifier).simulateExpiry(),
                      onReset: () =>
                          ref.read(subscriptionProvider.notifier).resetToTrial(),
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

  Color _statusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.trial:
        return AppColors.info;
      case SubscriptionStatus.pastDue:
        return AppColors.warning;
      case SubscriptionStatus.expired:
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.suspended:
        return AppColors.error;
    }
  }
}

class _PlanHeroCard extends StatelessWidget {
  final SubscriptionModel sub;
  final bool isDark;
  final bool isMobile;
  final int daysLeft;
  final double progress;
  final Color statusColor;
  final VoidCallback onChangePlan;

  const _PlanHeroCard({
    required this.sub,
    required this.isDark,
    required this.isMobile,
    required this.daysLeft,
    required this.progress,
    required this.statusColor,
    required this.onChangePlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F382B), Color(0xFF0A261D)]
              : const [Color(0xFFE8FAF3), Color(0xFFC7F4E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
            : Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -28,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.35),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.7),
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Icon(
                          _planIcon(sub.plan),
                          color: isDark
                              ? AppColors.accentLight
                              : AppColors.accentDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT PLAN',
                              style: AppTypography.labelSmall.copyWith(
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.accentLight
                                    : AppColors.accentDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub.plan.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textDarkPrimary
                                    : AppColors.textLightPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: AppRadius.roundBorder,
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          sub.status.displayName.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    daysLeft < 0
                        ? 'This license has expired. Upgrade to restore module access.'
                        : sub.status == SubscriptionStatus.trial
                            ? 'You are on a trial license. Upgrade before expiry to keep full access.'
                            : 'Your workspace is licensed and ready. Change plans any time from billing.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: AppRadius.roundBorder,
                    child: LinearProgressIndicator(
                      value: progress.isNaN ? 0 : progress,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.65),
                      color: daysLeft <= 7 ? AppColors.warning : AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    daysLeft < 0
                        ? 'License period ended'
                        : '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% of billing period used',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textLightMuted,
                    ),
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Change Plan',
                      icon: Icons.upgrade_outlined,
                      width: double.infinity,
                      onPressed: onChangePlan,
                      type: AppButtonType.primary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _planIcon(PlanType plan) {
    switch (plan) {
      case PlanType.trial:
        return Icons.hourglass_top_outlined;
      case PlanType.basic:
        return Icons.storefront_outlined;
      case PlanType.premium:
        return Icons.workspace_premium_outlined;
      case PlanType.enterprise:
        return Icons.apartment_outlined;
    }
  }
}

class _MetricGrid extends StatelessWidget {
  final int columns;
  final double spacing;
  final List<Widget> children;

  const _MetricGrid({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .floorToDouble();
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? accent;

  const _MetricTile({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = accent ??
        (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (accent ?? AppColors.accent).withValues(alpha: 0.12),
              borderRadius: AppRadius.smBorder,
            ),
            child: Icon(icon, size: 20, color: accent ?? AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textLightMuted,
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

class _StatusBanner extends StatelessWidget {
  final SubscriptionModel sub;
  final int daysLeft;
  final bool isDark;

  const _StatusBanner({
    required this.sub,
    required this.daysLeft,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = sub.status == SubscriptionStatus.expired;
    final color = isExpired ? AppColors.error : AppColors.warning;
    final message = isExpired
        ? 'Your license has expired. Upgrade now to restore billing, reports, and operational modules.'
        : sub.status == SubscriptionStatus.pastDue
            ? 'Payment is past due. Update your plan to avoid interruption.'
            : 'Your trial expires in ${daysLeft < 0 ? 0 : daysLeft} days. Upgrade to avoid access interruption.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isExpired ? Icons.error_outline : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final int columns;
  final double spacing;
  final SubscriptionModel subscription;
  final bool isDark;

  const _FeatureGrid({
    required this.columns,
    required this.spacing,
    required this.subscription,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final features = SubscriptionFeature.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .floorToDouble();
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: features.map((feature) {
            final enabled = subscription.canAccess(feature);
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(
                    color: enabled
                        ? AppColors.success.withValues(alpha: 0.28)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      enabled
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      size: 18,
                      color: enabled
                          ? AppColors.success
                          : (isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textLightMuted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        feature.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? (isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary)
                              : (isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textLightMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SandboxCard extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  final VoidCallback onExpire;
  final VoidCallback onReset;

  const _SandboxCard({
    required this.isDark,
    required this.isMobile,
    required this.onExpire,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final expireButton = AppButton(
      label: 'Expire License',
      icon: Icons.timer_off_outlined,
      onPressed: onExpire,
      type: AppButtonType.danger,
      width: isMobile ? double.infinity : null,
    );
    final resetButton = AppButton(
      label: 'Reset to Trial',
      icon: Icons.restart_alt,
      onPressed: onReset,
      type: AppButtonType.secondary,
      width: isMobile ? double.infinity : null,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sandbox testing controls',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Use these actions only in demo environments to preview expired and trial states.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                expireButton,
                const SizedBox(height: AppSpacing.sm),
                resetButton,
              ],
            )
          else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [expireButton, resetButton],
            ),
        ],
      ),
    );
  }
}
