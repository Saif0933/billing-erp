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

  // Customer & Supplier & Services
  static const String customers = '/api/v1/customers';
  static const String suppliers = '/api/v1/suppliers';
  static const String services = '/api/v1/services';


  // Inventory & Products
  static const String products = '/api/v1/products';
  static const String warehouses = '/api/v1/warehouses';
  static const String stockMovements = '/api/v1/inventory/movements';

  // Subscription & Plans
  static const String plans = '/api/v1/subscriptions/plans';
  static const String activeSubscription = '/api/v1/subscriptions/active';

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
}
