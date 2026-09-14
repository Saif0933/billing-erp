import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/general_ledger_dto.dart';
import '../../data/services/general_ledger_api_service.dart';

/// Type alias for backward compatibility across all widgets
typedef LedgerItem = LedgerItemDto;

/// Filter State for General Ledger
class GeneralLedgerFilterState {
  final String searchQuery;
  final String selectedAccount;
  final String selectedVoucher;
  final String selectedType;
  final String dateRangeLabel;
  final DateTimeRange? customDateRange;
  final String sortBy;
  final int rowsPerPage;
  final int currentPage;

  const GeneralLedgerFilterState({
    this.searchQuery = '',
    this.selectedAccount = 'All Accounts',
    this.selectedVoucher = 'All Vouchers',
    this.selectedType = 'All Types',
    this.dateRangeLabel = 'This Month',
    this.customDateRange,
    this.sortBy = 'Date (Newest)',
    this.rowsPerPage = 10,
    this.currentPage = 1,
  });

  GeneralLedgerFilterState copyWith({
    String? searchQuery,
    String? selectedAccount,
    String? selectedVoucher,
    String? selectedType,
    String? dateRangeLabel,
    DateTimeRange? customDateRange,
    String? sortBy,
    int? rowsPerPage,
    int? currentPage,
    bool clearDateRange = false,
  }) {
    return GeneralLedgerFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedVoucher: selectedVoucher ?? this.selectedVoucher,
      selectedType: selectedType ?? this.selectedType,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      customDateRange: clearDateRange ? null : (customDateRange ?? this.customDateRange),
      sortBy: sortBy ?? this.sortBy,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Comprehensive State for General Ledger
class GeneralLedgerState {
  final GeneralLedgerFilterState filter;
  final GeneralLedgerSummaryDto summary;
  final SmartInsightsDto smartInsights;
  final List<LedgerItemDto> items;
  final List<String> availableAccounts;
  final List<String> availableVouchers;
  final GeneralLedgerPaginationDto pagination;
  final bool isLoading;
  final bool isExporting;
  final String? error;

  const GeneralLedgerState({
    this.filter = const GeneralLedgerFilterState(),
    this.summary = const GeneralLedgerSummaryDto(),
    this.smartInsights = const SmartInsightsDto(),
    this.items = const [],
    this.availableAccounts = const ['All Accounts'],
    this.availableVouchers = const ['All Vouchers'],
    this.pagination = const GeneralLedgerPaginationDto(),
    this.isLoading = false,
    this.isExporting = false,
    this.error,
  });

  factory GeneralLedgerState.initial() {
    return const GeneralLedgerState(
      filter: GeneralLedgerFilterState(),
      summary: GeneralLedgerSummaryDto(),
      smartInsights: SmartInsightsDto(),
      items: [],
      availableAccounts: ['All Accounts'],
      availableVouchers: ['All Vouchers'],
      pagination: GeneralLedgerPaginationDto(),
      isLoading: true,
      error: null,
    );
  }

  GeneralLedgerState copyWith({
    GeneralLedgerFilterState? filter,
    GeneralLedgerSummaryDto? summary,
    SmartInsightsDto? smartInsights,
    List<LedgerItemDto>? items,
    List<String>? availableAccounts,
    List<String>? availableVouchers,
    GeneralLedgerPaginationDto? pagination,
    bool? isLoading,
    bool? isExporting,
    String? error,
    bool clearError = false,
  }) {
    return GeneralLedgerState(
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
      smartInsights: smartInsights ?? this.smartInsights,
      items: items ?? this.items,
      availableAccounts: availableAccounts ?? this.availableAccounts,
      availableVouchers: availableVouchers ?? this.availableVouchers,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Delegated getters for filter state
  String get searchQuery => filter.searchQuery;
  String get selectedAccount => filter.selectedAccount;
  String get selectedVoucher => filter.selectedVoucher;
  String get selectedType => filter.selectedType;
  String get dateRangeLabel => filter.dateRangeLabel;
  DateTimeRange? get customDateRange => filter.customDateRange;
  String get sortBy => filter.sortBy;
  int get rowsPerPage => filter.rowsPerPage;
  int get currentPage => filter.currentPage;

  // Delegated getters for summary metrics
  double get totalDebit => summary.totalDebit;
  double get totalCredit => summary.totalCredit;
  double get closingBalance => summary.closingBalance;
  int get totalEntries => pagination.total > 0 ? pagination.total : summary.totalEntries;
  bool get isBalanced => summary.isBalanced;
  int get totalPages => pagination.totalPages;
  List<LedgerItemDto> get pagedItems => items;
}

/// Data summary wrapper for widgets watching generalLedgerDataProvider
class GeneralLedgerSummaryData {
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final int totalEntries;
  final bool isBalanced;
  final List<LedgerItemDto> pagedItems;
  final int totalPages;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final SmartInsightsDto smartInsights;
  final List<String> availableAccounts;
  final List<String> availableVouchers;

  const GeneralLedgerSummaryData({
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    required this.totalEntries,
    required this.isBalanced,
    required this.pagedItems,
    required this.totalPages,
    required this.currentPage,
    this.isLoading = false,
    this.error,
    this.smartInsights = const SmartInsightsDto(),
    this.availableAccounts = const ['All Accounts'],
    this.availableVouchers = const ['All Vouchers'],
  });
}

/// StateNotifier controlling General Ledger dynamic lifecycle
class GeneralLedgerNotifier extends StateNotifier<GeneralLedgerState> {
  final GeneralLedgerApiService _apiService;
  Timer? _debounceTimer;

  GeneralLedgerNotifier(this._apiService) : super(GeneralLedgerState.initial()) {
    loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load General Ledger live data from the backend API
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiService.getGeneralLedger(
        search: state.searchQuery,
        account: state.selectedAccount,
        voucherType: state.selectedVoucher,
        type: state.selectedType,
        startDate: state.customDateRange?.start,
        endDate: state.customDateRange?.end,
        sortBy: state.sortBy,
        page: state.currentPage,
        limit: state.rowsPerPage,
      );

      // Build available accounts list
      final accountsSet = <String>{'All Accounts'};
      if (response.accounts.isNotEmpty) {
        accountsSet.addAll(response.accounts);
      }
      for (final item in response.items) {
        if (item.account.isNotEmpty) {
          accountsSet.add(item.account);
        }
      }

      // Build available vouchers list
      final voucherSet = <String>{'All Vouchers'};
      if (response.voucherTypes.isNotEmpty) {
        voucherSet.addAll(response.voucherTypes);
      }
      for (final item in response.items) {
        if (item.voucherType.isNotEmpty) {
          voucherSet.add(item.voucherType);
        }
      }

      state = state.copyWith(
        isLoading: false,
        summary: response.summary,
        smartInsights: response.smartInsights,
        items: response.items,
        availableAccounts: accountsSet.toList(),
        availableVouchers: voucherSet.toList(),
        pagination: response.pagination,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search query with 400ms debounce
  void setSearchQuery(String q) {
    if (state.searchQuery == q) return;

    state = state.copyWith(
      filter: state.filter.copyWith(searchQuery: q, currentPage: 1),
    );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      loadData();
    });
  }

  /// Change account filter
  void setSelectedAccount(String acc) {
    if (state.selectedAccount == acc) return;
    state = state.copyWith(
      filter: state.filter.copyWith(selectedAccount: acc, currentPage: 1),
    );
    loadData();
  }

  /// Change voucher type filter
  void setSelectedVoucher(String v) {
    if (state.selectedVoucher == v) return;
    state = state.copyWith(
      filter: state.filter.copyWith(selectedVoucher: v, currentPage: 1),
    );
    loadData();
  }

  /// Change debit/credit type filter
  void setSelectedType(String t) {
    if (state.selectedType == t) return;
    state = state.copyWith(
      filter: state.filter.copyWith(selectedType: t, currentPage: 1),
    );
    loadData();
  }

  /// Change date range filter
  void setDateRange(String label, DateTimeRange? range) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        dateRangeLabel: label,
        customDateRange: range,
        currentPage: 1,
        clearDateRange: range == null,
      ),
    );
    loadData();
  }

  /// Change sorting
  void setSortBy(String sort) {
    if (state.sortBy == sort) return;
    state = state.copyWith(
      filter: state.filter.copyWith(sortBy: sort),
    );
    loadData();
  }

  /// Change rows per page
  void setRowsPerPage(int count) {
    if (state.rowsPerPage == count) return;
    state = state.copyWith(
      filter: state.filter.copyWith(rowsPerPage: count, currentPage: 1),
    );
    loadData();
  }

  /// Change current page
  void setPage(int page) {
    if (state.currentPage == page) return;
    state = state.copyWith(
      filter: state.filter.copyWith(currentPage: page),
    );
    loadData();
  }

  /// Manual pull-to-refresh
  Future<void> refresh() async {
    await loadData();
  }

  /// Export ledger data
  Future<Map<String, dynamic>?> exportLedger({String format = 'csv'}) async {
    state = state.copyWith(isExporting: true);
    try {
      final result = await _apiService.exportLedger(
        format: format,
        search: state.searchQuery,
        account: state.selectedAccount,
        voucherType: state.selectedVoucher,
        type: state.selectedType,
        startDate: state.customDateRange?.start,
        endDate: state.customDateRange?.end,
        sortBy: state.sortBy,
      );
      state = state.copyWith(isExporting: false);
      return result;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: 'Export failed: $e');
      return null;
    }
  }
}

/// Main StateNotifierProvider for General Ledger
final generalLedgerNotifierProvider =
    StateNotifierProvider<GeneralLedgerNotifier, GeneralLedgerState>((ref) {
  final apiService = ref.watch(generalLedgerApiServiceProvider);
  return GeneralLedgerNotifier(apiService);
});

/// Direct aliases for clean access
final generalLedgerProvider = generalLedgerNotifierProvider;
final generalLedgerFilterProvider = generalLedgerNotifierProvider;

/// Adapter provider for summary and table consumption
final generalLedgerDataProvider = Provider<GeneralLedgerSummaryData>((ref) {
  final state = ref.watch(generalLedgerNotifierProvider);

  return GeneralLedgerSummaryData(
    totalDebit: state.totalDebit,
    totalCredit: state.totalCredit,
    closingBalance: state.closingBalance,
    totalEntries: state.totalEntries,
    isBalanced: state.isBalanced,
    pagedItems: state.items,
    totalPages: state.totalPages,
    currentPage: state.currentPage,
    isLoading: state.isLoading,
    error: state.error,
    smartInsights: state.smartInsights,
    availableAccounts: state.availableAccounts,
    availableVouchers: state.availableVouchers,
  );
});
