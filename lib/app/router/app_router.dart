import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/layouts/app_shell.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/business/presentation/providers/business_provider.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/business/presentation/pages/business_selection_page.dart';
import '../../features/business/presentation/pages/create_business_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/subscription/presentation/pages/upgrade_page.dart';
import '../../features/subscription/presentation/pages/locked_feature_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

// Phase 1 Page Imports
import '../../features/customer/presentation/pages/customer_page.dart';
import '../../features/customer/presentation/pages/customer_form_page.dart';
import '../../features/customer/presentation/pages/customer_detail_page.dart';
import '../../features/supplier/presentation/pages/supplier_page.dart';
import '../../features/supplier/presentation/pages/supplier_form_page.dart';
import '../../features/supplier/presentation/pages/supplier_detail_page.dart';
import '../../features/product/presentation/pages/product_form_page.dart';
import '../../features/product-listing/presentation/pages/product_listing_page.dart';
import '../../features/service/presentation/pages/service_page.dart';
import '../../features/service/presentation/pages/service_form_page.dart';
import '../../features/sales/presentation/pages/sales_invoice_page.dart';
import '../../features/sales/presentation/pages/invoice_create_page.dart';
import '../../features/sales/presentation/pages/invoice_detail_page.dart';
import '../../features/sales/presentation/pages/sale_return_page.dart';
import '../../features/sales/presentation/pages/sale_return_create_page.dart';
import '../../features/sales/presentation/pages/sale_return_detail_page.dart';
import '../../features/purchase/presentation/pages/purchase_page.dart';
import '../../features/purchase/presentation/pages/purchase_create_page.dart';
import '../../features/purchase/presentation/pages/purchase_detail_page.dart';
import '../../features/purchase/presentation/pages/purchase_return_page.dart';
import '../../features/payments/presentation/pages/receipt_entry_page.dart';
import '../../features/payments/presentation/pages/payment_entry_page.dart';
import '../../features/double-entery-account/presentation/pages/general_ledger_page.dart';
import '../../features/accounting/presentation/pages/outstanding_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/expenses/presentation/pages/expense_page.dart';

// Phase 2 Page Imports
import '../../features/sales/presentation/pages/pos_page.dart';
import '../../features/dashboard/presentation/pages/reports_page.dart';
import '../../features/inventory/presentation/pages/warehouse_page.dart';
import '../../features/subscription/presentation/pages/recurring_billing_page.dart';
import '../../features/settings/presentation/pages/invoice_customization_page.dart';
import '../../features/settings/presentation/pages/user_management_page.dart';
import '../../features/settings/presentation/pages/audit_log_page.dart';
import '../../features/settings/presentation/pages/import_export_page.dart';

// Phase 3 Page Imports
import '../../features/accounting/presentation/pages/chart_of_accounts_page.dart';
import '../../features/accounting/presentation/pages/journal_entries_page.dart';
import '../../features/accounting/presentation/pages/financial_reports_page.dart';
import '../../features/accounting/presentation/pages/bank_management_page.dart';
import '../../features/manufacturing/presentation/pages/bom_page.dart';
import '../../features/manufacturing/presentation/pages/production_orders_page.dart';
import '../../features/manufacturing/presentation/pages/job_work_page.dart';
import '../../features/manufacturing/presentation/pages/manufacturing_reports_page.dart';
import '../../features/gstIn/presentation/pages/gst_portal_page.dart';
import '../../features/platform-admin/presentation/pages/platform_admin_login_page.dart';
import '../../features/platform-admin/presentation/pages/platform_admin_shell_page.dart';

