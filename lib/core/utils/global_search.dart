import '../../features/dashboard/presentation/providers/billing_repository.dart';

enum SearchCategory {
  navigation('Navigation'),
  customers('Customers'),
  suppliers('Suppliers'),
  products('Products'),
  services('Services'),
  invoices('Invoices'),
  payments('Payments'),
  receipts('Receipts'),
  general('General');

  final String label;
  const SearchCategory(this.label);
}

class SearchResult {
  final String title;
  final String subtitle;
  final SearchCategory category;
  final String route;
  final Map<String, String>? metadata;

  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.route,
    this.metadata,
  });
}

class SearchRepository {
  static const List<SearchResult> _navigationShortcuts = [
    SearchResult(
      title: 'Dashboard Overview',
      subtitle: 'KPIs, revenue trends, and business summary',
      category: SearchCategory.navigation,
      route: '/dashboard',
    ),
    SearchResult(
      title: 'POS Billing Terminal',
      subtitle: 'Fast retail checkout & point of sale counter',
      category: SearchCategory.navigation,
      route: '/pos',
    ),
    SearchResult(
      title: 'Sales Invoices',
      subtitle: 'Manage and view customer tax invoices',
      category: SearchCategory.navigation,
      route: '/sales',
    ),
    SearchResult(
      title: 'Create New Invoice',
      subtitle: 'Generate a new sales tax invoice or bill',
      category: SearchCategory.navigation,
      route: '/sales/new',
    ),
    SearchResult(
      title: 'Customers Directory',
      subtitle: 'Customer accounts, balances, and GSTINs',
      category: SearchCategory.navigation,
      route: '/customers',
    ),
    SearchResult(
      title: 'Add New Customer',
      subtitle: 'Create a new customer profile',
      category: SearchCategory.navigation,
      route: '/customers/new',
    ),
    SearchResult(
      title: 'Inventory & Items',
      subtitle: 'Manage products, services, barcodes, and stock levels',
      category: SearchCategory.navigation,
      route: '/inventory',
    ),
    SearchResult(
      title: 'Warehouse Management',
      subtitle: 'Manage storage locations and stock transfers',
      category: SearchCategory.navigation,
      route: '/inventory/warehouses',
    ),
    SearchResult(
      title: 'Purchases & Bills',
      subtitle: 'Vendor purchase bills, purchase orders & inward stock',
      category: SearchCategory.navigation,
      route: '/purchases',
    ),
    SearchResult(
      title: 'Suppliers Directory',
      subtitle: 'Vendor records, supplier balances and payables',
      category: SearchCategory.navigation,
      route: '/suppliers',
    ),
    SearchResult(
      title: 'Expenses Tracker',
      subtitle: 'Record business operating expenses & vouchers',
      category: SearchCategory.navigation,
      route: '/expenses',
    ),
    SearchResult(
      title: 'Record New Expense',
      subtitle: 'Add an expense receipt or petty cash voucher',
      category: SearchCategory.navigation,
      route: '/expenses/new',
    ),
    SearchResult(
      title: 'Outstanding Dues & Receivables',
      subtitle: 'Customer overdue invoices and aging report',
      category: SearchCategory.navigation,
      route: '/accounting/outstanding',
    ),
    SearchResult(
      title: 'Ledger & Accounting',
      subtitle: 'General ledger, account statements, and journal vouchers',
      category: SearchCategory.navigation,
      route: '/accounting/ledger',
    ),
    SearchResult(
      title: 'Bank & Cash Management',
      subtitle: 'Bank accounts, cash registers, and reconciliations',
      category: SearchCategory.navigation,
      route: '/accounting/bank-management',
    ),
    SearchResult(
      title: 'Chart of Accounts',
      subtitle: 'Assets, liabilities, equity, revenue, and expense heads',
      category: SearchCategory.navigation,
      route: '/accounting/chart-of-accounts',
    ),
    SearchResult(
      title: 'Financial Reports',
      subtitle: 'Profit & Loss, Balance Sheet, and Trial Balance',
      category: SearchCategory.navigation,
      route: '/accounting/financial-reports',
    ),
    SearchResult(
      title: 'GST Portal & Tax Filing',
      subtitle: 'GSTR-1, GSTR-3B tax summary & filing workspace',
      category: SearchCategory.navigation,
      route: '/gst',
    ),
    SearchResult(
      title: 'Reports & Analytics',
      subtitle: 'Comprehensive sales, tax, and inventory reports',
      category: SearchCategory.navigation,
      route: '/reports',
    ),
    SearchResult(
      title: 'Recurring Invoices',
      subtitle: 'Automated subscription profiles & recurring billings',
      category: SearchCategory.navigation,
      route: '/recurring-billing',
    ),
    SearchResult(
      title: 'Settings & Company Profile',
      subtitle: 'Business info, GST registration, bank details, and branding',
      category: SearchCategory.navigation,
      route: '/settings',
    ),
    SearchResult(
      title: 'User Management & Permissions',
      subtitle: 'Team members, roles, and access control',
      category: SearchCategory.navigation,
      route: '/settings/users',
    ),
    SearchResult(
      title: 'Audit Logs',
      subtitle: 'System activity, security events, and change history',
      category: SearchCategory.navigation,
      route: '/settings/audit-logs',
    ),
    SearchResult(
      title: 'Notifications Center',
      subtitle: 'System alerts, payment updates, and reminders',
      category: SearchCategory.navigation,
      route: '/notifications',
    ),
  ];

