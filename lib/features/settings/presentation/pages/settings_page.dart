import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryText =
        isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final mutedText =
        isDark ? AppColors.textDarkMuted : AppColors.textLightMuted;
    final dividerColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final iconColor = isDark ? AppColors.accentLight : AppColors.accentDark;

    final settingsGroups = [
      _SettingsGroup(
        title: 'Account',
        items: [
          _SettingsItem(
            title: 'User Profile',
            subtitle:
                'Manage your name, contact info, and security credentials',
            icon: Icons.person_outline,
            route: '/profile',
          ),
          _SettingsItem(
            title: 'SaaS Subscription Plan',
            subtitle: 'Change plans, view renewals, and features checklist',
            icon: Icons.credit_card_outlined,
            route: '/subscription',
          ),
        ],
      ),
      _SettingsGroup(
        title: 'Business Configuration',
        items: [
          _SettingsItem(
            title: 'Business Details',
            subtitle: 'Edit legal names, GSTIN, PAN, and contacts',
            icon: Icons.business_outlined,
            route: '/business-selection',
          ),
          _SettingsItem(
            title: 'Invoice Customization Templates',
            subtitle:
                'Configure primary branding colors, bank details, signature and footer templates',
            icon: Icons.palette_outlined,
            route: '/settings/invoice-customization',
          ),
          _SettingsItem(
            title: 'Multi-Warehouse Godowns',
            subtitle: 'Manage branches, warehouses and stock locations',
            icon: Icons.warehouse_outlined,
            route: '/settings/warehouses',
          ),
          _SettingsItem(
            title: 'Customer Recurring Billing',
            subtitle:
                'Automate recurring subscription invoices and schedulers',
            icon: Icons.autorenew_outlined,
            route: '/settings/recurring-billing',
          ),
        ],
      ),
      _SettingsGroup(
        title: 'Team, Safety & Migration',
        items: [
          _SettingsItem(
            title: 'Users & Custom Permissions (RBAC)',
            subtitle:
                'Manage team access, custom roles matrix view/edit policy',
            icon: Icons.people_outline,
            route: '/settings/users',
          ),
          _SettingsItem(
            title: 'Security Audit Logs',
            subtitle: 'Examine ledger, adjustments, invoices updates trail',
            icon: Icons.security_outlined,
            route: '/settings/audit-logs',
          ),
          _SettingsItem(
            title: 'Data Migration Import / Export',
            subtitle:
                'Parse spreadsheet CSV/Excel list uploads, validation dry-runs',
            icon: Icons.swap_vert_outlined,
            route: '/settings/import-export',
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    context: context,
                    isDark: isDark,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    mutedText: mutedText,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ...settingsGroups.map(
                    (group) => _buildGroup(
                      context: context,
                      group: group,
                      isDark: isDark,
                      primaryText: primaryText,
                      mutedText: mutedText,
                      dividerColor: dividerColor,
                      iconColor: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color mutedText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard  /  Settings',
          style: AppTypography.bodySmall.copyWith(
            color: mutedText,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              alignment: Alignment.centerLeft,
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 22,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Settings & Administration',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage business entities, invoicing, tax setup, and user privileges.',
                    style: TextStyle(fontSize: 12.5, color: secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroup({
    required BuildContext context,
    required _SettingsGroup group,
    required bool isDark,
    required Color primaryText,
    required Color mutedText,
    required Color dividerColor,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  group.title.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(group.items.length, (index) {
            final item = group.items[index];
            final isLast = index == group.items.length - 1;
            return Column(
              children: [
                _SettingsRow(
                  item: item,
                  isDark: isDark,
                  primaryText: primaryText,
                  mutedText: mutedText,
                  iconColor: iconColor,
                  onTap: () => context.push(item.route),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: dividerColor,
                    indent: 56,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatefulWidget {
  final _SettingsItem item;
  final bool isDark;
  final Color primaryText;
  final Color mutedText;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.item,
    required this.isDark,
    required this.primaryText,
    required this.mutedText,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          color: _hovered
              ? (widget.isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFF0F172A).withValues(alpha: 0.03))
              : Colors.transparent,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 18,
                  color: widget.isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: widget.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: widget.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: widget.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.title, required this.items});
}

class _SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
