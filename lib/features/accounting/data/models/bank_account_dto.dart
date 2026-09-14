enum BankAccountCategory {
  current,
  savings,
  credit,
  inactive,
}

BankAccountCategory parseBankAccountCategory(dynamic val) {
  if (val == null) return BankAccountCategory.current;
  final str = val.toString().toLowerCase().trim();
  if (str.contains('saving')) return BankAccountCategory.savings;
  if (str.contains('credit') || str.contains('overdraft')) return BankAccountCategory.credit;
  if (str.contains('inactive')) return BankAccountCategory.inactive;
  return BankAccountCategory.current;
}

String categoryToSlug(BankAccountCategory category) {
  switch (category) {
    case BankAccountCategory.current:
      return 'current';
    case BankAccountCategory.savings:
      return 'savings';
    case BankAccountCategory.credit:
      return 'credit';
    case BankAccountCategory.inactive:
      return 'inactive';
  }
}

double parseNum(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  if (val is Map) {
    if (val.containsKey('d') && val['d'] is List) {
      final list = val['d'] as List;
      final digits = list.join('');
      return double.tryParse(digits) ?? 0.0;
    }
  }
  return 0.0;
}

int parseInt(dynamic val, {int defaultValue = 0}) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? defaultValue;
  return defaultValue;
}

class BankAccountItemDto {
  final String id;
  final String bankName;
  final String accountTypeLabel;
  final BankAccountCategory category;
  final String accountNumberMasked;
  final String fullAccountNumber;
  final String ifsc;
  final String branch;
  final double currentBalance;
  final double clearedBalance;
  final double unclearedBalance;
  final String status;
  final String logoType;

  const BankAccountItemDto({
    required this.id,
    required this.bankName,
    required this.accountTypeLabel,
    required this.category,
    required this.accountNumberMasked,
    required this.fullAccountNumber,
    required this.ifsc,
    this.branch = '',
    required this.currentBalance,
    required this.clearedBalance,
    required this.unclearedBalance,
    this.status = 'Active',
    required this.logoType,
  });

  factory BankAccountItemDto.fromJson(Map<String, dynamic> json) {
    return BankAccountItemDto(
      id: json['id']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      accountTypeLabel: json['accountTypeLabel']?.toString() ??
          json['accountType']?.toString() ??
          'Current Account',
      category: parseBankAccountCategory(json['category'] ?? json['accountTypeLabel']),
      accountNumberMasked: json['accountNumberMasked']?.toString() ?? 'XXXX XXXX 0000',
      fullAccountNumber: json['fullAccountNumber']?.toString() ??
          json['accountNumber']?.toString() ??
          '',
      ifsc: json['ifsc']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      currentBalance: parseNum(json['currentBalance']),
      clearedBalance: parseNum(json['clearedBalance']),
      unclearedBalance: parseNum(json['unclearedBalance']),
      status: json['status']?.toString() ?? 'Active',
      logoType: json['logoType']?.toString() ?? 'other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'accountTypeLabel': accountTypeLabel,
      'category': categoryToSlug(category),
      'accountNumberMasked': accountNumberMasked,
      'fullAccountNumber': fullAccountNumber,
      'ifsc': ifsc,
      'branch': branch,
      'currentBalance': currentBalance,
      'clearedBalance': clearedBalance,
      'unclearedBalance': unclearedBalance,
      'status': status,
      'logoType': logoType,
    };
  }
}

class BankTransactionItemDto {
  final String id;
  final String title;
  final String subtitle;
  final String reference;
  final double amount;
  final bool isCredit;
  final String date;
  final bool isCleared;
  final String logoType;

  const BankTransactionItemDto({
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

  factory BankTransactionItemDto.fromJson(Map<String, dynamic> json) {
    return BankTransactionItemDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      amount: parseNum(json['amount']),
      isCredit: json['isCredit'] == true,
      date: json['date']?.toString() ?? '',
      isCleared: json['isCleared'] == true,
      logoType: json['logoType']?.toString() ?? 'other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'reference': reference,
      'amount': amount,
      'isCredit': isCredit,
      'date': date,
      'isCleared': isCleared,
      'logoType': logoType,
    };
  }
}

class BankShareSegmentDto {
  final String name;
  final double amount;
  final double percentage;
  final String color;

  const BankShareSegmentDto({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  factory BankShareSegmentDto.fromJson(Map<String, dynamic> json) {
    return BankShareSegmentDto(
      name: json['name']?.toString() ?? '',
      amount: parseNum(json['amount']),
      percentage: parseNum(json['percentage']),
      color: json['color']?.toString() ?? '#2563EB',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'percentage': percentage,
      'color': color,
    };
  }
}

class BankAccountsResponseDto {
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
  final int limit;

  const BankAccountsResponseDto({
    required this.totalAccounts,
    required this.totalBalance,
    required this.clearedBalance,
    required this.unclearedBalance,
    required this.displayedAccounts,
    required this.recentTransactions,
    required this.balanceOverview,
    required this.totalPages,
    required this.currentPage,
    required this.totalCount,
    required this.limit,
  });

  factory BankAccountsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawAccounts = json['displayedAccounts'] as List? ?? [];
    final accounts = rawAccounts
        .whereType<Map<String, dynamic>>()
        .map((e) => BankAccountItemDto.fromJson(e))
        .toList();

    final rawTx = json['recentTransactions'] as List? ?? [];
    final txs = rawTx
        .whereType<Map<String, dynamic>>()
        .map((e) => BankTransactionItemDto.fromJson(e))
        .toList();

    final rawSegments = json['balanceOverview'] as List? ?? [];
    final segments = rawSegments
        .whereType<Map<String, dynamic>>()
        .map((e) => BankShareSegmentDto.fromJson(e))
        .toList();

    return BankAccountsResponseDto(
      totalAccounts: parseInt(json['totalAccounts']),
      totalBalance: parseNum(json['totalBalance']),
      clearedBalance: parseNum(json['clearedBalance']),
      unclearedBalance: parseNum(json['unclearedBalance']),
      displayedAccounts: accounts,
      recentTransactions: txs,
      balanceOverview: segments,
      totalPages: parseInt(json['totalPages'], defaultValue: 1),
      currentPage: parseInt(json['currentPage'], defaultValue: 1),
      totalCount: parseInt(json['totalCount'], defaultValue: accounts.length),
      limit: parseInt(json['limit'], defaultValue: 10),
    );
  }

  factory BankAccountsResponseDto.empty() {
    return const BankAccountsResponseDto(
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
      limit: 10,
    );
  }
}

class CreateBankAccountDto {
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String ifsc;
  final String branch;
  final double openingBalance;
  final String status;
  final String? logoType;

  const CreateBankAccountDto({
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.ifsc,
    this.branch = '',
    this.openingBalance = 0.0,
    this.status = 'Active',
    this.logoType,
  });

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName.trim(),
      'accountType': accountType.trim(),
      'accountNumber': accountNumber.trim(),
      'ifsc': ifsc.trim().toUpperCase(),
      if (branch.trim().isNotEmpty) 'branch': branch.trim(),
      'openingBalance': openingBalance,
      'status': status,
      if (logoType != null && logoType!.isNotEmpty) 'logoType': logoType,
    };
  }
}
