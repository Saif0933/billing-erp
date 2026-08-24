import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_cards.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final settingsGroups = [
      _SettingsGroup(
        title: 'Account Settings',
        items: [
          _SettingsItem(
            title: 'User Profile',
            subtitle: 'Manage your name, contact info, and security credentials',
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
            subtitle: 'Configure primary branding colors, bank Details, signature and footer templates',
            icon: Icons.palette_outlined,
            route: '/settings/invoice-customization',
          ),
          _SettingsItem(
            title: 'Multi-Warehouse godowns',
            subtitle: 'Manage branches, warehouses and stock locations',
            icon: Icons.warehouse_outlined,
            route: '/settings/warehouses',
          ),
          _SettingsItem(
            title: 'Customer Recurring Billing',
            subtitle: 'Automate recurring subscriptions invoices and schedulers',
            icon: Icons.auto_delete_outlined,
            route: '/settings/recurring-billing',
          ),
        ],
      ),
      _SettingsGroup(
        title: 'Team, Safety & Migration',
        items: [
          _SettingsItem(
            title: 'Users & Custom Permissions (RBAC)',
            subtitle: 'Manage team access, custom roles matrix view/edit policy',
            icon: Icons.people_outline,
            route: '/settings/users',
          ),
          _SettingsItem(
            title: 'Security Audit Logs',
            subtitle: 'Examine ledger, adjustments, invoices updates trail',
            icon: Icons.security,
            route: '/settings/audit-logs',
          ),
          _SettingsItem(
            title: 'Data Migration Import / Export',
            subtitle: 'Parse spreadsheet CSV/Excel list uploads, validation dry-runs',
            icon: Icons.swap_vert_outlined,
            route: '/settings/import-export',
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: 'Settings Preferences',
                  description: 'Manage details for your business entities, invoicing configurations, tax setups, and user privileges.',
                  breadcrumbs: const ['Dashboard', 'Settings'],
                ),
                
                ...settingsGroups.map((group) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(
                          group.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      ),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: group.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = group.items[index];
                            return ListTile(
                              leading: Icon(item.icon, color: isDark ? AppColors.accent : AppColors.primary),
                              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right, size: 18),
                              onTap: () => context.push(item.route),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                }).toList(),
              ],
            ),
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
