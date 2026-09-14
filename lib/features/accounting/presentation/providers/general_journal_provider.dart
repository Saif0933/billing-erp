import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/journal_entries_dto.dart';
import '../../data/services/journal_entries_api_service.dart';

// Re-export models for convenience across all UI widgets
export '../../data/models/journal_entries_dto.dart';

// Backward compatibility typedefs
typedef JournalEntryRowItem = JournalEntryItemDto;
typedef GeneralJournalSummaryData = GeneralJournalSummaryResponseDto;

/// State for General Journal feature
class GeneralJournalState {
  final bool isLoading;
  final String? error;
  final GeneralJournalSummaryResponseDto data;
  final String searchQuery;
  final String selectedTab; // 'Journal List', 'Drafts', 'Recurring Journals', 'Journal Templates'
  final String dateRangeLabel;
  final DateTimeRange? customDateRange;
  final String selectedType; // 'All Types', 'Standard', 'Adjustment', 'Recurring', 'Template'
  final String selectedStatus; // 'All Status', 'Posted', 'Draft', 'Voided'
  final String sortBy;
  final int rowsPerPage;
  final int currentPage;
  final List<AccountDropdownItemDto> availableAccounts;

  const GeneralJournalState({
    this.isLoading = false,
    this.error,
    this.data = const GeneralJournalSummaryResponseDto(),
    this.searchQuery = '',
    this.selectedTab = 'Journal List',
    this.dateRangeLabel = 'All Time',
    this.customDateRange,
    this.selectedType = 'All Types',
    this.selectedStatus = 'All Status',
    this.sortBy = 'Date (Newest)',
    this.rowsPerPage = 10,
    this.currentPage = 1,
    this.availableAccounts = const [],
  });

  GeneralJournalState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    GeneralJournalSummaryResponseDto? data,
    String? searchQuery,
    String? selectedTab,
    String? dateRangeLabel,
    DateTimeRange? customDateRange,
    bool clearDateRange = false,
    String? selectedType,
    String? selectedStatus,
    String? sortBy,
    int? rowsPerPage,
    int? currentPage,
    List<AccountDropdownItemDto>? availableAccounts,
  }) {
    return GeneralJournalState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTab: selectedTab ?? this.selectedTab,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      customDateRange: clearDateRange ? null : (customDateRange ?? this.customDateRange),
      selectedType: selectedType ?? this.selectedType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      currentPage: currentPage ?? this.currentPage,
      availableAccounts: availableAccounts ?? this.availableAccounts,
    );
  }
}

/// StateNotifier managing General Journal state & API queries
class GeneralJournalNotifier extends StateNotifier<GeneralJournalState> {
  final JournalEntriesApiService _apiService;
  Timer? _debounceTimer;

  GeneralJournalNotifier(this._apiService) : super(const GeneralJournalState()) {
    fetchJournalEntries();
    fetchAccounts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 1. Fetch Journal entries & 4 KPI metrics from backend API
  Future<void> fetchJournalEntries({bool isRefresh = false}) async {
    if (!isRefresh && state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiService.getJournalEntries(
        tab: state.selectedTab,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        type: state.selectedType,
        status: state.selectedStatus,
        startDate: state.customDateRange?.start,
        endDate: state.customDateRange?.end,
        sortBy: state.sortBy,
        page: state.currentPage,
        limit: state.rowsPerPage,
      );

      state = state.copyWith(
        isLoading: false,
        data: response,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 2. Fetch Chart of Accounts for dropdown selection
  Future<void> fetchAccounts() async {
    try {
      final accounts = await _apiService.getAccounts();
      state = state.copyWith(availableAccounts: accounts);
    } catch (_) {
      // Fallback is handled gracefully
    }
  }

  /// 3. Debounced Search (350ms)
  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q, currentPage: 1);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchJournalEntries();
    });
  }

  /// 4. Category Tab filter
  void setSelectedTab(String tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab, currentPage: 1);
    fetchJournalEntries();
  }

  /// 5. Date Range filter
  void setDateRange(String label, DateTimeRange? range) {
    state = state.copyWith(
      dateRangeLabel: label,
      customDateRange: range,
      clearDateRange: range == null,
      currentPage: 1,
    );
    fetchJournalEntries();
  }

  /// 6. Journal Type filter
  void setSelectedType(String t) {
    if (state.selectedType == t) return;
    state = state.copyWith(selectedType: t, currentPage: 1);
    fetchJournalEntries();
  }

  /// 7. Journal Status filter
  void setSelectedStatus(String s) {
    if (state.selectedStatus == s) return;
    state = state.copyWith(selectedStatus: s, currentPage: 1);
    fetchJournalEntries();
  }

  /// 8. Sorting
  void setSortBy(String sort) {
    if (state.sortBy == sort) return;
    state = state.copyWith(sortBy: sort);
    fetchJournalEntries();
  }

  /// 9. Rows per page
  void setRowsPerPage(int count) {
    if (state.rowsPerPage == count) return;
    state = state.copyWith(rowsPerPage: count, currentPage: 1);
    fetchJournalEntries();
  }

  /// 10. Page change
  void setPage(int page) {
    if (state.currentPage == page) return;
    state = state.copyWith(currentPage: page);
    fetchJournalEntries();
  }

  /// 11. Reset all filters
  void reset() {
    state = state.copyWith(
      searchQuery: '',
      selectedTab: 'Journal List',
      dateRangeLabel: 'All Time',
      clearDateRange: true,
      selectedType: 'All Types',
      selectedStatus: 'All Status',
      sortBy: 'Date (Newest)',
      rowsPerPage: 10,
      currentPage: 1,
    );
    fetchJournalEntries();
  }

  /// 12. Create Journal Entry
  Future<bool> createJournalEntry(CreateJournalEntryDto dto) async {
    try {
      await _apiService.createJournalEntry(dto);
      await fetchJournalEntries(isRefresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 13. Void Journal Entry
  Future<bool> voidJournalEntry(String id) async {
    try {
      final success = await _apiService.voidJournalEntry(id);
      if (success) {
        await fetchJournalEntries(isRefresh: true);
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 14. Delete Journal Entry
  Future<bool> deleteJournalEntry(String id) async {
    try {
      final success = await _apiService.deleteJournalEntry(id);
      if (success) {
        await fetchJournalEntries(isRefresh: true);
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 15. Export Journal Book
  Future<Map<String, dynamic>> exportJournals({String format = 'csv'}) async {
    return await _apiService.exportJournals(
      format: format,
      tab: state.selectedTab,
      search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      type: state.selectedType,
      status: state.selectedStatus,
      startDate: state.customDateRange?.start,
      endDate: state.customDateRange?.end,
      sortBy: state.sortBy,
    );
  }
}

/// Primary StateNotifierProvider for General Journal
final generalJournalNotifierProvider =
    StateNotifierProvider<GeneralJournalNotifier, GeneralJournalState>((ref) {
  final apiService = ref.watch(journalEntriesApiServiceProvider);
  return GeneralJournalNotifier(apiService);
});

/// Alias filter provider for seamless backward compatibility with existing toolbar/tabs/table widgets
final journalFilterProvider = generalJournalNotifierProvider;

/// Data provider delivering dynamic summary metrics and table items
final generalJournalDataProvider = Provider<GeneralJournalSummaryResponseDto>((ref) {
  final state = ref.watch(generalJournalNotifierProvider);
  return state.data;
});
