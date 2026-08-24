import 'package:flutter/material.dart';
import 'navigation_item.dart';
import '../permissions/permission_models.dart';
import '../../features/subscription/domain/entities/subscription_models.dart';

class NavigationConfig {
  NavigationConfig._();

  static const List<NavigationItem> menuItems = [
    NavigationItem(
      id: 'dashboard',
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/dashboard',
      requiredFeature: SubscriptionFeature.dashboard,
    ),
    NavigationItem(
      id: 'pos',
      title: 'POS Terminal',
      icon: Icons.point_of_sale_outlined,
      route: '/pos',
      requiredFeature: SubscriptionFeature.pos,
    ),
    NavigationItem(
      id: 'masters',
      title: 'Business Masters',
      icon: Icons.store_outlined,
      route: '/customers',
      children: [
        NavigationItem(
          id: 'customers',
          title: 'Customers',
          icon: Icons.people_outline,
          route: '/customers',
          requiredFeature: SubscriptionFeature.customers,
        ),
        NavigationItem(
          id: 'suppliers',
          title: 'Suppliers',
          icon: Icons.local_shipping_outlined,
          route: '/suppliers',
          requiredFeature: SubscriptionFeature.suppliers,
        ),
        NavigationItem(
          id: 'products',
          title: 'Products',
          icon: Icons.view_in_ar_outlined,
          route: '/products',
          requiredFeature: SubscriptionFeature.products,
        ),
        NavigationItem(
          id: 'services',
          title: 'Services',
          icon: Icons.design_services_outlined,
          route: '/services',
          requiredFeature: SubscriptionFeature.services,
        ),
      ],
    ),
    NavigationItem(
      id: 'sales_group',
      title: 'Sales Operations',
      icon: Icons.receipt_long_outlined,
      route: '/sales',
      children: [
        NavigationItem(
          id: 'sales',
          title: 'Sales Invoices',
          icon: Icons.receipt_long_outlined,
          route: '/sales',
          requiredFeature: SubscriptionFeature.sales,
        ),
        NavigationItem(
          id: 'recurring_billing',
          title: 'Recurring Billing',
          icon: Icons.auto_delete_outlined,
          route: '/settings/recurring-billing',
          requiredFeature: SubscriptionFeature.sales,
        ),
      ],
    ),
    NavigationItem(
      id: 'purchase_group',
      title: 'Purchases & Bills',
      icon: Icons.shopping_cart_outlined,
      route: '/purchase',
      children: [
        NavigationItem(
          id: 'purchase',
          title: 'Purchase Bills',
          icon: Icons.shopping_cart_outlined,
          route: '/purchase',
          requiredFeature: SubscriptionFeature.purchase,
        ),
      ],
    ),
    NavigationItem(
      id: 'payments_group',
      title: 'Payments & Receipts',
      icon: Icons.payment_outlined,
      route: '/payments/new',
      children: [
        NavigationItem(
          id: 'receipts',
          title: 'Receipts Entry',
          icon: Icons.receipt_outlined,
          route: '/receipts/new',
          requiredFeature: SubscriptionFeature.receipts,
        ),
        NavigationItem(
          id: 'payments',
          title: 'Payments Entry',
          icon: Icons.payment_outlined,
          route: '/payments/new',
          requiredFeature: SubscriptionFeature.payments,
        ),
        NavigationItem(
          id: 'outstanding',
          title: 'Outstanding Analysis',
          icon: Icons.account_balance_outlined,
          route: '/outstanding',
          requiredFeature: SubscriptionFeature.outstanding,
        ),
      ],
    ),
    NavigationItem(
      id: 'expenses',
      title: 'Expenses Tracker',
      icon: Icons.money_off_outlined,
      route: '/expenses',
      requiredFeature: SubscriptionFeature.expenses,
    ),
    NavigationItem(
      id: 'inventory_group',
      title: 'Inventory Control',
      icon: Icons.warehouse_outlined,
      route: '/inventory',
      children: [
        NavigationItem(
          id: 'inventory',
          title: 'Stock Valuation',
          icon: Icons.warehouse_outlined,
          route: '/inventory',
          requiredFeature: SubscriptionFeature.inventory,
        ),
        NavigationItem(
          id: 'warehouses',
          title: 'Godowns / Warehouses',
          icon: Icons.warehouse_outlined,
          route: '/settings/warehouses',
          requiredFeature: SubscriptionFeature.warehouse,
        ),
      ],
    ),
    NavigationItem(
      id: 'accounting_group',
      title: 'Double-Entry Accounting',
      icon: Icons.menu_book_outlined,
      route: '/ledger',
      children: [
        NavigationItem(
          id: 'ledger',
          title: 'General Ledger',
          icon: Icons.menu_book_outlined,
          route: '/ledger',
          requiredFeature: SubscriptionFeature.ledger,
        ),
        NavigationItem(
          id: 'chart_of_accounts',
          title: 'Chart of Accounts',
          icon: Icons.account_tree_outlined,
          route: '/accounting/chart-of-accounts',
          requiredFeature: SubscriptionFeature.accounting,
        ),
        NavigationItem(
          id: 'journal_entries',
          title: 'Journal Entries',
          icon: Icons.import_contacts_outlined,
          route: '/accounting/journal-entries',
          requiredFeature: SubscriptionFeature.accounting,
        ),
        NavigationItem(
          id: 'bank_accounts',
          title: 'Bank Accounts',
          icon: Icons.account_balance_wallet_outlined,
          route: '/accounting/bank-management',
          requiredFeature: SubscriptionFeature.accounting,
        ),
        NavigationItem(
          id: 'financial_reports',
          title: 'Financial Statements',
          icon: Icons.analytics_outlined,
          route: '/accounting/financial-reports',
          requiredFeature: SubscriptionFeature.accounting,
        ),
      ],
    ),
    NavigationItem(
      id: 'manufacturing_group',
      title: 'Manufacturing & BOM',
      icon: Icons.precision_manufacturing_outlined,
      route: '/manufacturing/bom',
      children: [
        NavigationItem(
          id: 'bom',
          title: 'Bill of Materials',
          icon: Icons.settings_input_component_outlined,
          route: '/manufacturing/bom',
          requiredFeature: SubscriptionFeature.manufacturing,
        ),
        NavigationItem(
          id: 'production_orders',
          title: 'Production Orders',
          icon: Icons.precision_manufacturing_outlined,
          route: '/manufacturing/production-orders',
          requiredFeature: SubscriptionFeature.manufacturing,
        ),
        NavigationItem(
          id: 'job_work',
          title: 'Job Work Register',
          icon: Icons.assignment_ind_outlined,
          route: '/manufacturing/job-work',
          requiredFeature: SubscriptionFeature.manufacturing,
        ),
        NavigationItem(
          id: 'mfg_reports',
          title: 'Manufacturing Reports',
          icon: Icons.assessment_outlined,
          route: '/manufacturing/reports',
          requiredFeature: SubscriptionFeature.manufacturing,
        ),
      ],
    ),
    NavigationItem(
      id: 'gst',
      title: 'GST Portal GSTIN',
      icon: Icons.account_balance_outlined,
      route: '/gst',
      requiredFeature: SubscriptionFeature.gst,
    ),
    NavigationItem(
      id: 'reports',
      title: 'Reports Center',
      icon: Icons.analytics_outlined,
      route: '/reports',
      requiredFeature: SubscriptionFeature.reports,
    ),
    NavigationItem(
      id: 'subscription_group',
      title: 'Billing & Plan',
      icon: Icons.credit_card_outlined,
      route: '/subscription',
      children: [
        NavigationItem(
          id: 'subscription',
          title: 'My Subscription',
          icon: Icons.credit_card_outlined,
          route: '/subscription',
        ),
        NavigationItem(
          id: 'upgrade',
          title: 'Upgrade Plan',
          icon: Icons.upgrade_outlined,
          route: '/upgrade',
        ),
      ],
    ),
    NavigationItem(
      id: 'settings_group',
      title: 'Settings & Administration',
      icon: Icons.settings_outlined,
      route: '/settings',
      children: [
        NavigationItem(
          id: 'settings',
          title: 'General Settings',
          icon: Icons.settings_outlined,
          route: '/settings',
        ),
        NavigationItem(
          id: 'profile',
          title: 'User Profile',
          icon: Icons.person_outline,
          route: '/profile',
        ),
        NavigationItem(
          id: 'invoice_customization',
          title: 'Invoice Templates',
          icon: Icons.palette_outlined,
          route: '/settings/invoice-customization',
        ),
        NavigationItem(
          id: 'users',
          title: 'Team & RBAC Access',
          icon: Icons.people_outline,
          route: '/settings/users',
        ),
        NavigationItem(
          id: 'audit_logs',
          title: 'Security Audit Trail',
          icon: Icons.security,
          route: '/settings/audit-logs',
        ),
        NavigationItem(
          id: 'import_export',
          title: 'Import & Export',
          icon: Icons.swap_vert_outlined,
          route: '/settings/import-export',
        ),
      ],
    ),
  ];
}
