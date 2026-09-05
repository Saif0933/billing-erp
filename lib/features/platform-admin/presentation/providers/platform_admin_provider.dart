import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/platform_admin_api_service.dart';
import '../../domain/models/platform_admin_models.dart';

class PlatformAdminState {
  final SuperAdminUser? currentUser;
  final bool isAuthenticated;
  final List<OrganizationTenant> tenants;
  final List<PlatformPlan> plans;
  final List<OnboardingRequest> onboardingRequests;
  final PlatformKPIs kpis;
  final String searchQuery;
  final String selectedStatusFilter;
  final String selectedPlanFilter;
  final String selectedNavTab; // 'dashboard', 'organizations', 'subscriptions', 'onboarding'
  final bool isLoading;

  const PlatformAdminState({
    this.currentUser,
    this.isAuthenticated = false,
    required this.tenants,
    required this.plans,
    required this.onboardingRequests,
    required this.kpis,
    this.searchQuery = '',
    this.selectedStatusFilter = 'All',
    this.selectedPlanFilter = 'All',
    this.selectedNavTab = 'dashboard',
    this.isLoading = false,
  });

  List<OrganizationTenant> get filteredTenants {
    return tenants.where((tenant) {
      final q = searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          tenant.name.toLowerCase().contains(q) ||
          tenant.code.toLowerCase().contains(q) ||
          tenant.domain.toLowerCase().contains(q) ||
          tenant.gstin.toLowerCase().contains(q) ||
          tenant.contactEmail.toLowerCase().contains(q);

      final matchesStatus = selectedStatusFilter == 'All' ||
          (selectedStatusFilter == 'Active' && tenant.status == TenantStatus.active) ||
          (selectedStatusFilter == 'Trial' && tenant.status == TenantStatus.trial) ||
          (selectedStatusFilter == 'Suspended' && tenant.status == TenantStatus.suspended) ||
          (selectedStatusFilter == 'Pending' && tenant.status == TenantStatus.pending);

      final matchesPlan = selectedPlanFilter == 'All' ||
          tenant.planName.toLowerCase() == selectedPlanFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesPlan;
    }).toList();
  }

