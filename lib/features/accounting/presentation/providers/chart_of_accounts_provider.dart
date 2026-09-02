import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CoaAccountType {
  asset,
  liability,
  equity,
  income,
  expense,
}

class CoaAccountItem {
  final String id;
  final String code;
  final String name;
  final String description;
  final CoaAccountType type;
  final double balance;
  final bool isGroup;
  final String? parentCode;
  final List<CoaAccountItem> children;

  const CoaAccountItem({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.balance,
    this.isGroup = false,
    this.parentCode,
    this.children = const [],
  });

  CoaAccountItem copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    CoaAccountType? type,
    double? balance,
    bool? isGroup,
    String? parentCode,
    List<CoaAccountItem>? children,
  }) {
    return CoaAccountItem(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isGroup: isGroup ?? this.isGroup,
      parentCode: parentCode ?? this.parentCode,
      children: children ?? this.children,
    );
  }
}

class CoaFilterState {
  final String searchQuery;
  final String selectedCategory;
  final Set<String> expandedGroupCodes;
  final bool showZeroBalances;
  final String sortBy;

  const CoaFilterState({
    this.searchQuery = '',
    this.selectedCategory = 'All Accounts',
    this.expandedGroupCodes = const {'1000', '2000', '3000', '4000', '5000', '6000'},
    this.showZeroBalances = true,
    this.sortBy = 'Code (Ascending)',
  });

  CoaFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    Set<String>? expandedGroupCodes,
    bool? showZeroBalances,
    String? sortBy,
  }) {
    return CoaFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      expandedGroupCodes: expandedGroupCodes ?? this.expandedGroupCodes,
      showZeroBalances: showZeroBalances ?? this.showZeroBalances,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class CoaNotifier extends StateNotifier<CoaFilterState> {
  CoaNotifier() : super(const CoaFilterState());

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setSelectedCategory(String cat) {
    state = state.copyWith(selectedCategory: cat);
  }

  void toggleGroupExpansion(String code) {
    final next = Set<String>.from(state.expandedGroupCodes);
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    state = state.copyWith(expandedGroupCodes: next);
  }

  void expandAll() {
    state = state.copyWith(expandedGroupCodes: {'1000', '2000', '3000', '4000', '5000', '6000'});
  }

  void collapseAll() {
    state = state.copyWith(expandedGroupCodes: {});
  }

  void setShowZeroBalances(bool val) {
    state = state.copyWith(showZeroBalances: val);
  }

  void setSortBy(String sort) {
    state = state.copyWith(sortBy: sort);
  }
}

final coaFilterProvider = StateNotifierProvider<CoaNotifier, CoaFilterState>((ref) {
  return CoaNotifier();
});

// Mock Chart of Accounts hierarchy matching screenshot exactly
final coaMasterAccountsProvider = Provider<List<CoaAccountItem>>((ref) {
  return [
    const CoaAccountItem(
      id: 'grp_1000',
      code: '1000',
      name: '1. Assets',
      description: 'All asset related accounts',
      type: CoaAccountType.asset,
      balance: 635400.00,
      isGroup: true,
      children: [
        CoaAccountItem(
          id: 'acc_1001',
          code: '1001',
          name: '1.1 Cash in Hand',
          description: 'Physical cash available in drawer',
          type: CoaAccountType.asset,
          balance: 12750.00,
          parentCode: '1000',
        ),
        CoaAccountItem(
          id: 'acc_1002',
          code: '1002',
          name: '1.2 Bank Accounts',
          description: 'HDFC & ICICI Current Accounts',
          type: CoaAccountType.asset,
          balance: 580000.00,
          parentCode: '1000',
        ),
        CoaAccountItem(
          id: 'acc_1003',
          code: '1003',
          name: '1.3 Accounts Receivable',
          description: 'Outstanding invoices from customers',
          type: CoaAccountType.asset,
          balance: 42650.00,
          parentCode: '1000',
        ),
      ],
    ),
    const CoaAccountItem(
      id: 'grp_2000',
      code: '2000',
      name: '2. Liabilities',
      description: 'All liability related accounts',
      type: CoaAccountType.liability,
      balance: 215200.00,
      isGroup: true,
      children: [
        CoaAccountItem(
          id: 'acc_2001',
          code: '2001',
          name: '2.1 Accounts Payable',
          description: 'Bills due to suppliers & vendors',
          type: CoaAccountType.liability,
          balance: 125200.00,
          parentCode: '2000',
        ),
        CoaAccountItem(
          id: 'acc_2002',
          code: '2002',
          name: '2.2 Short Term Loans',
          description: 'Working capital credit facility',
          type: CoaAccountType.liability,
          balance: 90000.00,
          parentCode: '2000',
        ),
      ],
    ),
    const CoaAccountItem(
      id: 'grp_3000',
      code: '3000',
      name: '3. Equity',
      description: 'Owner\'s equity accounts',
      type: CoaAccountType.equity,
      balance: 325000.00,
      isGroup: true,
      children: [
        CoaAccountItem(
          id: 'acc_3001',
          code: '3001',
          name: '3.1 Owner\'s Capital',
          description: 'Initial business investment capital',
          type: CoaAccountType.equity,
          balance: 250000.00,
          parentCode: '3000',
        ),
        CoaAccountItem(
          id: 'acc_3002',
          code: '3002',
          name: '3.2 Retained Earnings',
          description: 'Accumulated profits retained',
          type: CoaAccountType.equity,
          balance: 75000.00,
          parentCode: '3000',
        ),
      ],
    ),
    const CoaAccountItem(
      id: 'grp_4000',
      code: '4000',
      name: '4. Income',
      description: 'All income accounts',
      type: CoaAccountType.income,
      balance: 875000.00,
      isGroup: true,
      children: [
        CoaAccountItem(
          id: 'acc_4001',
          code: '4001',
          name: '4.1 Sales Revenue',
          description: 'Primary product sales revenue',
          type: CoaAccountType.income,
          balance: 825000.00,
          parentCode: '4000',
        ),
        CoaAccountItem(
          id: 'acc_4002',
          code: '4002',
          name: '4.2 Service Income',
          description: 'Consulting & installation charges',
          type: CoaAccountType.income,
          balance: 50000.00,
          parentCode: '4000',
        ),
      ],
    ),
    const CoaAccountItem(
      id: 'grp_5000',
      code: '5000',
      name: '5. Expenses',
      description: 'All expense accounts',
      type: CoaAccountType.expense,
      balance: 412300.00,
      isGroup: true,
      children: [
        CoaAccountItem(
          id: 'acc_5001',
          code: '5001',
          name: '5.1 Salaries & Wages',
          description: 'Employee payroll & bonuses',
          type: CoaAccountType.expense,
          balance: 250000.00,
          parentCode: '5000',
        ),
        CoaAccountItem(
          id: 'acc_5002',
          code: '5002',
          name: '5.2 Rent & Utilities',
          description: 'Office rent, electricity & internet',
          type: CoaAccountType.expense,
          balance: 162300.00,
          parentCode: '5000',
        ),
      ],
    ),
    const CoaAccountItem(
      id: 'grp_6000',
      code: '6000',
      name: '6. Other Income',
      description: 'Other income accounts',
      type: CoaAccountType.income,
      balance: 25000.00,
      isGroup: true,
      children: [
        CoaAccountItem(
          id: 'acc_6001',
          code: '6001',
          name: '6.1 Interest Income',
          description: 'Bank FD & savings interest',
          type: CoaAccountType.income,
          balance: 25000.00,
          parentCode: '6000',
        ),
      ],
    ),
  ];
});

class CoaSummaryData {
  final int totalAccounts;
  final int groups;
  final int ledgerAccounts;
  final double totalBalance;
  final List<CoaAccountItem> displayedGroups;

  const CoaSummaryData({
    required this.totalAccounts,
    required this.groups,
    required this.ledgerAccounts,
    required this.totalBalance,
    required this.displayedGroups,
  });
}

final coaDataProvider = Provider<CoaSummaryData>((ref) {
  final master = ref.watch(coaMasterAccountsProvider);
  final filter = ref.watch(coaFilterProvider);

  var groups = List<CoaAccountItem>.from(master);

  // Filter by category tab
  if (filter.selectedCategory != 'All Accounts') {
    groups = groups.where((g) {
      if (filter.selectedCategory == 'Assets') return g.type == CoaAccountType.asset;
      if (filter.selectedCategory == 'Liabilities') return g.type == CoaAccountType.liability;
      if (filter.selectedCategory == 'Equity') return g.type == CoaAccountType.equity;
      if (filter.selectedCategory == 'Income') return g.type == CoaAccountType.income;
      if (filter.selectedCategory == 'Expenses') return g.type == CoaAccountType.expense;
      return true;
    }).toList();
  }

  // Filter by search query
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    groups = groups.map((g) {
      final matchesGroup = g.name.toLowerCase().contains(q) || g.code.contains(q);
      final matchedChildren = g.children.where((c) {
        return c.name.toLowerCase().contains(q) || c.code.contains(q) || c.description.toLowerCase().contains(q);
      }).toList();

      if (matchesGroup || matchedChildren.isNotEmpty) {
        return g.copyWith(children: matchedChildren.isNotEmpty ? matchedChildren : g.children);
      }
      return null;
    }).whereType<CoaAccountItem>().toList();
  }

  return CoaSummaryData(
    totalAccounts: 156, // matching screenshot
    groups: 78,         // matching screenshot
    ledgerAccounts: 96, // matching screenshot
    totalBalance: 1245300.00, // matching screenshot
    displayedGroups: groups,
  );
});
