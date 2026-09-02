import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum JournalType {
  standard,
  adjustment,
  recurring,
  template,
}

enum JournalEntryStatus {
  posted,
  draft,
  voided,
}

class JournalEntryRowItem {
  final String id;
  final String date;
  final String time;
  final DateTime dateTime;
  final String journalNo;
  final String journalTypeLabel;
  final JournalType type;
  final String reference;
  final String narration;
  final double debit;
  final double credit;
  final JournalEntryStatus status;

  const JournalEntryRowItem({
    required this.id,
    required this.date,
    required this.time,
    required this.dateTime,
    required this.journalNo,
    required this.journalTypeLabel,
    required this.type,
    required this.reference,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.status,
  });
}

class JournalFilterState {
  final String searchQuery;
  final String selectedTab; // 'Journal List', 'Drafts', 'Recurring Journals', 'Journal Templates'
  final String dateRangeLabel;
  final DateTimeRange? customDateRange;
  final String selectedType; // 'All Types', 'Standard', 'Adjustment', 'Recurring', 'Template'
  final String selectedStatus; // 'All Status', 'Posted', 'Draft', 'Voided'
  final String sortBy;
  final int rowsPerPage;
  final int currentPage;

  const JournalFilterState({
    this.searchQuery = '',
    this.selectedTab = 'Journal List',
    this.dateRangeLabel = '01 May – 31 May 2026',
    this.customDateRange,
    this.selectedType = 'All Types',
    this.selectedStatus = 'All Status',
    this.sortBy = 'Date (Newest)',
    this.rowsPerPage = 10,
    this.currentPage = 1,
  });

  JournalFilterState copyWith({
    String? searchQuery,
    String? selectedTab,
    String? dateRangeLabel,
    DateTimeRange? customDateRange,
    String? selectedType,
    String? selectedStatus,
    String? sortBy,
    int? rowsPerPage,
    int? currentPage,
  }) {
    return JournalFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTab: selectedTab ?? this.selectedTab,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      customDateRange: customDateRange ?? this.customDateRange,
      selectedType: selectedType ?? this.selectedType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class JournalFilterNotifier extends StateNotifier<JournalFilterState> {
  JournalFilterNotifier() : super(const JournalFilterState());

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q, currentPage: 1);
  void setSelectedTab(String tab) => state = state.copyWith(selectedTab: tab, currentPage: 1);
  void setDateRange(String label, DateTimeRange? range) =>
      state = state.copyWith(dateRangeLabel: label, customDateRange: range, currentPage: 1);
  void setSelectedType(String t) => state = state.copyWith(selectedType: t, currentPage: 1);
  void setSelectedStatus(String s) => state = state.copyWith(selectedStatus: s, currentPage: 1);
  void setSortBy(String sort) => state = state.copyWith(sortBy: sort);
  void setRowsPerPage(int count) => state = state.copyWith(rowsPerPage: count, currentPage: 1);
  void setPage(int page) => state = state.copyWith(currentPage: page);
  void reset() => state = const JournalFilterState();
}

final journalFilterProvider =
    StateNotifierProvider<JournalFilterNotifier, JournalFilterState>((ref) {
  return JournalFilterNotifier();
});

// Master mock list matching screenshot exactly
final masterJournalEntriesProvider = Provider<List<JournalEntryRowItem>>((ref) {
  return [
    JournalEntryRowItem(
      id: 'gj_0056',
      date: '24 May 2026',
      time: '03:42 PM',
      dateTime: DateTime(2026, 5, 24, 15, 42),
      journalNo: 'GJ/26-27/0056',
      journalTypeLabel: 'Standard',
      type: JournalType.standard,
      reference: 'JV-56',
      narration: 'Rent paid for Office May 2026',
      debit: 25000.00,
      credit: 25000.00,
      status: JournalEntryStatus.posted,
    ),
    JournalEntryRowItem(
      id: 'gj_0055',
      date: '24 May 2026',
      time: '02:15 PM',
      dateTime: DateTime(2026, 5, 24, 14, 15),
      journalNo: 'GJ/26-27/0055',
      journalTypeLabel: 'Standard',
      type: JournalType.standard,
      reference: '-',
      narration: 'Office stationery purchase',
      debit: 5650.00,
      credit: 5650.00,
      status: JournalEntryStatus.posted,
    ),
    JournalEntryRowItem(
      id: 'gj_0054',
      date: '23 May 2026',
      time: '06:30 PM',
      dateTime: DateTime(2026, 5, 23, 18, 30),
      journalNo: 'GJ/26-27/0054',
      journalTypeLabel: 'Standard',
      type: JournalType.standard,
      reference: '-',
      narration: 'Bank charges',
      debit: 850.00,
      credit: 850.00,
      status: JournalEntryStatus.posted,
    ),
    JournalEntryRowItem(
      id: 'gj_0053',
      date: '23 May 2026',
      time: '05:10 PM',
      dateTime: DateTime(2026, 5, 23, 17, 10),
      journalNo: 'GJ/26-27/0053',
      journalTypeLabel: 'Adjustment',
      type: JournalType.adjustment,
      reference: 'ADJ-12',
      narration: 'Salary payable adjustment',
      debit: 15000.00,
      credit: 15000.00,
      status: JournalEntryStatus.posted,
    ),
    JournalEntryRowItem(
      id: 'gj_0052',
      date: '22 May 2026',
      time: '04:20 PM',
      dateTime: DateTime(2026, 5, 22, 16, 20),
      journalNo: 'GJ/26-27/0052',
      journalTypeLabel: 'Standard',
      type: JournalType.standard,
      reference: '-',
      narration: 'Prepaid insurance adjustment',
      debit: 4200.00,
      credit: 4200.00,
      status: JournalEntryStatus.draft,
    ),
    JournalEntryRowItem(
      id: 'gj_0051',
      date: '22 May 2026',
      time: '11:05 AM',
      dateTime: DateTime(2026, 5, 22, 11, 5),
      journalNo: 'GJ/26-27/0051',
      journalTypeLabel: 'Standard',
      type: JournalType.standard,
      reference: '-',
      narration: 'Interest income accrued',
      debit: 2750.00,
      credit: 2750.00,
      status: JournalEntryStatus.posted,
    ),
    JournalEntryRowItem(
      id: 'gj_0050',
      date: '21 May 2026',
      time: '09:35 AM',
      dateTime: DateTime(2026, 5, 21, 9, 35),
      journalNo: 'GJ/26-27/0050',
      journalTypeLabel: 'Standard',
      type: JournalType.standard,
      reference: '-',
      narration: 'Depreciation for May 2026',
      debit: 18600.00,
      credit: 18600.00,
      status: JournalEntryStatus.posted,
    ),
    JournalEntryRowItem(
      id: 'gj_0049',
      date: '21 May 2026',
      time: '10:20 AM',
      dateTime: DateTime(2026, 5, 21, 10, 20),
      journalNo: 'GJ/26-27/0049',
      journalTypeLabel: 'Standard',
      type: JournalType.standard,
      reference: '-',
      narration: 'Electricity expense',
      debit: 3450.00,
      credit: 3450.00,
      status: JournalEntryStatus.posted,
    ),
  ];
});

class GeneralJournalSummaryData {
  final int totalJournals;
  final double totalDebit;
  final double totalCredit;
  final int outOfBalanceCount;
  final double difference;
  final bool isBalanced;
  final List<JournalEntryRowItem> pagedItems;
  final int totalCount;
  final int totalPages;
  final int currentPage;

