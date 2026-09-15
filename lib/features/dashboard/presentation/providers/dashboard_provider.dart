import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/services/dashboard_api_service.dart';

class DashboardState {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DashboardOverviewData? overview;
  final String selectedPeriod;

  const DashboardState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.overview,
    this.selectedPeriod = 'this_year',
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    DashboardOverviewData? overview,
    String? selectedPeriod,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      overview: overview ?? this.overview,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardApiService _apiService;
  final Ref _ref;

  DashboardNotifier(this._apiService, this._ref)
      : super(const DashboardState(isLoading: true)) {
    loadOverview();
  }

  String? get _businessId {
    try {
      final biz = _ref.read(businessProvider).activeBusiness;
      return biz?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadOverview({
    bool refresh = false,
    String? period,
  }) async {
    final activePeriod = period ?? state.selectedPeriod;

    if (refresh) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else if (state.overview == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final overview = await _apiService.getOverview(
        period: activePeriod,
        refresh: refresh,
        businessId: _businessId,
      );

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        overview: overview,
        selectedPeriod: activePeriod,
        clearError: true,
      );
    } catch (e) {
      // Graceful fallback to cached state if network request fails
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> changeTrendPeriod(String periodKey) async {
    state = state.copyWith(selectedPeriod: periodKey);
    await loadOverview(period: periodKey);
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiService = ref.watch(dashboardApiServiceProvider);
  return DashboardNotifier(apiService, ref);
});
