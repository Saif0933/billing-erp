import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/financial_statement_dto.dart';
import '../../data/services/financial_statement_api_service.dart';

// Re-export DTO classes for seamless usage
export '../../data/models/financial_statement_dto.dart'
    show
        StatementLineItemDto,
        ProfitTrendPointDto,
        StatementSectionDto,
        FinancialDonutSegmentDto,
        FinancialStatementSummaryDto,
        FinancialStatementResponseDto;

// Backward-compatibility typedefs
typedef StatementLineItem = StatementLineItemDto;
typedef StatementSection = StatementSectionDto;
typedef FinancialDonutSegment = FinancialDonutSegmentDto;

enum FinancialReportType {
  profitAndLoss,
  balanceSheet,
  cashFlow,
  equityChanges,
}

String reportTypeToSlug(FinancialReportType type) {
  switch (type) {
    case FinancialReportType.profitAndLoss:
      return 'profitAndLoss';
    case FinancialReportType.balanceSheet:
      return 'balanceSheet';
    case FinancialReportType.cashFlow:
      return 'cashFlow';
    case FinancialReportType.equityChanges:
      return 'equityChanges';
  }
}

FinancialReportType slugToReportType(String slug) {
  final val = slug.toLowerCase();
  if (val.contains('balance') || val == 'bs') return FinancialReportType.balanceSheet;
  if (val.contains('cash') || val == 'cf') return FinancialReportType.cashFlow;
  if (val.contains('equity') || val == 'eq') return FinancialReportType.equityChanges;
  return FinancialReportType.profitAndLoss;
}

class ProfitTrendPoint {
  final String month;
  final double amount;
  final String label;

  const ProfitTrendPoint(this.month, this.amount, this.label);

  factory ProfitTrendPoint.fromDto(ProfitTrendPointDto dto) {
    return ProfitTrendPoint(dto.month, dto.amount, dto.label);
  }
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

/// Data holder model for UI presentation with loading & error information
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
  final List<StatementSectionDto> sections;
  final List<FinancialDonutSegmentDto> donutBreakdown;
  final String currentPeriodLabel;
  final String previousPeriodLabel;
  final String companyName;
  final bool isLoading;
  final String? errorMessage;

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
    this.sections = const [],
    this.donutBreakdown = const [],
    this.currentPeriodLabel = '01 Apr 2026 – 31 May 2026',
    this.previousPeriodLabel = '01 Feb – 31 Mar 2026',
    this.companyName = 'Tax Bunny Retail Store',
    this.isLoading = false,
    this.errorMessage,
  });

  factory FinancialStatementsSummaryData.fromResponse(FinancialStatementResponseDto resp) {
    final sum = resp.summary;
    final points = resp.trendPoints.map((p) => ProfitTrendPoint.fromDto(p)).toList();

    return FinancialStatementsSummaryData(
      totalIncome: sum.totalIncome,
      totalExpenses: sum.totalExpenses,
      netProfit: sum.netProfit,
      netProfitMargin: sum.netProfitMargin,
      profitGrowthPercent: sum.profitGrowthPercent,
      incomeItems: sum.incomeItems,
      totalIncomeItem: sum.totalIncomeItem,
      expenseItems: sum.expenseItems,
      totalExpenseItem: sum.totalExpenseItem,
      netProfitItem: resp.bannerItem ?? sum.netProfitItem,
      trendPoints: points,
      sections: resp.sections,
      donutBreakdown: sum.donutBreakdown,
      currentPeriodLabel: resp.currentPeriodLabel,
      previousPeriodLabel: resp.previousPeriodLabel,
      companyName: resp.companyName,
      isLoading: false,
    );
  }

  factory FinancialStatementsSummaryData.loading({FinancialStatementFilterState? filter}) {
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
      isLoading: true,
    );
  }

  factory FinancialStatementsSummaryData.error(String message, {FinancialStatementFilterState? filter}) {
    return FinancialStatementsSummaryData(
      totalIncome: 1300430.00,
      totalExpenses: 1006950.00,
      netProfit: 293480.00,
      netProfitMargin: 22.56,
      profitGrowthPercent: 28.91,
      incomeItems: const [],
      totalIncomeItem: const StatementLineItem(
        label: 'Total Income',
        currentAmount: 1300430.00,
        previousAmount: 1043800.00,
        percentChange: 24.61,
        isTotal: true,
      ),
      expenseItems: const [],
      totalExpenseItem: const StatementLineItem(
        label: 'Total Expenses',
        currentAmount: 1006950.00,
        previousAmount: 816150.00,
        percentChange: 23.38,
        isTotal: true,
      ),
      netProfitItem: const StatementLineItem(
        label: 'Net Profit',
        currentAmount: 293480.00,
        previousAmount: 227650.00,
        percentChange: 28.91,
        isHighlight: true,
      ),
      trendPoints: const [],
      isLoading: false,
      errorMessage: message,
    );
  }
}

