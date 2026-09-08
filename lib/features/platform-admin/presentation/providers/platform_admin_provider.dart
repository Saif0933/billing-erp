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
  final bool hasLoaded;
  final String? errorMessage;
  final bool isPlansLoading;
  final bool hasPlansLoaded;
  final String? plansErrorMessage;

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
    this.hasLoaded = false,
    this.errorMessage,
    this.isPlansLoading = false,
    this.hasPlansLoaded = false,
    this.plansErrorMessage,
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
    bool? hasLoaded,
    String? errorMessage,
    bool? isPlansLoading,
    bool? hasPlansLoaded,
    String? plansErrorMessage,
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
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: errorMessage,
      isPlansLoading: isPlansLoading ?? this.isPlansLoading,
      hasPlansLoaded: hasPlansLoaded ?? this.hasPlansLoaded,
      plansErrorMessage: plansErrorMessage,
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
            tenants: const [],
            plans: const [],
            onboardingRequests: _initialOnboardingRequests,
            isLoading: true,
            isPlansLoading: true,
            kpis: const PlatformKPIs(
              totalMrr: 0.0,
              totalArr: 0.0,
              mrrGrowthPercentage: 0.0,
              totalTenants: 0,
              activeTenants: 0,
              trialTenants: 0,
              totalUsers: 0,
              systemUptimePercentage: 99.98,
              serverLatencyMs: 38,
              pendingOnboardings: 0,
            ),
          ),
        ) {
    loadOrganizations();
    loadPlans();
  }

  /// Load plans from backend API
  Future<void> loadPlans() async {
    if (_apiService == null) return;
    try {
      state = state.copyWith(isPlansLoading: true, plansErrorMessage: null);
      final plans = await _apiService.getPlans();
      state = state.copyWith(
        plans: plans,
        isPlansLoading: false,
        hasPlansLoaded: true,
      );
    } catch (e) {
      state = state.copyWith(
        isPlansLoading: false,
        hasPlansLoaded: true,
        plansErrorMessage: e.toString(),
      );
    }
  }

  /// Create new SaaS subscription plan
  Future<void> createPlan(PlatformPlan plan) async {
    // 1. Optimistic update
    final updatedList = [...state.plans, plan];
    state = state.copyWith(plans: updatedList);

    // 2. Sync with backend API
    if (_apiService != null) {
      try {
        final serverPlan = await _apiService.createPlan(plan);
        final syncedList = state.plans.map((p) => p.id == plan.id ? serverPlan : p).toList();
        state = state.copyWith(plans: syncedList);
      } catch (_) {
        // Retain optimistic state
      }
    }
  }

  /// Update existing SaaS subscription plan
  Future<void> updatePlan(PlatformPlan plan) async {
    // 1. Optimistic update
    final updatedList = state.plans.map((p) => p.id == plan.id ? plan : p).toList();
    state = state.copyWith(plans: updatedList);

    // 2. Sync with backend API
    if (_apiService != null) {
      try {
        final serverPlan = await _apiService.updatePlan(plan);
        final syncedList = state.plans.map((p) => p.id == plan.id ? serverPlan : p).toList();
        state = state.copyWith(plans: syncedList);
      } catch (_) {
        // Retain optimistic state
      }
    }
  }

  /// Delete SaaS subscription plan
  Future<void> deletePlan(String planId) async {
    // 1. Optimistic update
    final updatedList = state.plans.where((p) => p.id != planId).toList();
    state = state.copyWith(plans: updatedList);

    // 2. Sync with backend API
    if (_apiService != null) {
      try {
        await _apiService.deletePlan(planId);
      } catch (_) {
        // Retain optimistic state
      }
    }
  }

  /// Load organizations directory and KPIs from backend REST API
  Future<void> loadOrganizations() async {
    if (_apiService == null) return;
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final res = await _apiService.getOrganizations();

      state = state.copyWith(
        tenants: res.tenants,
        kpis: res.kpis ?? state.kpis,
        isLoading: false,
        hasLoaded: true,
      );
      if (res.kpis == null) {
        _recalculateKpis();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: e.toString(),
      );
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

  // --- Initial Mock Requests ---

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
