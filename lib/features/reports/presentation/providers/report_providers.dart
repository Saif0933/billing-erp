import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/report_models.dart';
import '../../data/services/report_api_service.dart';

class ReportsState {
  final bool isLoading;
  final bool isExporting;
  final String? error;
  final DateTimeRange dateRange;
  final String warehouseId;
  final SalesRegisterData? salesData;
  final PurchaseRegisterData? purchaseData;
  final GstLiabilitySummary? gstData;
  final StockValuationData? stockData;

  ReportsState({
    this.isLoading = false,
    this.isExporting = false,
    this.error,
    DateTimeRange? dateRange,
    this.warehouseId = 'all',
    this.salesData,
    this.purchaseData,
    this.gstData,
    this.stockData,
  }) : dateRange = dateRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now().add(const Duration(days: 1)),
            );

  ReportsState copyWith({
    bool? isLoading,
    bool? isExporting,
    String? error,
    bool clearError = false,
    DateTimeRange? dateRange,
    String? warehouseId,
    SalesRegisterData? salesData,
    PurchaseRegisterData? purchaseData,
    GstLiabilitySummary? gstData,
    StockValuationData? stockData,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      error: clearError ? null : (error ?? this.error),
      dateRange: dateRange ?? this.dateRange,
      warehouseId: warehouseId ?? this.warehouseId,
      salesData: salesData ?? this.salesData,
      purchaseData: purchaseData ?? this.purchaseData,
      gstData: gstData ?? this.gstData,
      stockData: stockData ?? this.stockData,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportApiService _apiService;

  ReportsNotifier(this._apiService) : super(ReportsState()) {
    loadAllReports();
  }

  /// Load all 4 report datasets from backend concurrently
  Future<void> loadAllReports() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _apiService.getSalesRegister(
          startDate: state.dateRange.start,
          endDate: state.dateRange.end,
          warehouseId: state.warehouseId,
        ),
        _apiService.getPurchaseRegister(
          startDate: state.dateRange.start,
          endDate: state.dateRange.end,
          warehouseId: state.warehouseId,
        ),
        _apiService.getGstSummary(
          startDate: state.dateRange.start,
          endDate: state.dateRange.end,
        ),
        _apiService.getStockValuation(
          warehouseId: state.warehouseId,
        ),
      ]);

      state = state.copyWith(
        isLoading: false,
        salesData: results[0] as SalesRegisterData,
        purchaseData: results[1] as PurchaseRegisterData,
        gstData: results[2] as GstLiabilitySummary,
        stockData: results[3] as StockValuationData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update selected date range and refresh relevant backend reports
  void updateDateRange(DateTimeRange range) {
    state = state.copyWith(dateRange: range);
    loadAllReports();
  }

  /// Update selected warehouse filter and refresh relevant backend reports
  void updateWarehouse(String warehouseId) {
    state = state.copyWith(warehouseId: warehouseId);
    loadAllReports();
  }

  /// Trigger report export on backend
  Future<ReportExportResult?> exportReport({
    required String reportType,
    required String format,
    String? reportName,
  }) async {
    state = state.copyWith(isExporting: true);
    try {
      final result = await _apiService.exportReport(
        reportType: reportType,
        format: format,
        reportName: reportName,
        startDate: state.dateRange.start,
        endDate: state.dateRange.end,
        warehouseId: state.warehouseId,
      );
      state = state.copyWith(isExporting: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Export failed: $e',
      );
      return null;
    }
  }
}

final reportsStateProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final apiService = ref.watch(reportApiServiceProvider);
  return ReportsNotifier(apiService);
});