/// StateNotifier connecting the Financial Statements to backend API
class FinancialStatementsNotifier extends StateNotifier<AsyncValue<FinancialStatementResponseDto>> {
  final FinancialStatementApiService _apiService;
  final Ref _ref;

  FinancialStatementsNotifier(this._apiService, this._ref) : super(const AsyncValue.loading()) {
    // Listen to filter state updates and re-fetch statement
    _ref.listen<FinancialStatementFilterState>(financialStatementFilterProvider, (prev, next) {
      if (prev?.reportType != next.reportType ||
          prev?.dateRangeLabel != next.dateRangeLabel ||
          prev?.compareWith != next.compareWith ||
          prev?.trendPeriod != next.trendPeriod) {
        fetchStatement();
      }
    });

    fetchStatement();
  }

  /// Fetch financial statement from backend
  Future<void> fetchStatement({bool showLoading = true}) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }

    try {
      final filter = _ref.read(financialStatementFilterProvider);
      final response = await _apiService.getFinancialStatement(
        reportType: reportTypeToSlug(filter.reportType),
        dateRangeLabel: filter.dateRangeLabel,
        compareWith: filter.compareWith,
        trendPeriod: filter.trendPeriod,
      );

      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Silently refresh financial statement
  Future<void> refresh() async {
    await fetchStatement(showLoading: false);
  }

  /// Export financial statement
  Future<Map<String, dynamic>> exportStatement({String format = 'csv'}) async {
    final filter = _ref.read(financialStatementFilterProvider);
    return _apiService.exportStatement(
      format: format,
      reportType: reportTypeToSlug(filter.reportType),
      dateRangeLabel: filter.dateRangeLabel,
    );
  }

  /// Save active report layout
  Future<Map<String, dynamic>> saveLayout(String layoutName) async {
    final filter = _ref.read(financialStatementFilterProvider);
    return _apiService.saveLayout({
      'layoutName': layoutName,
      'reportType': reportTypeToSlug(filter.reportType),
      'compareWith': filter.compareWith,
      'trendPeriod': filter.trendPeriod,
    });
  }

  /// Schedule report delivery
  Future<Map<String, dynamic>> scheduleReport({
    required String frequency,
    required List<String> recipients,
    String format = 'pdf',
  }) async {
    final filter = _ref.read(financialStatementFilterProvider);
    return _apiService.scheduleReport({
      'reportType': reportTypeToSlug(filter.reportType),
      'frequency': frequency,
      'recipients': recipients,
      'format': format,
    });
  }

  /// Create custom report
  Future<Map<String, dynamic>> createCustomReport({
    required String reportName,
    List<String>? sections,
  }) async {
    final filter = _ref.read(financialStatementFilterProvider);
    return _apiService.createCustomReport({
      'reportName': reportName,
      'reportType': reportTypeToSlug(filter.reportType),
      'sections': sections ?? [],
    });
  }
}

final financialStatementsNotifierProvider =
    StateNotifierProvider<FinancialStatementsNotifier, AsyncValue<FinancialStatementResponseDto>>((ref) {
  final apiService = ref.watch(financialStatementApiServiceProvider);
  return FinancialStatementsNotifier(apiService, ref);
});

/// Primary presentation provider that reads from dynamic backend state
final financialStatementsDataProvider = Provider<FinancialStatementsSummaryData>((ref) {
  final asyncVal = ref.watch(financialStatementsNotifierProvider);
  final filter = ref.watch(financialStatementFilterProvider);

  return asyncVal.when(
    data: (resp) => FinancialStatementsSummaryData.fromResponse(resp),
    loading: () => FinancialStatementsSummaryData.loading(filter: filter),
    error: (err, _) => FinancialStatementsSummaryData.error(err.toString(), filter: filter),
  );
});
