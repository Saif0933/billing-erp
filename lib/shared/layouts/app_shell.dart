import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/responsive/responsive_breakpoints.dart';
import '../../features/subscription/domain/entities/subscription_models.dart';
import '../../features/subscription/presentation/providers/subscription_provider.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/mobile_drawer.dart';
import 'widgets/top_header.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String? currentLocation;
  const AppShell({super.key, required this.child, this.currentLocation});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Set<String> _tabRoutes = {
    '/dashboard',
    '/sales',
    '/pos',
    '/inventory',
  };

  bool _isTabRoute(String location) {
    final cleanPath = location.split('?').first;
    final normalized = cleanPath.endsWith('/') && cleanPath.length > 1
        ? cleanPath.substring(0, cleanPath.length - 1)
        : cleanPath;
    return _tabRoutes.contains(normalized);
  }

  int _calculateSelectedIndex(String location) {
    if (location == '/dashboard') return 0;
    if (location == '/sales') return 1;
    if (location == '/pos') return 2;
    if (location == '/inventory') return 3;
    return 0;
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) context.go('/dashboard');
    if (index == 1) context.go('/sales');
    if (index == 2) context.go('/pos');
    if (index == 3) context.go('/inventory');
    if (index == 4) _showMoreBottomSheet(context);
  }

  void _showMoreBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscription = ref.read(subscriptionProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'More Modules',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _buildMoreGroup(
                        context,
                        title: 'Accounting & Finance',
                        subscription: subscription,
                        items: [
                          _buildMoreItem(
                            context,
                            'General Ledger',
                            '/ledger',
                            Icons.menu_book_outlined,
                            SubscriptionFeature.ledger,
                          ),
                          _buildMoreItem(
                            context,
                            'Chart of Accounts',
                            '/accounting/chart-of-accounts',
                            Icons.account_tree_outlined,
                            SubscriptionFeature.accounting,
                          ),
                          _buildMoreItem(
                            context,
                            'Journal Entries',
                            '/accounting/journal-entries',
                            Icons.import_contacts_outlined,
                            SubscriptionFeature.accounting,
                          ),
                          _buildMoreItem(
                            context,
                            'Bank Accounts',
                            '/accounting/bank-management',
                            Icons.account_balance_wallet_outlined,
                            SubscriptionFeature.accounting,
                          ),
                          _buildMoreItem(
                            context,
                            'Financial Statements',
                            '/accounting/financial-reports',
                            Icons.analytics_outlined,
                            SubscriptionFeature.accounting,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMoreGroup(
                        context,
                        title: 'Manufacturing & Workflow',
                        subscription: subscription,
                        items: [
                          _buildMoreItem(
                            context,
                            'Bill of Materials',
                            '/manufacturing/bom',
                            Icons.settings_input_component_outlined,
                            SubscriptionFeature.manufacturing,
                          ),
                          _buildMoreItem(
                            context,
                            'Production Orders',
                            '/manufacturing/production-orders',
                            Icons.precision_manufacturing_outlined,
                            SubscriptionFeature.manufacturing,
                          ),
                          _buildMoreItem(
                            context,
                            'Job Work Register',
                            '/manufacturing/job-work',
                            Icons.assignment_ind_outlined,
                            SubscriptionFeature.manufacturing,
                          ),
                          _buildMoreItem(
                            context,
                            'Manufacturing Reports',
                            '/manufacturing/reports',
                            Icons.assessment_outlined,
                            SubscriptionFeature.manufacturing,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMoreGroup(
                        context,
                        title: 'Purchase & Expense',
                        subscription: subscription,
                        items: [
                          _buildMoreItem(
                            context,
                            'Purchase Invoices',
                            '/purchase',
                            Icons.shopping_cart_outlined,
                            SubscriptionFeature.purchase,
                          ),
                          _buildMoreItem(
                            context,
                            'Expenses Tracker',
                            '/expenses',
                            Icons.money_off_outlined,
                            SubscriptionFeature.expenses,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMoreGroup(
                        context,
                        title: 'Masters & Contacts',
                        subscription: subscription,
                        items: [
                          _buildMoreItem(
                            context,
                            'Customers Directory',
                            '/customers',
                            Icons.people_outline,
                            SubscriptionFeature.customers,
                          ),
                          _buildMoreItem(
                            context,
                            'Suppliers Directory',
                            '/suppliers',
                            Icons.local_shipping_outlined,
                            SubscriptionFeature.suppliers,
                          ),
                          _buildMoreItem(
                            context,
                            'Services Directory',
                            '/services',
                            Icons.design_services_outlined,
                            SubscriptionFeature.services,
                          ),
                          _buildMoreItem(
                            context,
                            'Products Directory',
                            '/products',
                            Icons.view_in_ar_outlined,
                            SubscriptionFeature.products,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMoreGroup(
                        context,
                        title: 'Taxation & Config',
                        subscription: subscription,
                        items: [
                          _buildMoreItem(
                            context,
                            'GST Portal Center',
                            '/gst',
                            Icons.account_balance_outlined,
                            SubscriptionFeature.gst,
                          ),
                          _buildMoreItem(
                            context,
                            'General Settings',
                            '/settings',
                            Icons.settings_outlined,
                            SubscriptionFeature.dashboard,
                          ),
                          _buildMoreItem(
                            context,
                            'User Management',
                            '/settings/users',
                            Icons.people_outline,
                            SubscriptionFeature.dashboard,
                          ),
                          _buildMoreItem(
                            context,
                            'Security Audit Logs',
                            '/settings/audit-logs',
                            Icons.security,
                            SubscriptionFeature.dashboard,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMoreGroup(
    BuildContext context, {
    required String title,
    required SubscriptionModel subscription,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smBorder,
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMoreItem(
    BuildContext context,
    String label,
    String route,
    IconData icon,
    SubscriptionFeature feature,
  ) {
    final subscription = ref.watch(subscriptionProvider);
    final isAllowed = subscription.canAccess(feature);

    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: !isAllowed
          ? const Icon(Icons.lock, size: 14, color: Colors.orange)
          : const Icon(Icons.chevron_right, size: 16),
      onTap: () {
        Navigator.pop(context); // Close sheet
        if (isAllowed) {
          context.push(route);
        } else {
          context.push('/locked-feature', extra: {'featureName': label});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String currentLoc = widget.currentLocation ?? state.uri.path;

    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTabScreen = _isTabRoute(currentLoc);

    return Scaffold(
      key: _scaffoldKey,
      appBar: isTabScreen
          ? ResponsiveTopHeader(scaffoldKey: _scaffoldKey)
          : null,
      drawer: (isMobile && isTabScreen) ? const MobileDrawer() : null,
      body: Row(
        children: [
          // Sidebar for Desktop & Tablet
          if (!isMobile) const DesktopSidebar(),
          // Content Area
          Expanded(
            child: SafeArea(
              top: !isTabScreen,
              bottom: !isTabScreen,
              child: widget.child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: (isMobile && isTabScreen)
          ? BottomNavigationBar(
              currentIndex: _calculateSelectedIndex(currentLoc),
              selectedItemColor: AppColors.accentDark,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: _onBottomNavTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Sales',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale_outlined),
                  label: 'POS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.warehouse_outlined),
                  label: 'Stock',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            )
          : null,
    );
  }
}
