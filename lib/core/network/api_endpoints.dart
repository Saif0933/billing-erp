class ApiEndpoints {
  ApiEndpoints._();

  // Auth endpoints (matching backend src/module/user/routes/auth.routes.ts)
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh-token';
  static const String logout = '/api/v1/auth/logout';
  static const String getMe = '/api/v1/auth/me';

  // Business & multi-tenant endpoints
  static const String businesses = '/api/v1/businesses';
  static const String currentBusiness = '/api/v1/businesses/current';
  static const String switchBusiness = '/api/v1/businesses/switch';

  // Invoices & Billing
  static const String invoices = '/api/v1/invoices';
  static const String invoiceSeries = '/api/v1/invoices/series';
  static const String salesInvoices = '/api/v1/sales/invoices';
  static const String salesInvoiceNextNumber = '/api/v1/sales/invoices/next-number';
  static const String salesInvoiceMetrics = '/api/v1/sales/invoices/metrics/summary';
  static const String salesInvoiceHeld = '/api/v1/sales/invoices/held/list';
  static const String salesInvoiceHold = '/api/v1/sales/invoices/hold';

  // Customer & Supplier & Services
  static const String customers = '/api/v1/customers';
  static const String suppliers = '/api/v1/suppliers';
  static const String services = '/api/v1/services';


  // Inventory & Products
  static const String products = '/api/v1/products';
  static const String warehouses = '/api/v1/warehouses';
  static const String stockValuation = '/api/v1/inventory/stock-valuation';
  static const String stockMovements = '/api/v1/inventory/stock-valuation/movements';
  static const String goodsWarehouse = '/api/v1/inventory/goods-warehouse';

  // Subscription & Plans
  static const String plans = '/api/v1/subscriptions/plans';
  static const String activeSubscription = '/api/v1/subscriptions/active';
  static const String subscribePlan = '/api/v1/subscriptions/subscribe';

  // Onboarding endpoints
  static const String onboardOrganization = '/api/v1/onboarding/organization';
  static const String validateGstin = '/api/v1/onboarding/validate-gstin';
  static const String checkNameAvailability = '/api/v1/onboarding/check-name';
  static const String onboardingPlans = '/api/v1/onboarding/plans';
  static const String onboardingOrganizations = '/api/v1/onboarding/organizations';

  // GST Portal & Compliance
  static const String gstProfile = '/api/v1/gst/profile';
  static const String gstMetrics = '/api/v1/gst/metrics';
  static const String gstReturns = '/api/v1/gst/returns';
  static const String gstFileReturn = '/api/v1/gst/returns/file';
  static const String gstLiabilitySummary = '/api/v1/gst/liability-summary';
  static const String gstLookup = '/api/v1/gst/lookup';
  static const String gstSync = '/api/v1/gst/sync';
  static const String gstPayments = '/api/v1/gst/payments';
  static const String gstExportGstr1 = '/api/v1/gst/export/json/gstr1';

  // Platform Admin Directory & KPIs & Plans
  static const String platformAdminOrganizations = '/api/v1/platform-admin/organizations';
  static const String platformAdminKPIs = '/api/v1/platform-admin/organizations/kpis';
  static const String platformAdminPlans = '/api/v1/platform-admin/plans';

  // POS (Point of Sale) & Fast Billing endpoints
  static const String posProducts = '/api/v1/pos/products';
  static const String posScan = '/api/v1/pos/products/scan';
  static const String posCustomers = '/api/v1/pos/customers';
  static const String posQuickCustomer = '/api/v1/pos/customers/quick';
  static const String posSessionOpen = '/api/v1/pos/session/open';
  static const String posSessionActive = '/api/v1/pos/session/active';
  static const String posSessionClose = '/api/v1/pos/session/close';
  static const String posSessionHistory = '/api/v1/pos/session/history';
  static const String posCheckout = '/api/v1/pos/checkout';
  static const String posSales = '/api/v1/pos/sales';
  static const String posHoldCart = '/api/v1/pos/cart/hold';
  static const String posHeldCarts = '/api/v1/pos/cart/held';
  static const String posResumeCart = '/api/v1/pos/cart/resume';
  static const String posReceipt = '/api/v1/pos/receipt';
  static const String posDashboardSummary = '/api/v1/pos/dashboard/summary';

  // Payments, Receipts & Outstanding Analysis
  static const String receipts = '/api/v1/receipts';
  static const String payments = '/api/v1/payments';
  static const String outstanding = '/api/v1/outstanding';

  // Purchase Bills (backend: module/purchase/purchase-bill)
  static const String purchases = '/api/v1/purchases';

  // Purchase Returns / Debit Notes (backend: module/purchase/purchaseReturn)
  static const String purchaseReturns = '/api/v1/purchase-returns';

  // Sales Returns & Credit Notes (backend: module/salesopration/sales-return)
  static const String salesReturns = '/api/v1/sales/returns';
  static const String salesReturnNextNumber = '/api/v1/sales/returns/next-number';
  static const String salesReturnMetrics = '/api/v1/sales/returns/metrics/summary';

  // Expenses & Tracker (backend: module/expenses&tracker)
  static const String expenses = '/api/v1/expenses';
  static const String expenseSummary = '/api/v1/expenses/summary';
  static const String expenseCategories = '/api/v1/expenses/categories';

  // Report Center (backend: module/report&center)
  static const String reports = '/api/v1/reports';
  static const String reportSalesRegister = '/api/v1/reports/sales-register';
  static const String reportPurchaseRegister = '/api/v1/reports/purchase-register';
  static const String reportGstSummary = '/api/v1/reports/gst-summary';
  static const String reportStockValuation = '/api/v1/reports/stock-valuation';
  static const String reportExport = '/api/v1/reports/export';
  static const String reportExportsHistory = '/api/v1/reports/exports';
  static const String reportCatalog = '/api/v1/reports/catalog';
  static const String reportSaved = '/api/v1/reports/saved';
}
