import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/platform_admin_provider.dart';
import 'platform_admin_dashboard_page.dart';
import 'platform_admin_organization_page.dart';
import 'platform_admin_subscription_page.dart';
import 'platform_admin_onboarding_page.dart';

class PlatformAdminShellPage extends ConsumerWidget {
  final String? initialTab;

  const PlatformAdminShellPage({super.key, this.initialTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(platformAdminProvider);
    final notifier = ref.read(platformAdminProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    // Use initialTab if supplied and different
    if (initialTab != null && initialTab != state.selectedNavTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setNavTab(initialTab!);
      });
    }

    Widget contentBody;
    switch (state.selectedNavTab) {
      case 'organizations':
        contentBody = const PlatformAdminOrganizationPage();
        break;
      case 'subscriptions':
        contentBody = const PlatformAdminSubscriptionPage();
        break;
      case 'onboarding':
        contentBody = const PlatformAdminOnboardingPage();
        break;
      case 'dashboard':
      default:
        contentBody = const PlatformAdminDashboardPage();
        break;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Mobile Drawer Button
                  if (!isDesktop) ...[
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Logo & Platform Badge
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Platform Admin',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SUPERADMIN',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4F46E5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (screenWidth >= 520)
                          Text(
                            'Multi-Tenant SaaS Infrastructure',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Return to Tenant App Button
                  if (screenWidth >= 768) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.storefront_outlined, size: 15),
                      label: const Text('Tenant Billing App', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () => context.go('/dashboard'),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // SuperAdmin Avatar & Logout
                  PopupMenuButton<String>(
                    tooltip: 'Admin Profile',
                    offset: const Offset(0, 48),
                    onSelected: (action) {
                      if (action == 'logout') {
                        notifier.logout();
                        AppFeedback.showSnackbar(context, message: 'SuperAdmin signed out.');
                        context.go('/platform-admin/login');
                      } else if (action == 'tenant_app') {
                        context.go('/dashboard');
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.currentUser?.name ?? 'Alexander Wright', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(state.currentUser?.email ?? 'admin@platform-billing.com', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'tenant_app',
                        child: Row(
                          children: [
                            Icon(Icons.business, size: 16, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text('Open Tenant App'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sign Out', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF4F46E5),
                          child: Text(
                            state.currentUser?.name.substring(0, 1) ?? 'A',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 8),
                          Text(
                            state.currentUser?.name.split(' ').first ?? 'Admin',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: !isDesktop ? _buildDrawer(context, notifier, state, isDark) : null,
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _getTabIndex(state.selectedNavTab),
              onDestinationSelected: (index) {
                final tabs = ['dashboard', 'organizations', 'subscriptions', 'onboarding'];
                notifier.setNavTab(tabs[index]);
              },
              destinations: [
                const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                const NavigationDestination(icon: Icon(Icons.domain_outlined), selectedIcon: Icon(Icons.domain), label: 'Tenants'),
                const NavigationDestination(icon: Icon(Icons.card_membership_outlined), selectedIcon: Icon(Icons.card_membership), label: 'Plans'),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: state.onboardingRequests.isNotEmpty,
                    label: Text('${state.onboardingRequests.length}'),
                    child: const Icon(Icons.person_add_alt_1_outlined),
                  ),
                  selectedIcon: const Icon(Icons.person_add_alt_1),
                  label: 'Onboarding',
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          // Desktop Sidebar
          if (isDesktop)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(right: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSidebarItem(
                    title: 'Executive Dashboard',
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    tabId: 'dashboard',
                    isSelected: state.selectedNavTab == 'dashboard',
                    onTap: () => notifier.setNavTab('dashboard'),
                    isDark: isDark,
                  ),
                  _buildSidebarItem(
                    title: 'Organizations (Tenants)',
                    icon: Icons.domain_outlined,
                    activeIcon: Icons.domain,
                    tabId: 'organizations',
                    isSelected: state.selectedNavTab == 'organizations',
                    onTap: () => notifier.setNavTab('organizations'),
                    isDark: isDark,
                    badgeCount: state.tenants.length,
                  ),
                  _buildSidebarItem(
                    title: 'SaaS Subscriptions',
                    icon: Icons.card_membership_outlined,
                    activeIcon: Icons.card_membership,
                    tabId: 'subscriptions',
                    isSelected: state.selectedNavTab == 'subscriptions',
                    onTap: () => notifier.setNavTab('subscriptions'),
                    isDark: isDark,
                  ),
                  _buildSidebarItem(
                    title: 'Tenant Onboarding',
                    icon: Icons.person_add_alt_1_outlined,
                    activeIcon: Icons.person_add_alt_1,
                    tabId: 'onboarding',
                    isSelected: state.selectedNavTab == 'onboarding',
                    onTap: () => notifier.setNavTab('onboarding'),
                    isDark: isDark,
                    badgeCount: state.onboardingRequests.isNotEmpty ? state.onboardingRequests.length : null,
                  ),
                  const Spacer(),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.health_and_safety_outlined, size: 20, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Multi-Tenant Cloud', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('Uptime: 99.98% • Latency: 38ms', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main View Content
          Expanded(
            child: contentBody,
          ),
        ],
      ),
    );
  }

  int _getTabIndex(String tab) {
    switch (tab) {
      case 'organizations':
        return 1;
      case 'subscriptions':
        return 2;
      case 'onboarding':
        return 3;
      case 'dashboard':
      default:
        return 0;
    }
  }

  Widget _buildSidebarItem({
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required String tabId,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    int? badgeCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : (isDark ? Colors.white : const Color(0xFF334155)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    PlatformAdminNotifier notifier,
    PlatformAdminState state,
    bool isDark,
  ) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.admin_panel_settings, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Platform SuperAdmin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildSidebarItem(
              title: 'Executive Dashboard',
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              tabId: 'dashboard',
              isSelected: state.selectedNavTab == 'dashboard',
              onTap: () {
                notifier.setNavTab('dashboard');
                Navigator.pop(context);
              },
              isDark: isDark,
            ),
            _buildSidebarItem(
              title: 'Organizations (Tenants)',
              icon: Icons.domain_outlined,
              activeIcon: Icons.domain,
              tabId: 'organizations',
              isSelected: state.selectedNavTab == 'organizations',
              onTap: () {
                notifier.setNavTab('organizations');
                Navigator.pop(context);
              },
              isDark: isDark,
              badgeCount: state.tenants.length,
            ),
            _buildSidebarItem(
              title: 'SaaS Subscriptions',
              icon: Icons.card_membership_outlined,
              activeIcon: Icons.card_membership,
              tabId: 'subscriptions',
              isSelected: state.selectedNavTab == 'subscriptions',
              onTap: () {
                notifier.setNavTab('subscriptions');
                Navigator.pop(context);
              },
              isDark: isDark,
            ),
            _buildSidebarItem(
              title: 'Tenant Onboarding',
              icon: Icons.person_add_alt_1_outlined,
              activeIcon: Icons.person_add_alt_1,
              tabId: 'onboarding',
              isSelected: state.selectedNavTab == 'onboarding',
              onTap: () {
                notifier.setNavTab('onboarding');
                Navigator.pop(context);
              },
              isDark: isDark,
              badgeCount: state.onboardingRequests.isNotEmpty ? state.onboardingRequests.length : null,
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Tenant Billing App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () => context.go('/dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