  const GeneralJournalSummaryData({
    required this.totalJournals,
    required this.totalDebit,
    required this.totalCredit,
    required this.outOfBalanceCount,
    required this.difference,
    required this.isBalanced,
    required this.pagedItems,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
  });
}

final generalJournalDataProvider = Provider<GeneralJournalSummaryData>((ref) {
  final master = ref.watch(masterJournalEntriesProvider);
  final filter = ref.watch(journalFilterProvider);

  var list = List<JournalEntryRowItem>.from(master);

  // Filter by Tab
  if (filter.selectedTab == 'Drafts') {
    list = list.where((e) => e.status == JournalEntryStatus.draft).toList();
  } else if (filter.selectedTab == 'Recurring Journals') {
    list = list.where((e) => e.type == JournalType.recurring).toList();
  } else if (filter.selectedTab == 'Journal Templates') {
    list = list.where((e) => e.type == JournalType.template).toList();
  }

  // Filter by Search Query
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    list = list.where((e) {
      return e.journalNo.toLowerCase().contains(q) ||
          e.narration.toLowerCase().contains(q) ||
          e.reference.toLowerCase().contains(q) ||
          e.journalTypeLabel.toLowerCase().contains(q);
    }).toList();
  }

  // Filter by Type
  if (filter.selectedType != 'All Types') {
    list = list.where((e) => e.journalTypeLabel.toLowerCase() == filter.selectedType.toLowerCase()).toList();
  }

  // Filter by Status
  if (filter.selectedStatus != 'All Status') {
    list = list.where((e) => e.status.name.toLowerCase() == filter.selectedStatus.toLowerCase()).toList();
  }

  // Sorting
  if (filter.sortBy == 'Date (Newest)') {
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  } else if (filter.sortBy == 'Date (Oldest)') {
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  } else if (filter.sortBy == 'Amount (High to Low)') {
    list.sort((a, b) => b.debit.compareTo(a.debit));
  } else if (filter.sortBy == 'Amount (Low to High)') {
    list.sort((a, b) => a.debit.compareTo(b.debit));
  }

  // Pagination
  final pageSize = filter.rowsPerPage;
  final totalPages = (84 / pageSize).ceil();
  final currentPage = filter.currentPage.clamp(1, totalPages);
  final startIndex = ((currentPage - 1) * pageSize).clamp(0, list.length);
  final pagedItems = list.skip(startIndex).take(pageSize).toList();

  return GeneralJournalSummaryData(
    totalJournals: 84, // Matching screenshot
    totalDebit: 1245300.00, // Matching screenshot
    totalCredit: 1245300.00, // Matching screenshot
    outOfBalanceCount: 0, // Matching screenshot
    difference: 0.00,
    isBalanced: true,
    pagedItems: pagedItems.isNotEmpty ? pagedItems : list,
    totalCount: 84,
    totalPages: totalPages,
    currentPage: currentPage,
  );
});
