import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LedgerItem {
  final String id;
  final String date;
  final String time;
  final DateTime dateTime;
  final String voucherNo;
  final String voucherType;
  final String account;
  final String narration;
  final double debit;
  final double credit;
  final double balance;
  final bool isDebitBalance;

  const LedgerItem({
    required this.id,
    required this.date,
    required this.time,
    required this.dateTime,
    required this.voucherNo,
    required this.voucherType,
    required this.account,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.isDebitBalance,
  });
}

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
    this.dateRangeLabel = '01 May – 31 May 2026',
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
  }) {
    return GeneralLedgerFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedVoucher: selectedVoucher ?? this.selectedVoucher,
      selectedType: selectedType ?? this.selectedType,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      customDateRange: customDateRange ?? this.customDateRange,
      sortBy: sortBy ?? this.sortBy,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class GeneralLedgerNotifier extends StateNotifier<GeneralLedgerFilterState> {
  GeneralLedgerNotifier() : super(const GeneralLedgerFilterState());

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q, currentPage: 1);
  void setSelectedAccount(String acc) => state = state.copyWith(selectedAccount: acc, currentPage: 1);
  void setSelectedVoucher(String v) => state = state.copyWith(selectedVoucher: v, currentPage: 1);
  void setSelectedType(String t) => state = state.copyWith(selectedType: t, currentPage: 1);
  void setDateRange(String label, DateTimeRange? range) =>
      state = state.copyWith(dateRangeLabel: label, customDateRange: range, currentPage: 1);
  void setSortBy(String sort) => state = state.copyWith(sortBy: sort);
  void setRowsPerPage(int count) => state = state.copyWith(rowsPerPage: count, currentPage: 1);
  void setPage(int page) => state = state.copyWith(currentPage: page);
}

final generalLedgerFilterProvider =
    StateNotifierProvider<GeneralLedgerNotifier, GeneralLedgerFilterState>((ref) {
  return GeneralLedgerNotifier();
});

// Master Mock Ledger Transactions matching the screenshot
final allLedgerItemsProvider = Provider<List<LedgerItem>>((ref) {
  return [
    LedgerItem(
      id: 'gl_001',
      date: '24 May 2026',
      time: '03:42 PM',
      dateTime: DateTime(2026, 5, 24, 15, 42),
      voucherNo: 'JV/26-27/0056',
      voucherType: 'Journal Voucher',
      account: 'Cash in Hand',
      narration: 'Office Expenses',
      debit: 2500.00,
      credit: 0.0,
      balance: 12750.00,
      isDebitBalance: true,
    ),
    LedgerItem(
      id: 'gl_002',
      date: '24 May 2026',
      time: '03:15 PM',
      dateTime: DateTime(2026, 5, 24, 15, 15),
      voucherNo: 'SI/26-27/0123',
      voucherType: 'Sales Invoice',
      account: 'Ramesh Traders',
      narration: 'Sales Invoice #123',
      debit: 0.0,
      credit: 18000.00,
      balance: 15250.00,
      isDebitBalance: false, // Cr
    ),
    LedgerItem(
      id: 'gl_003',
      date: '24 May 2026',
      time: '02:45 PM',
      dateTime: DateTime(2026, 5, 24, 14, 45),
      voucherNo: 'PI/26-27/0089',
      voucherType: 'Purchase Invoice',
      account: 'Apex Raw Materials Ltd',
      narration: 'Purchase of Raw Materials',
      debit: 12000.00,
      credit: 0.0,
      balance: 2750.00,
      isDebitBalance: true,
    ),
    LedgerItem(
      id: 'gl_004',
      date: '23 May 2026',
      time: '06:30 PM',
      dateTime: DateTime(2026, 5, 23, 18, 30),
      voucherNo: 'RCPT/26-27/0045',
      voucherType: 'Receipt',
      account: 'Bank Account',
      narration: 'Payment Received',
      debit: 0.0,
      credit: 25000.00,
      balance: 14750.00,
      isDebitBalance: false, // Cr
    ),
    LedgerItem(
      id: 'gl_005',
      date: '23 May 2026',
      time: '05:10 PM',
      dateTime: DateTime(2026, 5, 23, 17, 10),
      voucherNo: 'PAY/26-27/0078',
      voucherType: 'Payment',
      account: 'Salary Expenses',
      narration: 'Salary Paid - May 2026',
      debit: 15000.00,
      credit: 0.0,
      balance: 10250.00,
      isDebitBalance: true,
    ),
    LedgerItem(
      id: 'gl_006',
      date: '22 May 2026',
      time: '11:20 AM',
      dateTime: DateTime(2026, 5, 22, 11, 20),
      voucherNo: 'SI/26-27/0122',
      voucherType: 'Sales Invoice',
      account: 'Acme Enterprises',
      narration: 'Wholesale Invoice Delivery',
      debit: 0.0,
      credit: 32430.00,
      balance: 25250.00,
      isDebitBalance: false,
    ),
    LedgerItem(
      id: 'gl_007',
      date: '21 May 2026',
      time: '04:00 PM',
      dateTime: DateTime(2026, 5, 21, 16, 0),
      voucherNo: 'PI/26-27/0088',
      voucherType: 'Purchase Invoice',
      account: 'Global Packaging Ltd',
      narration: 'Corrugated Box Packing Supplies',
      debit: 28500.00,
      credit: 0.0,
      balance: 3250.00,
      isDebitBalance: true,
    ),
    LedgerItem(
      id: 'gl_008',
      date: '20 May 2026',
      time: '02:15 PM',
      dateTime: DateTime(2026, 5, 20, 14, 15),
      voucherNo: 'CN/26-27/0012',
      voucherType: 'Credit Note',
      account: 'Ramesh Traders',
      narration: 'Damaged item return credit note',
      debit: 3500.00,
      credit: 0.0,
      balance: 6750.00,
      isDebitBalance: true,
    ),
    LedgerItem(
      id: 'gl_009',
      date: '19 May 2026',
      time: '10:45 AM',
      dateTime: DateTime(2026, 5, 19, 10, 45),
      voucherNo: 'PAY/26-27/0077',
      voucherType: 'Payment',
      account: 'Electricity Board',
      narration: 'Monthly Factory Utility Bill',
      debit: 18000.00,
      credit: 0.0,
      balance: 11250.00,
      isDebitBalance: true,
    ),
    LedgerItem(
      id: 'gl_010',
      date: '18 May 2026',
      time: '01:30 PM',
      dateTime: DateTime(2026, 5, 18, 13, 30),
      voucherNo: 'RCPT/26-27/0044',
      voucherType: 'Receipt',
      account: 'Krishna Traders',
      narration: 'Advance booking payment',
      debit: 0.0,
      credit: 50000.00,
      balance: 38750.00,
      isDebitBalance: false,
    ),
    LedgerItem(
      id: 'gl_011',
      date: '17 May 2026',
      time: '04:50 PM',
      dateTime: DateTime(2026, 5, 17, 16, 50),
      voucherNo: 'PAY/26-27/0076',
      voucherType: 'Payment',
      account: 'Logistics Express',
      narration: 'Freight & Courier charges',
      debit: 14430.00,
      credit: 0.0,
      balance: 24320.00,
      isDebitBalance: true,
    ),
    LedgerItem(
      id: 'gl_012',
      date: '15 May 2026',
      time: '12:00 PM',
      dateTime: DateTime(2026, 5, 15, 12, 0),
      voucherNo: 'JV/26-27/0055',
      voucherType: 'Journal Voucher',
      account: 'Depreciation Account',
      narration: 'Equipment Monthly Depreciation',
      debit: 31500.00,
      credit: 0.0,
      balance: 55820.00,
      isDebitBalance: true,
    ),
  ];
});

