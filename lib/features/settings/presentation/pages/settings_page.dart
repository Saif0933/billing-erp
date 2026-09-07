import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_cards.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);

    final settingsGroups = [
      _SettingsGroup(
        title: 'Account Settings',
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
                'Configure primary branding colors, bank Details, signature and footer templates',
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
            subtitle:
                'Automate recurring subscriptions invoices and schedulers',
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
            subtitle:
                'Manage team access, custom roles matrix view/edit policy',
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
            subtitle:
                'Parse spreadsheet CSV/Excel list uploads, validation dry-runs',
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
                const AppPageHeader(
                  title: 'Settings Preferences',
                  description:
                      'Manage details for your business entities, invoicing configurations, tax setups, and user privileges.',
                  breadcrumbs: ['Dashboard', 'Settings'],
                ),

                // Appearance & Theme Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'Appearance & Theme',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: isDark ? AppColors.accent : AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'App Theme Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Choose how Tax Bunny displays on this device',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _buildThemeOption(
                            context: context,
                            ref: ref,
                            label: 'System Auto',
                            subtitle: 'Follows device',
                            icon: Icons.brightness_auto_rounded,
                            mode: ThemeMode.system,
                            currentMode: currentThemeMode,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          _buildThemeOption(
                            context: context,
                            ref: ref,
                            label: 'Light Mode',
                            subtitle: 'Bright & clean',
                            icon: Icons.light_mode_rounded,
                            mode: ThemeMode.light,
                            currentMode: currentThemeMode,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          _buildThemeOption(
                            context: context,
                            ref: ref,
                            label: 'Dark Mode',
                            subtitle: 'Easy on eyes',
                            icon: Icons.dark_mode_rounded,
                            mode: ThemeMode.dark,
                            currentMode: currentThemeMode,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                ...settingsGroups.map((group) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(
                          group.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      ),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: group.items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = group.items[index];
                            return ListTile(
                              leading: Icon(
                                item.icon,
                                color: isDark
                                    ? AppColors.accent
                                    : AppColors.primary,
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item.subtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                              ),
                              onTap: () => context.push(item.route),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required bool isDark,
  }) {
    final isSelected = mode == currentMode;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1)
                : (isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : (isDark
                      ? const Color(0xFF334155)
                      : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF047857))
                      : (isDark ? Colors.white : AppColors.textLightPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
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
