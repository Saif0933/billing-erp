import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FinancialReportType {
  profitAndLoss,
  balanceSheet,
  cashFlow,
  equityChanges,
}

class StatementLineItem {
  final String label;
  final double currentAmount;
  final double previousAmount;
  final double percentChange;
  final bool isPositive;
  final bool isHeader;
  final bool isTotal;
  final bool isHighlight;

  const StatementLineItem({
    required this.label,
    required this.currentAmount,
    required this.previousAmount,
    required this.percentChange,
    this.isPositive = true,
    this.isHeader = false,
    this.isTotal = false,
    this.isHighlight = false,
  });
}

class FinancialStatementFilterState {
  final FinancialReportType reportType;
  final String reportTypeLabel;
  final String dateRangeLabel;
  final String compareWith;
  final String trendPeriod;

  const FinancialStatementFilterState({
    this.reportType = FinancialReportType.profitAndLoss,
    this.reportTypeLabel = 'Profit & Loss Statement',
    this.dateRangeLabel = '01 Apr 2026 – 31 May 2026',
    this.compareWith = 'Previous Period',
    this.trendPeriod = 'Last 6 Months',
  });

  FinancialStatementFilterState copyWith({
    FinancialReportType? reportType,
    String? reportTypeLabel,
    String? dateRangeLabel,
    String? compareWith,
    String? trendPeriod,
  }) {
    return FinancialStatementFilterState(
      reportType: reportType ?? this.reportType,
      reportTypeLabel: reportTypeLabel ?? this.reportTypeLabel,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      compareWith: compareWith ?? this.compareWith,
      trendPeriod: trendPeriod ?? this.trendPeriod,
    );
  }
}

class FinancialStatementNotifier extends StateNotifier<FinancialStatementFilterState> {
  FinancialStatementNotifier() : super(const FinancialStatementFilterState());

  void setReportType(FinancialReportType type, String label) {
    state = state.copyWith(reportType: type, reportTypeLabel: label);
  }

  void setDateRange(String label) {
    state = state.copyWith(dateRangeLabel: label);
  }

  void setCompareWith(String comp) {
    state = state.copyWith(compareWith: comp);
  }

  void setTrendPeriod(String period) {
    state = state.copyWith(trendPeriod: period);
  }
}

final financialStatementFilterProvider =
    StateNotifierProvider<FinancialStatementNotifier, FinancialStatementFilterState>((ref) {
  return FinancialStatementNotifier();
});

class ProfitTrendPoint {
  final String month;
  final double amount;
  final String label;

  const ProfitTrendPoint(this.month, this.amount, this.label);
}

class FinancialStatementsSummaryData {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double netProfitMargin;
  final double profitGrowthPercent;
  final List<StatementLineItem> incomeItems;
  final StatementLineItem totalIncomeItem;
  final List<StatementLineItem> expenseItems;
  final StatementLineItem totalExpenseItem;
  final StatementLineItem netProfitItem;
  final List<ProfitTrendPoint> trendPoints;

  const FinancialStatementsSummaryData({
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
  });
}

final financialStatementsDataProvider = Provider<FinancialStatementsSummaryData>((ref) {
  return const FinancialStatementsSummaryData(
    totalIncome: 1300430.00,
    totalExpenses: 1006950.00,
    netProfit: 293480.00,
    netProfitMargin: 22.56,
    profitGrowthPercent: 28.91,
    incomeItems: [
      StatementLineItem(
        label: 'Sales Revenue',
        currentAmount: 1275430.00,
        previousAmount: 1025300.00,
        percentChange: 24.42,
        isPositive: true,
      ),
      StatementLineItem(
        label: 'Other Income',
        currentAmount: 25000.00,
        previousAmount: 18500.00,
        percentChange: 35.14,
        isPositive: true,
      ),
    ],
    totalIncomeItem: StatementLineItem(
      label: 'Total Income',
      currentAmount: 1300430.00,
      previousAmount: 1043800.00,
      percentChange: 24.61,
      isPositive: true,
      isTotal: true,
    ),
    expenseItems: [
      StatementLineItem(
        label: 'Cost of Goods Sold',
        currentAmount: 625300.00,
        previousAmount: 510200.00,
        percentChange: 22.55,
        isPositive: true,
      ),
      StatementLineItem(
        label: 'Operating Expenses',
        currentAmount: 320450.00,
        previousAmount: 275300.00,
        percentChange: 16.39,
        isPositive: true,
      ),
      StatementLineItem(
        label: 'Administrative Expenses',
        currentAmount: 115200.00,
        previousAmount: 95400.00,
        percentChange: 20.78,
        isPositive: true,
      ),
      StatementLineItem(
        label: 'Other Expenses',
        currentAmount: 45000.00,
        previousAmount: 35250.00,
        percentChange: 27.66,
        isPositive: true,
      ),
    ],
    totalExpenseItem: StatementLineItem(
      label: 'Total Expenses',
      currentAmount: 1006950.00,
      previousAmount: 816150.00,
      percentChange: 23.38,
      isPositive: false,
      isTotal: true,
    ),
    netProfitItem: StatementLineItem(
      label: 'Net Profit',
      currentAmount: 293480.00,
      previousAmount: 227650.00,
      percentChange: 28.91,
      isPositive: true,
      isHighlight: true,
    ),
    trendPoints: [
      ProfitTrendPoint('Dec 2025', 110000.00, '₹1.1L'),
      ProfitTrendPoint('Jan 2026', 185000.00, '₹1.85L'),
      ProfitTrendPoint('Feb 2026', 170000.00, '₹1.7L'),
      ProfitTrendPoint('Mar 2026', 280000.00, '₹2.8L'),
      ProfitTrendPoint('Apr 2026', 172000.00, '₹1.72L'),
      ProfitTrendPoint('May 2026', 293480.00, '₹2.93L'),
    ],
  );
});
