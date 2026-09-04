import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/responsive/responsive.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget content = child;
    if (title != null || (actions != null && actions!.isNotEmpty)) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                    ),
                  ),
                ),
              if (actions != null && actions!.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  children: actions!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: AppRadius.smBorder,
        border: border ?? Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: const [AppShadows.sm],
      ),
      child: content,
    );
  }
}

class AppMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? trendColor;
  final String? trendLabel;

  const AppMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trendColor,
    this.trendLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  icon,
                  color: iconColor ?? (isDark ? AppColors.accent : AppColors.primary),
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
          ),
          if (subtitle != null || trendLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (trendLabel != null) ...[
                  Text(
                    trendLabel!,
                    style: AppTypography.bodySmall.copyWith(
                      color: trendColor ?? AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> actions;
  final List<String> breadcrumbs;

  const AppPageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
    this.breadcrumbs = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: breadcrumbs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final val = entry.value;
                  final isLast = idx == breadcrumbs.length - 1;
                  return Row(
                    children: [
                      Text(
                        val,
                        style: AppTypography.bodySmall.copyWith(
                          color: isLast
                              ? (isDark ? AppColors.accent : AppColors.primary)
                              : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                          fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: Text(
                            '/',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Responsive.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.headlineMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            description!,
                            style: AppTypography.bodyMedium.copyWith(color: secondaryTextColor),
                          ),
                        ],
                      ],
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: actions,
                      ),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.headlineMedium.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              description!,
                              style: AppTypography.bodyMedium.copyWith(color: secondaryTextColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: actions,
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}
