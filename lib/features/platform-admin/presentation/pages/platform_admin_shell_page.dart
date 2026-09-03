import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

    final authState = ref.watch(authProvider);
    final authUser = authState.user;

    final String adminName = (authUser?.fullName.trim().isNotEmpty == true)
        ? authUser!.fullName.trim()
        : ((state.currentUser?.name.trim().isNotEmpty == true)
            ? state.currentUser!.name.trim()
            : 'Super Administrator');

    final String adminEmail = (authUser?.email.trim().isNotEmpty == true)
        ? authUser!.email.trim()
        : ((state.currentUser?.email.trim().isNotEmpty == true)
            ? state.currentUser!.email.trim()
            : 'admin@platform.com');

    final String adminInitial = adminName.isNotEmpty
        ? adminName.substring(0, 1).toUpperCase()
        : 'A';

    final String adminFirstName = adminName.contains(' ')
        ? adminName.split(' ').first
        : adminName;

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

                  // Dynamic SuperAdmin Avatar & Menu
                  PopupMenuButton<String>(
                    tooltip: 'Admin Profile: $adminName',
                    offset: const Offset(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (action) async {
                      if (action == 'logout') {
                        notifier.logout();
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          AppFeedback.showSnackbar(context, message: 'SuperAdmin signed out successfully.');
                          context.go('/login');
                        }
                      } else if (action == 'tenant_app') {
                        context.go('/dashboard');
                      } else if (action == 'profile_details') {
                        _showAdminProfileDialog(context, adminName, adminEmail, isDark);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    adminInitial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      adminName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      adminEmail,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF16A34A),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Online • SuperAdmin',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'profile_details',
                        child: Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 16, color: Color(0xFF4F46E5)),
                            SizedBox(width: 10),
                            Text('View SuperAdmin Profile', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'tenant_app',
                        child: Row(
                          children: [
                            Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF4F46E5)),
                            SizedBox(width: 10),
                            Text('Open Tenant App', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 16, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                adminInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  adminFirstName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const Text(
                                  'SuperAdmin',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 16, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: !isDesktop ? _buildDrawer(context, ref, notifier, state, adminName, adminEmail, adminInitial, isDark) : null,
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
                  _buildSidebarItem(
                    title: 'Product Listing',
                    icon: Icons.qr_code_scanner_outlined,
                    activeIcon: Icons.qr_code_scanner,
                    tabId: 'product_listing',
                    isSelected: false,
                    onTap: () => context.go('/product-listing'),
                    isDark: isDark,
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
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          notifier.logout();
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            AppFeedback.showSnackbar(context, message: 'SuperAdmin signed out successfully.');
                            context.go('/login');
                          }
                        },
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
    WidgetRef ref,
    PlatformAdminNotifier notifier,
    PlatformAdminState state,
    String adminName,
    String adminEmail,
    String adminInitial,
    bool isDark,
  ) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Dynamic SuperAdmin Header in Drawer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        adminInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          adminEmail,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'SUPERADMIN',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4F46E5),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            _buildSidebarItem(
              title: 'Product Listing',
              icon: Icons.qr_code_scanner_outlined,
              activeIcon: Icons.qr_code_scanner,
              tabId: 'product_listing',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                context.go('/product-listing');
              },
              isDark: isDark,
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Admin Profile Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showAdminProfileDialog(context, adminName, adminEmail, isDark);
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Tenant Billing App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () => context.go('/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                notifier.logout();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: 'SuperAdmin signed out successfully.');
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminProfileDialog(BuildContext context, String adminName, String adminEmail, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('SuperAdmin Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileInfoTile('Full Name', adminName, Icons.person_outline, isDark),
            const SizedBox(height: 10),
            _buildProfileInfoTile('Email Address', adminEmail, Icons.email_outlined, isDark),
            const SizedBox(height: 10),
            _buildProfileInfoTile('Access Level', 'Global Platform SuperAdmin', Icons.security_outlined, isDark),
            const SizedBox(height: 10),
            _buildProfileInfoTile('Session Status', 'Active & Authenticated', Icons.check_circle_outline, isDark, isGreen: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTile(String label, String value, IconData icon, bool isDark, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF4F46E5)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isGreen ? const Color(0xFF16A34A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
