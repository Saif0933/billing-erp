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

class StatementLineItemDto {
  final String label;
  final double currentAmount;
  final double previousAmount;
  final double percentChange;
  final bool isPositive;
  final bool isHeader;
  final bool isTotal;
  final bool isHighlight;
  final String? accountCode;
  final String? category;

  const StatementLineItemDto({
    required this.label,
    required this.currentAmount,
    required this.previousAmount,
    required this.percentChange,
    this.isPositive = true,
    this.isHeader = false,
    this.isTotal = false,
    this.isHighlight = false,
    this.accountCode,
    this.category,
  });

  factory StatementLineItemDto.fromJson(Map<String, dynamic> json) {
    return StatementLineItemDto(
      label: json['label']?.toString() ?? '',
      currentAmount: parseNum(json['currentAmount']),
      previousAmount: parseNum(json['previousAmount']),
      percentChange: parseNum(json['percentChange']),
      isPositive: json['isPositive'] as bool? ?? true,
      isHeader: json['isHeader'] as bool? ?? false,
      isTotal: json['isTotal'] as bool? ?? false,
      isHighlight: json['isHighlight'] as bool? ?? false,
      accountCode: json['accountCode']?.toString(),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'currentAmount': currentAmount,
      'previousAmount': previousAmount,
      'percentChange': percentChange,
      'isPositive': isPositive,
      'isHeader': isHeader,
      'isTotal': isTotal,
      'isHighlight': isHighlight,
      'accountCode': accountCode,
      'category': category,
    };
  }

  factory StatementLineItemDto.empty({String label = ''}) {
    return StatementLineItemDto(
      label: label,
      currentAmount: 0.0,
      previousAmount: 0.0,
      percentChange: 0.0,
    );
  }
}

class ProfitTrendPointDto {
  final String month;
  final double amount;
  final String label;

  const ProfitTrendPointDto({
    required this.month,
    required this.amount,
    required this.label,
  });

  factory ProfitTrendPointDto.fromJson(Map<String, dynamic> json) {
    return ProfitTrendPointDto(
      month: json['month']?.toString() ?? '',
      amount: parseNum(json['amount']),
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'amount': amount,
      'label': label,
    };
  }
}

class StatementSectionDto {
  final String sectionTitle;
  final String sectionColor;
  final List<StatementLineItemDto> items;
  final StatementLineItemDto totalItem;

  const StatementSectionDto({
    required this.sectionTitle,
    required this.sectionColor,
    required this.items,
    required this.totalItem,
  });

  factory StatementSectionDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => StatementLineItemDto.fromJson(e))
        .toList();

    StatementLineItemDto totalItem = StatementLineItemDto.empty();
    if (json['totalItem'] is Map<String, dynamic>) {
      totalItem = StatementLineItemDto.fromJson(json['totalItem'] as Map<String, dynamic>);
    }

    return StatementSectionDto(
      sectionTitle: json['sectionTitle']?.toString() ?? '',
      sectionColor: json['sectionColor']?.toString() ?? '#15803D',
      items: items,
      totalItem: totalItem,
    );
  }
}

class FinancialDonutSegmentDto {
  final String name;
  final double amount;
  final double percentage;
  final String color;

