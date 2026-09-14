import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_account_dto.dart';
import '../../data/services/bank_account_api_service.dart';

// Re-export DTO models for seamless usage
export '../../data/models/bank_account_dto.dart'
    show
        BankAccountCategory,
        BankAccountItemDto,
        BankTransactionItemDto,
        BankShareSegmentDto,
        BankAccountsResponseDto,
        CreateBankAccountDto;

// Backward-compatibility typedefs
typedef BankAccountItem = BankAccountItemDto;
typedef BankTransactionItem = BankTransactionItemDto;
typedef BankShareSegment = BankShareSegmentDto;

/// Filter state for Bank Accounts screen
class BankFilterState {
  final String searchQuery;
  final String selectedTab; // 'All Accounts', 'Current Accounts', 'Savings Accounts', 'Credit Accounts', 'Inactive Accounts'
  final String sortBy;
  final int rowsPerPage;
  final int currentPage;

  const BankFilterState({
    this.searchQuery = '',
    this.selectedTab = 'All Accounts',
    this.sortBy = 'Balance (High to Low)',
    this.rowsPerPage = 10,
    this.currentPage = 1,
  });

  BankFilterState copyWith({
    String? searchQuery,
    String? selectedTab,
    String? sortBy,
    int? rowsPerPage,
    int? currentPage,
  }) {
    return BankFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTab: selectedTab ?? this.selectedTab,
      sortBy: sortBy ?? this.sortBy,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class BankFilterNotifier extends StateNotifier<BankFilterState> {
  BankFilterNotifier() : super(const BankFilterState());

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q, currentPage: 1);
  void setSelectedTab(String tab) => state = state.copyWith(selectedTab: tab, currentPage: 1);
  void setSortBy(String s) => state = state.copyWith(sortBy: s);
  void setRowsPerPage(int r) => state = state.copyWith(rowsPerPage: r, currentPage: 1);
  void setPage(int p) => state = state.copyWith(currentPage: p);
  void reset() => state = const BankFilterState();
}

final bankFilterProvider = StateNotifierProvider<BankFilterNotifier, BankFilterState>((ref) {
  return BankFilterNotifier();
});

/// StateNotifier that connects the Bank Accounts module to backend API
class BankAccountsNotifier extends StateNotifier<AsyncValue<BankAccountsResponseDto>> {
  final BankAccountApiService _apiService;
  final Ref _ref;
  Timer? _debounceTimer;