  PlatformAdminState copyWith({
    SuperAdminUser? currentUser,
    bool? isAuthenticated,
    List<OrganizationTenant>? tenants,
    List<PlatformPlan>? plans,
    List<OnboardingRequest>? onboardingRequests,
    PlatformKPIs? kpis,
    String? searchQuery,
    String? selectedStatusFilter,
    String? selectedPlanFilter,
    String? selectedNavTab,
    bool? isLoading,
  }) {
    return PlatformAdminState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      tenants: tenants ?? this.tenants,
      plans: plans ?? this.plans,
      onboardingRequests: onboardingRequests ?? this.onboardingRequests,
      kpis: kpis ?? this.kpis,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      selectedPlanFilter: selectedPlanFilter ?? this.selectedPlanFilter,
      selectedNavTab: selectedNavTab ?? this.selectedNavTab,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PlatformAdminNotifier extends StateNotifier<PlatformAdminState> {
  final PlatformAdminApiService? _apiService;

  PlatformAdminNotifier([this._apiService])
      : super(
          PlatformAdminState(
            currentUser: SuperAdminUser(
              id: 'super_01',
              name: 'Alexander Wright',
              email: 'admin@platform-billing.com',
              role: 'Global Platform Admin',
              avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
              lastLogin: DateTime.now().subtract(const Duration(minutes: 12)),
            ),
            isAuthenticated: true,
            tenants: _initialTenants,
            plans: _initialPlans,
            onboardingRequests: _initialOnboardingRequests,
            kpis: const PlatformKPIs(
              totalMrr: 485450.00,
              totalArr: 5825400.00,
              mrrGrowthPercentage: 18.4,
              totalTenants: 148,
              activeTenants: 132,
              trialTenants: 12,
              totalUsers: 1420,
              systemUptimePercentage: 99.98,
              serverLatencyMs: 38,
              pendingOnboardings: 4,
            ),
          ),
        ) {
    loadOrganizations();
  }

  /// Load organizations directory and KPIs from backend REST API
  Future<void> loadOrganizations() async {
    if (_apiService == null) return;
    try {
      state = state.copyWith(isLoading: true);
      final res = await _apiService.getOrganizations(
        search: state.searchQuery,
        status: state.selectedStatusFilter,
        plan: state.selectedPlanFilter,
      );

      state = state.copyWith(
        tenants: res.tenants.isNotEmpty ? res.tenants : state.tenants,
        kpis: res.kpis ?? state.kpis,
        isLoading: false,
      );
    } catch (_) {
      // Gracefully retain cached state on connection error
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh platform KPIs from backend
  Future<void> refreshKPIs() async {
    if (_apiService == null) return;
    try {
      final kpis = await _apiService.getKPIs();
      state = state.copyWith(kpis: kpis);
    } catch (_) {
      // Keep existing
    }
  }

  void setNavTab(String tab) {
    state = state.copyWith(selectedNavTab: tab);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(selectedStatusFilter: status);
  }

  void setPlanFilter(String plan) {
    state = state.copyWith(selectedPlanFilter: plan);
  }

  bool login(String email, String password) {
    if (email.isNotEmpty && password.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        currentUser: SuperAdminUser(
          id: 'super_01',
          name: email.split('@').first.toUpperCase(),
          email: email,
          role: 'Global SuperAdmin',
          lastLogin: DateTime.now(),
        ),
      );
      return true;
    }
    return false;
  }

  void logout() {
    state = state.copyWith(
      isAuthenticated: false,
      currentUser: null,
    );
  }

  Future<void> toggleTenantStatus(String tenantId, TenantStatus newStatus) async {
    // 1. Optimistic update
    final updatedList = state.tenants.map((t) {
      if (t.id == tenantId) {
        return t.copyWith(status: newStatus);
      }
      return t;
    }).toList();

    state = state.copyWith(tenants: updatedList);
    _recalculateKpis();

    // 2. Sync with backend API
    if (_apiService != null) {
      try {
        final syncedTenant = await _apiService.toggleStatus(tenantId, newStatus);
        final syncedList = state.tenants.map((t) => t.id == tenantId ? syncedTenant : t).toList();
        state = state.copyWith(tenants: syncedList);
        _recalculateKpis();
      } catch (_) {
        // Retain optimistic state
      }
    }
  }

  Future<void> addTenant(OrganizationTenant tenant, {String? password}) async {
    // 1. Optimistic update
    final updatedList = [tenant, ...state.tenants];
    state = state.copyWith(tenants: updatedList);
    _recalculateKpis();

    // 2. Sync with backend API
    if (_apiService != null) {
      try {
        final serverTenant = await _apiService.createOrganization(tenant, password: password);
        final syncedList = state.tenants.map((t) => t.id == tenant.id ? serverTenant : t).toList();
        state = state.copyWith(tenants: syncedList);
        _recalculateKpis();
      } catch (_) {
        // Retain optimistic state
      }
    }
  }

  Future<void> updateTenant(OrganizationTenant tenant) async {
    // 1. Optimistic update
    final updatedList = state.tenants.map((t) {
      if (t.id == tenant.id) {
        return tenant;
      }
      return t;
    }).toList();

    state = state.copyWith(tenants: updatedList);
    _recalculateKpis();

    // 2. Sync with backend API
    if (_apiService != null) {
      try {
        final serverTenant = await _apiService.updateOrganization(tenant);
        final syncedList = state.tenants.map((t) => t.id == tenant.id ? serverTenant : t).toList();
        state = state.copyWith(tenants: syncedList);
        _recalculateKpis();
      } catch (_) {
        // Retain optimistic state
      }
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    // 1. Optimistic update
    final updatedList = state.tenants.where((t) => t.id != tenantId).toList();
    state = state.copyWith(tenants: updatedList);
    _recalculateKpis();

    // 2. Sync with backend API
    if (_apiService != null) {
      try {
        await _apiService.deleteOrganization(tenantId);
      } catch (_) {
        // Retain optimistic state
      }
    }
  }

  Future<Map<String, dynamic>?> impersonateTenant(String tenantId) async {
    if (_apiService != null) {
      try {
        return await _apiService.impersonateTenant(tenantId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void approveOnboardingRequest(String requestId) {
    final req = state.onboardingRequests.firstWhere((r) => r.id == requestId);
    
    // Create new organization tenant from approved request
    final newTenant = OrganizationTenant(
      id: 'org_${DateTime.now().millisecondsSinceEpoch}',
      name: req.organizationName,
      code: req.organizationName.replaceAll(RegExp(r'\s+'), '').toUpperCase().substring(0, 4),
      domain: '${req.organizationName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.platform-erp.in',
      gstin: req.gstin,
      contactPerson: req.adminName,
      contactEmail: req.adminEmail,
      contactPhone: req.adminPhone,
      planId: req.requestedPlanId,
      planName: req.requestedPlanName,
      status: TenantStatus.active,
      monthlySpend: req.requestedPlanName == 'Enterprise' ? 6999.0 : (req.requestedPlanName == 'Growth' ? 2499.0 : 999.0),
      totalInvoices: 0,
      activeUsersCount: 1,
      maxUsersLimit: req.requestedPlanName == 'Enterprise' ? 100 : (req.requestedPlanName == 'Growth' ? 15 : 3),
      storageUsedGb: 0.1,
      storageLimitGb: req.requestedPlanName == 'Enterprise' ? 100.0 : (req.requestedPlanName == 'Growth' ? 25.0 : 5.0),
      createdAt: DateTime.now(),
      renewalDate: DateTime.now().add(const Duration(days: 30)),
    );

    final updatedRequests = state.onboardingRequests.where((r) => r.id != requestId).toList();
    final updatedTenants = [newTenant, ...state.tenants];

    state = state.copyWith(
      onboardingRequests: updatedRequests,
      tenants: updatedTenants,
    );

    _recalculateKpis();
  }

  void submitOnboardingRequest(OnboardingRequest req) {
    final updatedRequests = [req, ...state.onboardingRequests];
    state = state.copyWith(onboardingRequests: updatedRequests);
    _recalculateKpis();
  }

  void _recalculateKpis() {
    final total = state.tenants.length;
    final active = state.tenants.where((t) => t.status == TenantStatus.active).length;
    final trial = state.tenants.where((t) => t.status == TenantStatus.trial).length;
    final totalMrr = state.tenants
        .where((t) => t.status == TenantStatus.active)
        .fold(0.0, (sum, t) => sum + t.monthlySpend);
    final totalUsers = state.tenants.fold(0, (sum, t) => sum + t.activeUsersCount);

    state = state.copyWith(
      kpis: PlatformKPIs(
        totalMrr: totalMrr,
        totalArr: totalMrr * 12,
        mrrGrowthPercentage: 18.4,
        totalTenants: total,
        activeTenants: active,
        trialTenants: trial,
        totalUsers: totalUsers,
        systemUptimePercentage: 99.98,
        serverLatencyMs: 38,
        pendingOnboardings: state.onboardingRequests.length,
      ),
    );
  }

  // --- Initial Mock Data ---
  static final List<OrganizationTenant> _initialTenants = [
    OrganizationTenant(
      id: 'org_001',
      name: 'Acme Global Enterprises',
      code: 'ACME',
      domain: 'acme.billing-erp.in',
      gstin: '27AABCU9603R1ZM',
      contactPerson: 'Rahul Sharma',
      contactEmail: 'rahul@acmeglobal.in',
      contactPhone: '+91 98201 44552',
      planId: 'plan_ent',
      planName: 'Enterprise',
      status: TenantStatus.active,
      monthlySpend: 6999.00,
      totalInvoices: 4820,
      activeUsersCount: 28,
      maxUsersLimit: 100,
      storageUsedGb: 14.5,
      storageLimitGb: 100.0,
      createdAt: DateTime.now().subtract(const Duration(days: 280)),
      renewalDate: DateTime.now().add(const Duration(days: 14)),
    ),
    OrganizationTenant(
      id: 'org_002',
      name: 'Vortex Retail Chain',
      code: 'VRTX',
      domain: 'vortex.billing-erp.in',
      gstin: '29AABCV4421P1Z9',
      contactPerson: 'Priya Sundaram',
      contactEmail: 'priya@vortexretail.com',
      contactPhone: '+91 94481 99231',
      planId: 'plan_growth',
      planName: 'Growth',
      status: TenantStatus.active,
      monthlySpend: 2499.00,
      totalInvoices: 1840,
      activeUsersCount: 8,
      maxUsersLimit: 15,
      storageUsedGb: 6.2,
      storageLimitGb: 25.0,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      renewalDate: DateTime.now().add(const Duration(days: 22)),
    ),
    OrganizationTenant(
      id: 'org_003',
      name: 'Zenith Logistics Hub',
      code: 'ZNTH',
      domain: 'zenith.billing-erp.in',
      gstin: '24AAACZ1189Q1ZA',
      contactPerson: 'Vikram Mehta',
      contactEmail: 'vikram@zenithlog.com',
      contactPhone: '+91 98980 12345',
      planId: 'plan_ent',
      planName: 'Enterprise',
      status: TenantStatus.active,
      monthlySpend: 6999.00,
      totalInvoices: 8910,
      activeUsersCount: 45,
      maxUsersLimit: 100,
      storageUsedGb: 32.8,
      storageLimitGb: 100.0,
      createdAt: DateTime.now().subtract(const Duration(days: 410)),
      renewalDate: DateTime.now().add(const Duration(days: 6)),
    ),
    OrganizationTenant(
      id: 'org_004',
      name: 'BlueSky Cloud Services',
      code: 'BSKY',
      domain: 'bluesky.billing-erp.in',
      gstin: '33AABCB7720K1ZX',
      contactPerson: 'Kavita Menon',
      contactEmail: 'kavita@blueskycloud.in',
      contactPhone: '+91 97451 88220',
      planId: 'plan_growth',
      planName: 'Growth',
      status: TenantStatus.trial,
      monthlySpend: 0.00,
      totalInvoices: 120,
      activeUsersCount: 3,
      maxUsersLimit: 15,
      storageUsedGb: 0.8,
      storageLimitGb: 25.0,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      renewalDate: DateTime.now().add(const Duration(days: 7)),
    ),
    OrganizationTenant(
      id: 'org_005',
      name: 'Apex FMCG Distributors',
      code: 'APEX',
      domain: 'apexfmcg.billing-erp.in',
      gstin: '07AAACA9921E1Z3',
      contactPerson: 'Anil Kapoor',
      contactEmail: 'anil@apexfmcg.com',
      contactPhone: '+91 99110 44331',
      planId: 'plan_starter',
      planName: 'Starter',
      status: TenantStatus.active,
      monthlySpend: 999.00,
      totalInvoices: 640,
      activeUsersCount: 2,
      maxUsersLimit: 3,
      storageUsedGb: 1.4,
      storageLimitGb: 5.0,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      renewalDate: DateTime.now().add(const Duration(days: 18)),
    ),
    OrganizationTenant(
      id: 'org_006',
      name: 'Nova Pharma Solutions',
      code: 'NOVA',
      domain: 'novapharma.billing-erp.in',
      gstin: '36AAACN5512L1ZP',
      contactPerson: 'Dr. Sanjay Rao',
      contactEmail: 'sanjay@novapharma.in',
      contactPhone: '+91 98490 66778',
      planId: 'plan_starter',
      planName: 'Starter',
      status: TenantStatus.suspended,
      monthlySpend: 0.00,
      totalInvoices: 310,
      activeUsersCount: 1,
      maxUsersLimit: 3,
      storageUsedGb: 2.1,
      storageLimitGb: 5.0,
      createdAt: DateTime.now().subtract(const Duration(days: 190)),
      renewalDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
    OrganizationTenant(
      id: 'org_007',
      name: 'Evergreen Organic Foods',
      code: 'EVRG',
      domain: 'evergreen.billing-erp.in',
      gstin: '19AABCE8841M1ZK',
      contactPerson: 'Ritu Sen',
      contactEmail: 'ritu@evergreenfoods.in',
      contactPhone: '+91 98300 22114',
      planId: 'plan_growth',
      planName: 'Growth',
      status: TenantStatus.active,
      monthlySpend: 2499.00,
      totalInvoices: 2150,
      activeUsersCount: 7,
      maxUsersLimit: 15,
      storageUsedGb: 5.8,
      storageLimitGb: 25.0,
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      renewalDate: DateTime.now().add(const Duration(days: 28)),
    ),
  ];

  static final List<PlatformPlan> _initialPlans = [
    const PlatformPlan(
      id: 'plan_starter',
      name: 'Starter',
      tagline: 'Ideal for small retail businesses, startups and standalone stores.',
      priceMonthly: 999.00,
      priceYearly: 9990.00,
      maxUsers: 3,
      maxInvoicesPerMonth: 500,
      storageLimitGb: 5.0,
      features: [
        'Up to 3 Team Members',
        '500 GST Invoices / Month',
        'Basic Inventory & Barcode Scan',
        'Standard Email Invoices',
        '5 GB Cloud Storage',
        'Standard Support (24h SLA)',
      ],
      activeTenantsCount: 42,
      themeColor: Color(0xFF2563EB),
    ),
    const PlatformPlan(
      id: 'plan_growth',
      name: 'Growth',
      tagline: 'Best for scaling wholesalers, multi-location shops, and expanding businesses.',
      priceMonthly: 2499.00,
      priceYearly: 24990.00,
      maxUsers: 15,
      maxInvoicesPerMonth: 5000,
      storageLimitGb: 25.0,
      isPopular: true,
      features: [
        'Up to 15 Team Members',
        '5,000 Invoices / Month',
        'Multi-Warehouse Inventory',
        'Double-Entry Accounting & Ledger',
        'Automated GSTR-1 & 3B Filing Portal',
        '25 GB Cloud Storage',
        'Priority Phone & Chat Support (4h SLA)',
      ],
      activeTenantsCount: 68,
      themeColor: Color(0xFF15803D),
    ),
    const PlatformPlan(
      id: 'plan_ent',
      name: 'Enterprise',
      tagline: 'Complete ERP suite with custom domain, unlimited scale & manufacturing.',
      priceMonthly: 6999.00,
      priceYearly: 69990.00,
      maxUsers: 100,
      maxInvoicesPerMonth: 50000,
      storageLimitGb: 100.0,
      features: [
        'Up to 100 Team Members',
        'Unlimited Invoices & Transactions',
        'Manufacturing, BOM & Job Work',
        'Custom Subdomain / White-labeling',
        'Advanced RBAC & Audit Trails',
        '100 GB High-Speed Storage',
        'Dedicated Account Manager (1h SLA)',
        'Automated Daily Offsite Backups',
      ],
      activeTenantsCount: 38,
      themeColor: Color(0xFF6D28D9),
    ),
  ];

  static final List<OnboardingRequest> _initialOnboardingRequests = [
    OnboardingRequest(
      id: 'req_101',
      organizationName: 'Metro Hardware & Electricals',
      gstin: '27AABCM3391K1ZX',
      adminName: 'Sunil Patil',
      adminEmail: 'sunil@metrohardware.in',
      adminPhone: '+91 98220 11990',
      requestedPlanId: 'plan_growth',
      requestedPlanName: 'Growth',
      businessType: 'Wholesale & Retail',
      state: 'Maharashtra',
      status: TenantStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    OnboardingRequest(
      id: 'req_102',
      organizationName: 'Shree Krishna Textiles',
      gstin: '24AABCS8891J1ZT',
      adminName: 'Mahesh Shah',
      adminEmail: 'mahesh@krishnatextiles.com',
      adminPhone: '+91 98790 44221',
      requestedPlanId: 'plan_ent',
      requestedPlanName: 'Enterprise',
      businessType: 'Textile Manufacturing',
      state: 'Gujarat',
      status: TenantStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    OnboardingRequest(
      id: 'req_103',
      organizationName: 'Arogya Ayurvedic Care',
      gstin: '32AABCA4412P1ZQ',
      adminName: 'Dr. Geetha Nair',
      adminEmail: 'geetha@arogyacare.in',
      adminPhone: '+91 94470 33881',
      requestedPlanId: 'plan_starter',
      requestedPlanName: 'Starter',
      businessType: 'Healthcare & Retail',
      state: 'Kerala',
      status: TenantStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}

final platformAdminApiServiceProvider = Provider<PlatformAdminApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlatformAdminApiService(apiClient);
});

final platformAdminProvider =
    StateNotifierProvider<PlatformAdminNotifier, PlatformAdminState>((ref) {
  final apiService = ref.watch(platformAdminApiServiceProvider);
  return PlatformAdminNotifier(apiService);
});