  const FinancialDonutSegmentDto({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  factory FinancialDonutSegmentDto.fromJson(Map<String, dynamic> json) {
    return FinancialDonutSegmentDto(
      name: json['name']?.toString() ?? '',
      amount: parseNum(json['amount']),
      percentage: parseNum(json['percentage']),
      color: json['color']?.toString() ?? '#2563EB',
    );
  }
}

class FinancialStatementSummaryDto {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double netProfitMargin;
  final double profitGrowthPercent;
  final List<StatementLineItemDto> incomeItems;
  final StatementLineItemDto totalIncomeItem;
  final List<StatementLineItemDto> expenseItems;
  final StatementLineItemDto totalExpenseItem;
  final StatementLineItemDto netProfitItem;
  final List<ProfitTrendPointDto> trendPoints;
  final List<FinancialDonutSegmentDto> donutBreakdown;

  const FinancialStatementSummaryDto({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.netProfitMargin,
    required this.profitGrowthPercent,
    required this.incomeItems,
    required this.totalIncomeItem,
    required this.expenseItems,
    required this.totalExpenseItem,
    required this.netProfitItem,
    required this.trendPoints,
    this.donutBreakdown = const [],
  });

  factory FinancialStatementSummaryDto.fromJson(Map<String, dynamic> json) {
    final rawIncome = json['incomeItems'] as List<dynamic>? ?? [];
    final incomeItems = rawIncome
        .whereType<Map<String, dynamic>>()
        .map((e) => StatementLineItemDto.fromJson(e))
        .toList();

    StatementLineItemDto totalIncomeItem = StatementLineItemDto.empty(label: 'Total Income');
    if (json['totalIncomeItem'] is Map<String, dynamic>) {
      totalIncomeItem = StatementLineItemDto.fromJson(json['totalIncomeItem'] as Map<String, dynamic>);
    }

    final rawExpenses = json['expenseItems'] as List<dynamic>? ?? [];
    final expenseItems = rawExpenses
        .whereType<Map<String, dynamic>>()
        .map((e) => StatementLineItemDto.fromJson(e))
        .toList();

    StatementLineItemDto totalExpenseItem = StatementLineItemDto.empty(label: 'Total Expenses');
    if (json['totalExpenseItem'] is Map<String, dynamic>) {
      totalExpenseItem = StatementLineItemDto.fromJson(json['totalExpenseItem'] as Map<String, dynamic>);
    }

    StatementLineItemDto netProfitItem = StatementLineItemDto.empty(label: 'Net Profit');
    if (json['netProfitItem'] is Map<String, dynamic>) {
      netProfitItem = StatementLineItemDto.fromJson(json['netProfitItem'] as Map<String, dynamic>);
    }

    final rawTrend = json['trendPoints'] as List<dynamic>? ?? [];
    final trendPoints = rawTrend
        .whereType<Map<String, dynamic>>()
        .map((e) => ProfitTrendPointDto.fromJson(e))
        .toList();

    final rawDonut = json['donutBreakdown'] as List<dynamic>? ?? [];
    final donutBreakdown = rawDonut
        .whereType<Map<String, dynamic>>()
        .map((e) => FinancialDonutSegmentDto.fromJson(e))
        .toList();

    return FinancialStatementSummaryDto(
      totalIncome: parseNum(json['totalIncome']),
      totalExpenses: parseNum(json['totalExpenses']),
      netProfit: parseNum(json['netProfit']),
      netProfitMargin: parseNum(json['netProfitMargin']),
      profitGrowthPercent: parseNum(json['profitGrowthPercent']),
      incomeItems: incomeItems,
      totalIncomeItem: totalIncomeItem,
      expenseItems: expenseItems,
      totalExpenseItem: totalExpenseItem,
      netProfitItem: netProfitItem,
      trendPoints: trendPoints,
      donutBreakdown: donutBreakdown,
    );
  }

  factory FinancialStatementSummaryDto.empty() {
    return FinancialStatementSummaryDto(
      totalIncome: 0.0,
      totalExpenses: 0.0,
      netProfit: 0.0,
      netProfitMargin: 0.0,
      profitGrowthPercent: 0.0,
      incomeItems: const [],
      totalIncomeItem: StatementLineItemDto.empty(label: 'Total Income'),
      expenseItems: const [],
      totalExpenseItem: StatementLineItemDto.empty(label: 'Total Expenses'),
      netProfitItem: StatementLineItemDto.empty(label: 'Net Profit'),
      trendPoints: const [],
      donutBreakdown: const [],
    );
  }
}

class FinancialStatementResponseDto {
  final String reportType;
  final String reportTypeLabel;
  final String dateRangeLabel;
  final String currentPeriodLabel;
  final String previousPeriodLabel;
  final String compareWith;
  final List<StatementSectionDto> sections;
  final StatementLineItemDto? bannerItem;
  final FinancialStatementSummaryDto summary;
  final String trendPeriod;
  final List<ProfitTrendPointDto> trendPoints;
  final String currency;
  final String companyName;

  const FinancialStatementResponseDto({
    required this.reportType,
    required this.reportTypeLabel,
    required this.dateRangeLabel,
    required this.currentPeriodLabel,
    required this.previousPeriodLabel,
    required this.compareWith,
    required this.sections,
    this.bannerItem,
    required this.summary,
    required this.trendPeriod,
    required this.trendPoints,
    required this.currency,
    required this.companyName,
  });

  factory FinancialStatementResponseDto.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? [];
    final sections = rawSections
        .whereType<Map<String, dynamic>>()
        .map((e) => StatementSectionDto.fromJson(e))
        .toList();

    StatementLineItemDto? bannerItem;
    if (json['bannerItem'] is Map<String, dynamic>) {
      bannerItem = StatementLineItemDto.fromJson(json['bannerItem'] as Map<String, dynamic>);
    }

    FinancialStatementSummaryDto summary = FinancialStatementSummaryDto.empty();
    if (json['summary'] is Map<String, dynamic>) {
      summary = FinancialStatementSummaryDto.fromJson(json['summary'] as Map<String, dynamic>);
    }

    final rawTrend = json['trendPoints'] as List<dynamic>? ?? [];
    final trendPoints = rawTrend
        .whereType<Map<String, dynamic>>()
        .map((e) => ProfitTrendPointDto.fromJson(e))
        .toList();

    return FinancialStatementResponseDto(
      reportType: json['reportType']?.toString() ?? 'profitAndLoss',
      reportTypeLabel: json['reportTypeLabel']?.toString() ?? 'Profit & Loss Statement',
      dateRangeLabel: json['dateRangeLabel']?.toString() ?? '01 Apr 2026 – 31 May 2026',
      currentPeriodLabel: json['currentPeriodLabel']?.toString() ?? '01 Apr 2026 – 31 May 2026',
      previousPeriodLabel: json['previousPeriodLabel']?.toString() ?? '01 Feb – 31 Mar 2026',
      compareWith: json['compareWith']?.toString() ?? 'Previous Period',
      sections: sections,
      bannerItem: bannerItem,
      summary: summary,
      trendPeriod: json['trendPeriod']?.toString() ?? 'Last 6 Months',
      trendPoints: trendPoints,
      currency: json['currency']?.toString() ?? 'INR',
      companyName: json['companyName']?.toString() ?? 'Tax Bunny Retail Store',
    );
  }

  factory FinancialStatementResponseDto.empty() {
    return FinancialStatementResponseDto(
      reportType: 'profitAndLoss',
      reportTypeLabel: 'Profit & Loss Statement',
      dateRangeLabel: '01 Apr 2026 – 31 May 2026',
      currentPeriodLabel: '01 Apr 2026 – 31 May 2026',
      previousPeriodLabel: '01 Feb – 31 Mar 2026',
      compareWith: 'Previous Period',
      sections: const [],
      summary: FinancialStatementSummaryDto.empty(),
      trendPeriod: 'Last 6 Months',
      trendPoints: const [],
      currency: 'INR',
      companyName: 'Tax Bunny Retail Store',
    );
  }
}