  BankAccountsNotifier(this._apiService, this._ref) : super(const AsyncValue.loading()) {
    // Listen to filter changes and re-fetch with debounced search
    _ref.listen<BankFilterState>(bankFilterProvider, (prev, next) {
      if (prev?.searchQuery != next.searchQuery) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          fetchBankAccounts();
        });
      } else if (prev?.selectedTab != next.selectedTab ||
          prev?.sortBy != next.sortBy ||
          prev?.rowsPerPage != next.rowsPerPage ||
          prev?.currentPage != next.currentPage) {
        fetchBankAccounts();
      }
    });

    fetchBankAccounts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Fetch accounts with active filter state
  Future<void> fetchBankAccounts({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }

    try {
      final filter = _ref.read(bankFilterProvider);
      final response = await _apiService.getBankAccounts(
        tab: filter.selectedTab,
        search: filter.searchQuery,
        sortBy: filter.sortBy,
        page: filter.currentPage,
        limit: filter.rowsPerPage,
      );

      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh accounts silently
  Future<void> refresh() async {
    await fetchBankAccounts(showLoading: false);
  }

  /// Go to specific page
  void goToPage(int page) {
    _ref.read(bankFilterProvider.notifier).setPage(page);
  }

  /// Create a new bank account
  Future<BankAccountItemDto> createAccount(CreateBankAccountDto dto) async {
    final result = await _apiService.createBankAccount(dto);
    await refresh();
    return result;
  }

  /// Update an existing bank account
  Future<BankAccountItemDto> updateAccount(String id, Map<String, dynamic> data) async {
    final result = await _apiService.updateBankAccount(id, data);
    await refresh();
    return result;
  }

  /// Delete a bank account
  Future<bool> deleteAccount(String id) async {
    final success = await _apiService.deleteBankAccount(id);
    if (success) {
      await refresh();
    }
    return success;
  }

  /// Toggle Active / Inactive status of a bank account
  Future<BankAccountItemDto> toggleStatus(String id) async {
    final result = await _apiService.toggleStatus(id);
    await refresh();
    return result;
  }

  /// Reconcile bank account
  Future<Map<String, dynamic>> reconcileAccount(
    String id, {
    double? statementBalance,
    String? statementDate,
    List<String>? transactionIds,
  }) async {
    final result = await _apiService.reconcileAccount(
      id,
      statementBalance: statementBalance,
      statementDate: statementDate,
      transactionIds: transactionIds,
    );
    await refresh();
    return result;
  }

  /// Export bank accounts to CSV
  Future<Map<String, dynamic>> exportBankAccounts() async {
    final filter = _ref.read(bankFilterProvider);
    return _apiService.exportBankAccounts(
      tab: filter.selectedTab,
      search: filter.searchQuery,
    );
  }
}

final bankAccountsNotifierProvider =
    StateNotifierProvider<BankAccountsNotifier, AsyncValue<BankAccountsResponseDto>>((ref) {
  final apiService = ref.watch(bankAccountApiServiceProvider);
  return BankAccountsNotifier(apiService, ref);
});

/// Data holder model for UI presentation with loading & error information
class BankSummaryData {
  final int totalAccounts;
  final double totalBalance;
  final double clearedBalance;
  final double unclearedBalance;
  final List<BankAccountItemDto> displayedAccounts;
  final List<BankTransactionItemDto> recentTransactions;
  final List<BankShareSegmentDto> balanceOverview;
  final int totalPages;
  final int currentPage;
  final int totalCount;
  final bool isLoading;
  final String? errorMessage;

  const BankSummaryData({
    required this.totalAccounts,
    required this.totalBalance,
    required this.clearedBalance,
    required this.unclearedBalance,
    required this.displayedAccounts,
    required this.recentTransactions,
    required this.balanceOverview,
    required this.totalPages,
    required this.currentPage,
    this.totalCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  factory BankSummaryData.loading() {
    return const BankSummaryData(
      totalAccounts: 0,
      totalBalance: 0.0,
      clearedBalance: 0.0,
      unclearedBalance: 0.0,
      displayedAccounts: [],
      recentTransactions: [],
      balanceOverview: [],
      totalPages: 1,
      currentPage: 1,
      totalCount: 0,
      isLoading: true,
    );
  }

  factory BankSummaryData.error(String message) {
    return BankSummaryData(
      totalAccounts: 0,
      totalBalance: 0.0,
      clearedBalance: 0.0,
      unclearedBalance: 0.0,
      displayedAccounts: [],
      recentTransactions: [],
      balanceOverview: [],
      totalPages: 1,
      currentPage: 1,
      totalCount: 0,
      isLoading: false,
      errorMessage: message,
    );
  }

  factory BankSummaryData.fromDto(BankAccountsResponseDto dto) {
    return BankSummaryData(
      totalAccounts: dto.totalAccounts,
      totalBalance: dto.totalBalance,
      clearedBalance: dto.clearedBalance,
      unclearedBalance: dto.unclearedBalance,
      displayedAccounts: dto.displayedAccounts,
      recentTransactions: dto.recentTransactions,
      balanceOverview: dto.balanceOverview,
      totalPages: dto.totalPages,
      currentPage: dto.currentPage,
      totalCount: dto.totalCount,
      isLoading: false,
    );
  }
}

/// Primary presentation provider consumed by Bank Accounts widgets
final bankDataProvider = Provider<BankSummaryData>((ref) {
  final asyncVal = ref.watch(bankAccountsNotifierProvider);

  return asyncVal.when(
    data: (dto) => BankSummaryData.fromDto(dto),
    loading: () => BankSummaryData.loading(),
    error: (err, _) => BankSummaryData.error(err.toString()),
  );
});