import '../../shared/widgets/app_states.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = RefListenable(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/business-selection',
        builder: (context, state) => const BusinessSelectionPage(),
      ),
      GoRoute(
        path: '/create-business',
        builder: (context, state) => const CreateBusinessPage(),
      ),
      GoRoute(
        path: '/platform-admin/login',
        builder: (context, state) => const PlatformAdminLoginPage(),
      ),
      GoRoute(
        path: '/platform-admin',
        builder: (context, state) => const PlatformAdminShellPage(),
      ),
      GoRoute(
        path: '/platform-admin/dashboard',
        builder: (context, state) => const PlatformAdminShellPage(initialTab: 'dashboard'),
      ),
      GoRoute(
        path: '/platform-admin/organizations',
        builder: (context, state) => const PlatformAdminShellPage(initialTab: 'organizations'),
      ),
      GoRoute(
        path: '/platform-admin/subscriptions',
        builder: (context, state) => const PlatformAdminShellPage(initialTab: 'subscriptions'),
      ),
      GoRoute(
        path: '/platform-admin/onboarding',
        builder: (context, state) => const PlatformAdminShellPage(initialTab: 'onboarding'),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/subscription',
            builder: (context, state) => const SubscriptionPage(),
          ),
          GoRoute(
            path: '/upgrade',
            builder: (context, state) => const UpgradePage(),
          ),
          GoRoute(
            path: '/locked-feature',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final featureName = extra?['featureName'] as String? ?? 'this feature';
              return LockedFeaturePage(featureName: featureName);
            },
          ),

          // Customers
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerPage(),
          ),
          GoRoute(
            path: '/customers/new',
            builder: (context, state) => const CustomerFormPage(),
          ),
          GoRoute(
            path: '/customers/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerDetailPage(customerId: id);
            },
          ),
          GoRoute(
            path: '/customers/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerFormPage(customerId: id);
            },
          ),

          // Suppliers
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const SupplierPage(),
          ),
          GoRoute(
            path: '/suppliers/new',
            builder: (context, state) => const SupplierFormPage(),
          ),
          GoRoute(
            path: '/suppliers/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierDetailPage(supplierId: id);
            },
          ),
          GoRoute(
            path: '/suppliers/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierFormPage(supplierId: id);
            },
          ),

          // Products
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListingPage(),
          ),
          GoRoute(
            path: '/product-listing',
            builder: (context, state) => const ProductListingPage(),
          ),
          GoRoute(
            path: '/products/new',
            builder: (context, state) => const ProductFormPage(),
          ),
          GoRoute(
            path: '/products/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductFormPage(productId: id);
            },
          ),

          // Services
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicePage(),
          ),
          GoRoute(
            path: '/services/new',
            builder: (context, state) => const ServiceFormPage(),
          ),
          GoRoute(
            path: '/services/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ServiceFormPage(serviceId: id);
            },
          ),

          // Sales
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesInvoicePage(),
          ),
          GoRoute(
            path: '/sales/new',
            builder: (context, state) => const InvoiceCreatePage(),
          ),
          GoRoute(
            path: '/sales/returns',
            builder: (context, state) => const SaleReturnPage(),
          ),
          GoRoute(
            path: '/sales/returns/new',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final originalInvoiceId = extra?['originalInvoiceId'] as String? ?? state.uri.queryParameters['invoiceId'] ?? '';
              return SaleReturnCreatePage(originalInvoiceId: originalInvoiceId);
            },
          ),
          GoRoute(
            path: '/sales/returns/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SaleReturnDetailPage(returnId: id);
            },
          ),
          GoRoute(
            path: '/sales/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvoiceDetailPage(invoiceId: id);
            },
          ),

          // Purchases
          GoRoute(
            path: '/purchase/returns',
            builder: (context, state) => const PurchaseReturnPage(),
          ),
          GoRoute(
            path: '/purchase/returns/new',
            builder: (context, state) => const PurchaseReturnPage(),
          ),
          GoRoute(
            path: '/purchase',
            builder: (context, state) => const PurchasePage(),
          ),
          GoRoute(
            path: '/purchase/new',
            builder: (context, state) => const PurchaseCreatePage(),
          ),
          GoRoute(
            path: '/purchase/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              if (id == 'returns') {
                return const PurchaseReturnPage();
              }
              return PurchaseDetailPage(purchaseId: id);
            },
          ),

          // Payments & Receipts
          GoRoute(
            path: '/receipts/new',
            builder: (context, state) => const ReceiptEntryPage(),
          ),
          GoRoute(
            path: '/payments/new',
            builder: (context, state) => const PaymentEntryPage(),
          ),

          // Ledger, Outstanding, Inventory & Expenses
          GoRoute(
            path: '/ledger',
            builder: (context, state) => const GeneralLedgerPage(),
          ),
          GoRoute(
            path: '/outstanding',
            builder: (context, state) => const OutstandingPage(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryPage(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensePage(),
          ),

          GoRoute(
            path: '/pos',
            builder: (context, state) => const POSPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/gst',
            builder: (context, state) => const GstPortalPage(),
          ),
          GoRoute(
            path: '/settings/warehouses',
            builder: (context, state) => const WarehousePage(),
          ),
          GoRoute(
            path: '/settings/recurring-billing',
            builder: (context, state) => const RecurringBillingPage(),
          ),
          GoRoute(
            path: '/settings/invoice-customization',
            builder: (context, state) => const InvoiceCustomizationPage(),
          ),
          GoRoute(
            path: '/settings/users',
            builder: (context, state) => const UserManagementPage(),
          ),
          GoRoute(
            path: '/settings/audit-logs',
            builder: (context, state) => const AuditLogPage(),
          ),
          GoRoute(
            path: '/settings/import-export',
            builder: (context, state) => const ImportExportPage(),
          ),

          // Phase 3: Accounting Routes
          GoRoute(
            path: '/accounting/chart-of-accounts',
            builder: (context, state) => const ChartOfAccountsPage(),
          ),
          GoRoute(
            path: '/accounting/journal-entries',
            builder: (context, state) => const JournalEntriesPage(),
          ),
          GoRoute(
            path: '/accounting/financial-reports',
            builder: (context, state) => const FinancialReportsPage(),
          ),
          GoRoute(
            path: '/accounting/bank-management',
            builder: (context, state) => const BankManagementPage(),
          ),

          // Phase 3: Manufacturing Routes
          GoRoute(
            path: '/manufacturing/bom',
            builder: (context, state) => const BOMPage(),
          ),
          GoRoute(
            path: '/manufacturing/production-orders',
            builder: (context, state) => const ProductionOrdersPage(),
          ),
          GoRoute(
            path: '/manufacturing/job-work',
            builder: (context, state) => const JobWorkPage(),
          ),
          GoRoute(
            path: '/manufacturing/reports',
            builder: (context, state) => const ManufacturingReportsPage(),
          ),

          // Placeholder / Future scope
          ...['gst'].map((path) {
            return GoRoute(
              path: '/$path',
              builder: (context, state) => ComingSoonPage(moduleName: path),
            );
          }),
        ],
      ),
    ],
    errorBuilder: (context, state) => const RouteNotFoundPage(),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isOnboarded = ref.read(onboardingProvider);
      final businessState = ref.read(businessProvider);
      final loc = state.matchedLocation;
      
      if (authState.status == AuthStatus.splash) {
        return '/splash';
      }

      final isPlatformAdminRoute = loc.startsWith('/platform-admin');
      if (isPlatformAdminRoute) {
        return null;
      }

      final isUnauthenticated = authState.status == AuthStatus.unauthenticated;
      final authRoutes = ['/login', '/register', '/forgot-password', '/otp', '/splash'];
      final isGoingToAuthRoute = authRoutes.contains(loc);

      if (isUnauthenticated) {
        if (loc == '/splash') return '/login';
        return isGoingToAuthRoute ? null : '/login';
      }

      if (isGoingToAuthRoute) {
        if (!isOnboarded) return '/onboarding';
        if (businessState.activeBusiness == null) return '/business-selection';
        return '/dashboard';
      }

      if (!isOnboarded && loc != '/onboarding') {
        return '/onboarding';
      }

      if (isOnboarded && loc == '/onboarding') {
        if (businessState.activeBusiness == null) return '/business-selection';
        return '/dashboard';
      }

      if (isOnboarded && businessState.activeBusiness == null && loc != '/business-selection' && loc != '/create-business') {
        return '/business-selection';
      }

      return null;
    },
  );
});

class RefListenable extends ChangeNotifier {
  RefListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(onboardingProvider, (_, __) => notifyListeners());
    ref.listen(businessProvider, (_, __) => notifyListeners());
  }
}

class ComingSoonPage extends StatelessWidget {
  final String moduleName;
  const ComingSoonPage({super.key, required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(moduleName.toUpperCase())),
      body: AppEmptyState(
        title: 'Coming Soon',
        description: 'The $moduleName module is currently in development.',
        icon: Icons.construction,
        actionLabel: 'Back to Dashboard',
        onActionPressed: () => context.go('/dashboard'),
      ),
    );
  }
}

class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppEmptyState(
        title: '404 - Not Found',
        description: 'The page you are looking for does not exist.',
        icon: Icons.warning_amber_rounded,
        actionLabel: 'Go Home',
        onActionPressed: () => context.go('/dashboard'),
      ),
    );
  }
}