  List<SearchResult> getInitialSuggestions() {
    return _navigationShortcuts.take(8).toList();
  }

  Future<List<SearchResult>> search(String query, BillingState billingState, {SearchCategory? category}) async {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) {
      return getInitialSuggestions();
    }

    final List<SearchResult> results = [];

    // 1. Search Navigation Shortcuts
    for (var nav in _navigationShortcuts) {
      if (nav.title.toLowerCase().contains(cleanQuery) ||
          nav.subtitle.toLowerCase().contains(cleanQuery) ||
          nav.route.toLowerCase().contains(cleanQuery)) {
        results.add(nav);
      }
    }

    // 2. Search Customers
    for (var c in billingState.customers) {
      if (c.name.toLowerCase().contains(cleanQuery) ||
          c.mobile.contains(cleanQuery) ||
          c.gstin.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: c.name,
          subtitle: 'Customer - Mobile: ${c.mobile} | GSTIN: ${c.gstin}',
          category: SearchCategory.customers,
          route: '/customers/${c.id}',
        ));
      }
    }

    // 3. Search Suppliers
    for (var s in billingState.suppliers) {
      if (s.name.toLowerCase().contains(cleanQuery) ||
          s.mobile.contains(cleanQuery) ||
          s.gstin.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: s.name,
          subtitle: 'Supplier - Mobile: ${s.mobile} | GSTIN: ${s.gstin}',
          category: SearchCategory.suppliers,
          route: '/suppliers/${s.id}',
        ));
      }
    }

    // 4. Search Products
    for (var p in billingState.products) {
      if (p.name.toLowerCase().contains(cleanQuery) ||
          p.code.toLowerCase().contains(cleanQuery) ||
          p.sku.toLowerCase().contains(cleanQuery) ||
          p.barcode.contains(cleanQuery)) {
        results.add(SearchResult(
          title: p.name,
          subtitle: 'Product - SKU: ${p.sku} | Barcode: ${p.barcode} | Price: ₹${p.sellingPrice}',
          category: SearchCategory.products,
          route: '/inventory',
        ));
      }
    }

    // 5. Search Invoices
    for (var inv in billingState.invoices) {
      if (inv.invoiceNumber.toLowerCase().contains(cleanQuery) ||
          inv.customerName.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: inv.invoiceNumber,
          subtitle: 'Invoice - Customer: ${inv.customerName} | Amount: ₹${inv.grandTotal} | Status: ${inv.status.name.toUpperCase()}',
          category: SearchCategory.invoices,
          route: '/sales/${inv.id}',
        ));
      }
    }

    // 6. Search Payments
    for (var pay in billingState.payments) {
      if (pay.referenceNumber.toLowerCase().contains(cleanQuery) ||
          pay.supplierName.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: 'Payment - Ref: ${pay.referenceNumber}',
          subtitle: 'Payment Outward - Supplier: ${pay.supplierName} | Amount: ₹${pay.amount}',
          category: SearchCategory.payments,
          route: '/accounting/ledger',
        ));
      }
    }

    // 7. Search Receipts
    for (var rec in billingState.receipts) {
      if (rec.referenceNumber.toLowerCase().contains(cleanQuery) ||
          rec.customerName.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          title: 'Receipt - Ref: ${rec.referenceNumber}',
          subtitle: 'Payment Receipt - Customer: ${rec.customerName} | Amount: ₹${rec.amount}',
          category: SearchCategory.receipts,
          route: '/accounting/ledger',
        ));
      }
    }

    return results;
  }
}
