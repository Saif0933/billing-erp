import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BankAccountCategory {
  current,
  savings,
  credit,
  inactive,
}

class BankAccountItem {
  final String id;
  final String bankName;
  final String accountTypeLabel;
  final BankAccountCategory category;
  final String accountNumberMasked;
  final String fullAccountNumber;
  final String ifsc;
  final double currentBalance;
  final double clearedBalance;
  final double unclearedBalance;
  final String status;
  final String logoType; // 'sbi', 'hdfc', 'icici', 'axis', 'bob'

  const BankAccountItem({
    required this.id,
    required this.bankName,
    required this.accountTypeLabel,
    required this.category,
    required this.accountNumberMasked,
    required this.fullAccountNumber,
    required this.ifsc,
    required this.currentBalance,
    required this.clearedBalance,
    required this.unclearedBalance,
    this.status = 'Active',
    required this.logoType,
  });
}

class BankTransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final String reference;
  final double amount;
  final bool isCredit;
  final String date;
  final bool isCleared;
  final String logoType;

  const BankTransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reference,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.isCleared,
    required this.logoType,
  });
}

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

// Master mock bank accounts matching screenshot exactly
final masterBankAccountsProvider = Provider<List<BankAccountItem>>((ref) {
  return [
    const BankAccountItem(
      id: 'bank_01',
      bankName: 'State Bank of India',
      accountTypeLabel: 'Main Current Account',
      category: BankAccountCategory.current,
      accountNumberMasked: 'XXXX XXXX 1234',
      fullAccountNumber: '382910291234',
      ifsc: 'SBIN0001234',
      currentBalance: 745320.50,
      clearedBalance: 721100.50,
      unclearedBalance: 24220.00,
      status: 'Active',
      logoType: 'sbi',
    ),
    const BankAccountItem(
      id: 'bank_02',
      bankName: 'HDFC Bank',
      accountTypeLabel: 'Business Current Account',
      category: BankAccountCategory.current,
      accountNumberMasked: 'XXXX XXXX 5678',
      fullAccountNumber: '50200019285678',
      ifsc: 'HDFC0005678',
      currentBalance: 580450.00,
      clearedBalance: 551000.00,
      unclearedBalance: 29450.00,
      status: 'Active',
      logoType: 'hdfc',
    ),
    const BankAccountItem(
      id: 'bank_03',
      bankName: 'ICICI Bank',
      accountTypeLabel: 'Savings Account',
      category: BankAccountCategory.savings,
      accountNumberMasked: 'XXXX XXXX 9012',
      fullAccountNumber: '001201599012',
      ifsc: 'ICIC0009012',
      currentBalance: 325680.00,
      clearedBalance: 315680.00,
      unclearedBalance: 10000.00,
      status: 'Active',
      logoType: 'icici',
    ),
    const BankAccountItem(
      id: 'bank_04',
      bankName: 'Axis Bank',
      accountTypeLabel: 'Overdraft Account',
      category: BankAccountCategory.current,
      accountNumberMasked: 'XXXX XXXX 3456',
      fullAccountNumber: '91202004813456',
      ifsc: 'UTIB0003456',
      currentBalance: 215430.00,
      clearedBalance: 205430.00,
      unclearedBalance: 10000.00,
      status: 'Active',
      logoType: 'axis',
    ),
    const BankAccountItem(
      id: 'bank_05',
      bankName: 'Bank of Baroda',
      accountTypeLabel: 'Salary Account',
      category: BankAccountCategory.savings,
      accountNumberMasked: 'XXXX XXXX 7890',
      fullAccountNumber: '29810100007890',
      ifsc: 'BARB0XXXXXX',
      currentBalance: 108550.00,
      clearedBalance: 99100.00,
      unclearedBalance: 9450.00,
      status: 'Active',
      logoType: 'bob',
    ),
  ];
});

// Master mock recent transactions matching screenshot exactly
final masterBankTransactionsProvider = Provider<List<BankTransactionItem>>((ref) {
  return [
    const BankTransactionItem(
      id: 'tx_01',
      title: 'NEFT Payment Received',
      subtitle: 'From: ABC Corporation',
      reference: 'Ref: NEFT/240524/001',
      amount: 75000.00,
      isCredit: true,
      date: '24 May 2026',
      isCleared: true,
      logoType: 'sbi',
    ),
    const BankTransactionItem(
      id: 'tx_02',
      title: 'Cheque Deposit',
      subtitle: 'Cheque No: 123456',
      reference: 'Ref: DEP/240524/002',
      amount: 50000.00,
      isCredit: true,
      date: '24 May 2026',
      isCleared: false,
      logoType: 'hdfc',
    ),
    const BankTransactionItem(
      id: 'tx_03',
      title: 'UPI Payment',
      subtitle: 'To: Office Supplies',
      reference: 'Ref: UPI/240524/003',
      amount: 8450.00,
      isCredit: false,
      date: '24 May 2026',
      isCleared: true,
      logoType: 'icici',
    ),
    const BankTransactionItem(
      id: 'tx_04',
      title: 'Account Transfer',
      subtitle: 'To: Salary Account',
      reference: 'Ref: TRF/240523/004',
      amount: 100000.00,
      isCredit: false,
      date: '24 May 2026',
      isCleared: true,
      logoType: 'axis',
    ),
    const BankTransactionItem(
      id: 'tx_05',
      title: 'Interest Credited',
      subtitle: 'Bank Savings Interest',
      reference: 'Ref: INT/240523/005',
      amount: 1250.00,
      isCredit: true,
      date: '23 May 2026',
      isCleared: true,
      logoType: 'bob',
    ),
  ];
});

class BankSummaryData {
  final int totalAccounts;
  final double totalBalance;
  final double clearedBalance;
  final double unclearedBalance;
  final List<BankAccountItem> displayedAccounts;
  final List<BankTransactionItem> recentTransactions;
  final int totalPages;
  final int currentPage;

  const BankSummaryData({
    required this.totalAccounts,
    required this.totalBalance,
    required this.clearedBalance,
    required this.unclearedBalance,
    required this.displayedAccounts,
    required this.recentTransactions,
    required this.totalPages,
    required this.currentPage,
  });
}

final bankDataProvider = Provider<BankSummaryData>((ref) {
  final master = ref.watch(masterBankAccountsProvider);
  final transactions = ref.watch(masterBankTransactionsProvider);
  final filter = ref.watch(bankFilterProvider);

  var list = List<BankAccountItem>.from(master);

  // Filter by Tab
  if (filter.selectedTab == 'Current Accounts') {
    list = list.where((b) => b.category == BankAccountCategory.current).toList();
  } else if (filter.selectedTab == 'Savings Accounts') {
    list = list.where((b) => b.category == BankAccountCategory.savings).toList();
  } else if (filter.selectedTab == 'Credit Accounts') {
    list = list.where((b) => b.category == BankAccountCategory.credit).toList();
  } else if (filter.selectedTab == 'Inactive Accounts') {
    list = list.where((b) => b.status != 'Active').toList();
  }

  // Filter by Search Query
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    list = list.where((b) {
      return b.bankName.toLowerCase().contains(q) ||
          b.accountTypeLabel.toLowerCase().contains(q) ||
          b.accountNumberMasked.toLowerCase().contains(q) ||
          b.fullAccountNumber.contains(q);
    }).toList();
  }

  return BankSummaryData(
    totalAccounts: 5,
    totalBalance: 1875430.50,
    clearedBalance: 1792310.50,
    unclearedBalance: 83120.00,
    displayedAccounts: list,
    recentTransactions: transactions,
    totalPages: 1,
    currentPage: 1,
  );
});
