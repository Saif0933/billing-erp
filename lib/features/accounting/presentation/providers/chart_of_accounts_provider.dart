import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chart_of_accounts_dto.dart';
import '../../data/services/chart_of_accounts_api_service.dart';

// Re-export DTO models for convenience across all UI widgets
export '../../data/models/chart_of_accounts_dto.dart';

// Backward compatibility typedefs
typedef CoaAccountItem = CoaAccountItemDto;
typedef CoaSummaryData = CoaSummaryDataDto;

/// State for Chart of Accounts feature
class ChartOfAccountsState {
  final bool isLoading;
  final String? error;
  final CoaSummaryDataDto data;
  final String searchQuery;
  final String selectedCategory;
  final Set<String> expandedGroupCodes;
  final bool showZeroBalances;
  final String sortBy;
  final List<Map<String, dynamic>> parentGroups;

  const ChartOfAccountsState({
    this.isLoading = false,
    this.error,
    this.data = const CoaSummaryDataDto(),
    this.searchQuery = '',
    this.selectedCategory = 'All Accounts',
    this.expandedGroupCodes = const {'1000', '2000', '3000', '4000', '5000', '6000'},
    this.showZeroBalances = true,
    this.sortBy = 'Code (Ascending)',
    this.parentGroups = const [],
  });

  ChartOfAccountsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    CoaSummaryDataDto? data,
    String? searchQuery,
    String? selectedCategory,
    Set<String>? expandedGroupCodes,
    bool? showZeroBalances,
    String? sortBy,
    List<Map<String, dynamic>>? parentGroups,
  }) {
    return ChartOfAccountsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      expandedGroupCodes: expandedGroupCodes ?? this.expandedGroupCodes,
      showZeroBalances: showZeroBalances ?? this.showZeroBalances,
      sortBy: sortBy ?? this.sortBy,
      parentGroups: parentGroups ?? this.parentGroups,
    );
  }
}

/// StateNotifier managing Chart of Accounts state & API interactions
class ChartOfAccountsNotifier extends StateNotifier<ChartOfAccountsState> {
  final ChartOfAccountsApiService _apiService;
  Timer? _debounceTimer;

  ChartOfAccountsNotifier(this._apiService) : super(const ChartOfAccountsState()) {
    fetchChartOfAccounts();
    fetchAccountGroups();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Map UI category label to backend query string
  String? _mapCategory(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'assets':
      case 'asset':
        return 'asset';
      case 'liabilities':
      case 'liability':
        return 'liability';
      case 'equity':
        return 'equity';
      case 'income':
        return 'income';
      case 'expenses':
      case 'expense':
        return 'expense';
      default:
        return null;
    }
  }

  /// Fetch accounts tree and KPI summary from backend
  Future<void> fetchChartOfAccounts({bool isRefresh = false}) async {
    if (!isRefresh && state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final backendCategory = _mapCategory(state.selectedCategory);
      final result = await _apiService.getChartOfAccounts(
        category: backendCategory,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        showZeroBalances: state.showZeroBalances,
        sortBy: state.sortBy,
      );

      // Collect top-level codes to ensure primary groups are expanded by default
      final updatedExpanded = Set<String>.from(state.expandedGroupCodes);
      if (updatedExpanded.isEmpty) {
        for (final item in result.displayedGroups) {
          updatedExpanded.add(item.code);
        }
      }

      state = state.copyWith(
        isLoading: false,
        data: result,
        expandedGroupCodes: updatedExpanded,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch account groups for parent dropdown selection
  Future<void> fetchAccountGroups() async {
    try {
      final groups = await _apiService.getAccountGroups();
      state = state.copyWith(parentGroups: groups);
    } catch (_) {
      // Non-critical, fallback will use displayed groups
    }
  }

  /// Set search query with 350ms debounce
  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchChartOfAccounts();
    });
  }

  /// Change active category tab
  void setSelectedCategory(String cat) {
    if (state.selectedCategory == cat) return;
    state = state.copyWith(selectedCategory: cat);
    fetchChartOfAccounts();
  }

  /// Toggle group collapse/expand
  void toggleGroupExpansion(String code) {
    final next = Set<String>.from(state.expandedGroupCodes);
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    state = state.copyWith(expandedGroupCodes: next);
  }

  /// Expand all groups
  void expandAll() {
    final allCodes = <String>{};
    void collect(List<CoaAccountItemDto> items) {
      for (final item in items) {
        if (item.isGroup || item.children.isNotEmpty) {
          allCodes.add(item.code);
          collect(item.children);
        }
      }
    }
    collect(state.data.displayedGroups);
    state = state.copyWith(expandedGroupCodes: allCodes);
  }

  /// Collapse all groups
  void collapseAll() {
    state = state.copyWith(expandedGroupCodes: {});
  }

  /// Toggle showing zero balance accounts
  void setShowZeroBalances(bool val) {
    if (state.showZeroBalances == val) return;
    state = state.copyWith(showZeroBalances: val);
    fetchChartOfAccounts();
  }

  /// Change sort order
  void setSortBy(String sort) {
    if (state.sortBy == sort) return;
    state = state.copyWith(sortBy: sort);
    fetchChartOfAccounts();
  }

  /// Create a new account
  Future<bool> createAccount(CreateCoaAccountDto dto) async {
    try {
      await _apiService.createAccount(dto);
      await fetchChartOfAccounts(isRefresh: true);
      await fetchAccountGroups();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete an account
  Future<bool> deleteAccount(String id) async {
    try {
      final success = await _apiService.deleteAccount(id);
      if (success) {
        await fetchChartOfAccounts(isRefresh: true);
        await fetchAccountGroups();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Primary StateNotifierProvider for Chart of Accounts
final chartOfAccountsNotifierProvider =
    StateNotifierProvider<ChartOfAccountsNotifier, ChartOfAccountsState>((ref) {
  final apiService = ref.watch(chartOfAccountsApiServiceProvider);
  return ChartOfAccountsNotifier(apiService);
});

/// Alias filter provider for seamless backward compatibility with existing toolbar/tab widgets
final coaFilterProvider = chartOfAccountsNotifierProvider;

/// Data provider delivering dynamic summary metrics and tree items
final coaDataProvider = Provider<CoaSummaryDataDto>((ref) {
  final state = ref.watch(chartOfAccountsNotifierProvider);
  return state.data;
});