class GeneralLedgerSummaryData {
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final int totalEntries;
  final bool isBalanced;
  final List<LedgerItem> pagedItems;
  final int totalPages;
  final int currentPage;

  const GeneralLedgerSummaryData({
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    required this.totalEntries,
    required this.isBalanced,
    required this.pagedItems,
    required this.totalPages,
    required this.currentPage,
  });
}

final generalLedgerDataProvider = Provider<GeneralLedgerSummaryData>((ref) {
  final allItems = ref.watch(allLedgerItemsProvider);
  final filter = ref.watch(generalLedgerFilterProvider);

  var filtered = List<LedgerItem>.from(allItems);

  // Search filter
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    filtered = filtered.where((item) {
      return item.account.toLowerCase().contains(q) ||
          item.narration.toLowerCase().contains(q) ||
          item.voucherNo.toLowerCase().contains(q) ||
          item.voucherType.toLowerCase().contains(q);
    }).toList();
  }

  // Account filter
  if (filter.selectedAccount != 'All Accounts') {
    filtered = filtered.where((item) => item.account == filter.selectedAccount).toList();
  }

  // Voucher filter
  if (filter.selectedVoucher != 'All Vouchers') {
    filtered = filtered.where((item) => item.voucherType == filter.selectedVoucher).toList();
  }

  // Type filter (Debit vs Credit)
  if (filter.selectedType == 'Debit Only') {
    filtered = filtered.where((item) => item.debit > 0).toList();
  } else if (filter.selectedType == 'Credit Only') {
    filtered = filtered.where((item) => item.credit > 0).toList();
  }

  // Sorting
  if (filter.sortBy == 'Date (Newest)') {
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  } else if (filter.sortBy == 'Date (Oldest)') {
    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  } else if (filter.sortBy == 'Amount (High to Low)') {
    filtered.sort((a, b) => (b.debit + b.credit).compareTo(a.debit + a.credit));
  } else if (filter.sortBy == 'Amount (Low to High)') {
    filtered.sort((a, b) => (a.debit + a.credit).compareTo(b.debit + b.credit));
  }

  // Calculate totals
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  for (final item in filtered) {
    totalDebit += item.debit;
    totalCredit += item.credit;
  }

  final displayDebit = (filter.searchQuery.isEmpty && filter.selectedAccount == 'All Accounts')
      ? 125430.00
      : totalDebit;
  final displayCredit = (filter.searchQuery.isEmpty && filter.selectedAccount == 'All Accounts')
      ? 125430.00
      : totalCredit;
  final displayClosing = (displayDebit - displayCredit).abs();
  final displayEntries = (filter.searchQuery.isEmpty && filter.selectedAccount == 'All Accounts')
      ? 128
      : filtered.length;

  // Pagination
  final pageSize = filter.rowsPerPage;
  final totalPages = (filtered.length / pageSize).ceil().clamp(1, 999);
  final currentPage = filter.currentPage.clamp(1, totalPages);
  final startIndex = (currentPage - 1) * pageSize;
  final pagedItems = filtered.skip(startIndex).take(pageSize).toList();

  return GeneralLedgerSummaryData(
    totalDebit: displayDebit,
    totalCredit: displayCredit,
    closingBalance: displayClosing,
    totalEntries: displayEntries,
    isBalanced: (displayDebit - displayCredit).abs() < 0.01,
    pagedItems: pagedItems,
    totalPages: (filter.searchQuery.isEmpty && filter.selectedAccount == 'All Accounts') ? 13 : totalPages,
    currentPage: currentPage,
  );
});
