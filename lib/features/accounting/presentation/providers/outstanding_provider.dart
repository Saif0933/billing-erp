import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/outstanding_dto.dart';
import '../../data/services/outstanding_api_service.dart';
import '../../../../core/models/billing_models.dart';

/// Provider for OutstandingApiService
final outstandingApiServiceProvider = Provider<OutstandingApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OutstandingApiService(apiClient);
});

/// State for the Outstanding Analysis dashboard
class OutstandingState {
  final String selectedTab; // 'Receivables' or 'Payables'
  final String statusFilter; // 'All', 'OVERDUE', 'DUE TODAY', 'PENDING'
  final String bucketFilter; // 'ALL', '0-30', '31-60', '61-90', '91+'
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final OutstandingSummaryResponseDto? summary;
  final List<OutstandingItemDto> items;
  final bool isUsingLocalFallback;

  const OutstandingState({
    this.selectedTab = 'Receivables',
    this.statusFilter = 'All',
    this.bucketFilter = 'ALL',
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.summary,
    this.items = const [],
    this.isUsingLocalFallback = false,
  });

  OutstandingState copyWith({
    String? selectedTab,
    String? statusFilter,
    String? bucketFilter,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
    OutstandingSummaryResponseDto? summary,
    List<OutstandingItemDto>? items,
    bool? isUsingLocalFallback,
  }) {
    return OutstandingState(
      selectedTab: selectedTab ?? this.selectedTab,
      statusFilter: statusFilter ?? this.statusFilter,
      bucketFilter: bucketFilter ?? this.bucketFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      summary: summary ?? this.summary,
      items: items ?? this.items,
      isUsingLocalFallback: isUsingLocalFallback ?? this.isUsingLocalFallback,
    );
  }
}

class OutstandingNotifier extends StateNotifier<OutstandingState> {
  final OutstandingApiService _apiService;
  final Ref _ref;

  OutstandingNotifier(this._apiService, this._ref) : super(const OutstandingState()) {
    loadData();
  }

  /// Load live outstanding data from backend with fallback to local repository
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final summary = await _apiService.getSummary();

      final listRes = state.selectedTab == 'Receivables'
          ? await _apiService.getReceivables(
              status: state.statusFilter == 'All' ? 'ALL' : state.statusFilter,
              bucket: state.bucketFilter,
              search: state.searchQuery,
            )
          : await _apiService.getPayables(
              status: state.statusFilter == 'All' ? 'ALL' : state.statusFilter,
              bucket: state.bucketFilter,
              search: state.searchQuery,
            );

      state = state.copyWith(
        isLoading: false,
        summary: summary,
        items: listRes.items,
        isUsingLocalFallback: false,
      );
    } catch (_) {
      // Graceful fallback to local repository
      _computeFromLocalRepository();
    }
  }

  void setTab(String tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab, items: [], bucketFilter: 'ALL');
    loadData();
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    loadData();
  }

  void setBucketFilter(String bucket) {
    state = state.copyWith(bucketFilter: bucket);
    loadData();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }

  /// Fallback computation directly from BillingRepository in case server is unreachable
  void _computeFromLocalRepository() {
    final billingState = _ref.read(billingRepositoryProvider);
    final now = DateTime.now();

    double bucket0To30 = 0.0;
    double bucket31To60 = 0.0;
    double bucket61To90 = 0.0;
    double bucket91Plus = 0.0;
    double totalOutstanding = 0.0;
    double dueToday = 0.0;
    double totalOverdue = 0.0;
    double totalPending = 0.0;

    List<OutstandingItemDto> items = [];

    if (state.selectedTab == 'Receivables') {
      final activeInvoices = billingState.invoices.where(
        (inv) =>
            inv.status != InvoiceStatus.paid &&
            inv.status != InvoiceStatus.cancelled &&
            !inv.isCreditNote,
      );

      for (var inv in activeInvoices) {
        final diffDays = now.difference(inv.invoiceDate).inDays;
        final customer = billingState.customers.cast<Customer?>().firstWhere(
              (c) => c?.id == inv.customerId,
              orElse: () => null,
            );
        final creditDays = customer?.creditPeriod ?? 30;
        final dueDate = inv.invoiceDate.add(Duration(days: creditDays > 0 ? creditDays : 30));
        final isDueToday =
            now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;
        final isOverdue = now.isAfter(dueDate) && !isDueToday;

        totalOutstanding += inv.balanceAmount;
        if (isDueToday) {
          dueToday += inv.balanceAmount;
        } else if (isOverdue) {
          totalOverdue += inv.balanceAmount;
        } else {
          totalPending += inv.balanceAmount;
        }

        String bucket = '91+';
        if (diffDays <= 30) {
          bucket0To30 += inv.balanceAmount;
          bucket = '0-30';
        } else if (diffDays <= 60) {
          bucket31To60 += inv.balanceAmount;
          bucket = '31-60';
        } else if (diffDays <= 90) {
          bucket61To90 += inv.balanceAmount;
          bucket = '61-90';
        } else {
          bucket91Plus += inv.balanceAmount;
        }

        final statusLabel = isOverdue ? 'OVERDUE' : (isDueToday ? 'DUE TODAY' : 'PENDING');

        items.add(
          OutstandingItemDto(
            id: inv.id,
            refNumber: inv.invoiceNumber,
            date: inv.invoiceDate,
            dueDate: dueDate,
            partyId: inv.customerId,
            partyName: inv.customerName,
            partyMobile: customer?.mobile,
            amount: inv.grandTotal,
            paidAmount: inv.grandTotal - inv.balanceAmount,
            balance: inv.balanceAmount,
            ageDays: diffDays,
            statusLabel: statusLabel,
            bucket: bucket,
          ),
        );
      }
    } else {
      final activePurchases = billingState.purchases.where(
        (p) =>
            p.status != PurchaseStatus.paid &&
            p.status != PurchaseStatus.cancelled &&
            !p.isDebitNote,
      );

      for (var p in activePurchases) {
        final diffDays = now.difference(p.purchaseDate).inDays;
        final supplier = billingState.suppliers.cast<Supplier?>().firstWhere(
              (s) => s?.id == p.supplierId,
              orElse: () => null,
            );
        final creditDays = supplier?.creditTerms ?? 30;
        final dueDate = p.purchaseDate.add(Duration(days: creditDays > 0 ? creditDays : 30));
        final isDueToday =
            now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;
        final isOverdue = now.isAfter(dueDate) && !isDueToday;

        totalOutstanding += p.balanceAmount;
        if (isDueToday) {
          dueToday += p.balanceAmount;
        } else if (isOverdue) {
          totalOverdue += p.balanceAmount;
        } else {
          totalPending += p.balanceAmount;
        }

        String bucket = '91+';
        if (diffDays <= 30) {
          bucket0To30 += p.balanceAmount;
          bucket = '0-30';
        } else if (diffDays <= 60) {
          bucket31To60 += p.balanceAmount;
          bucket = '31-60';
        } else if (diffDays <= 90) {
          bucket61To90 += p.balanceAmount;
          bucket = '61-90';
        } else {
          bucket91Plus += p.balanceAmount;
        }

        final statusLabel = isOverdue ? 'OVERDUE' : (isDueToday ? 'DUE TODAY' : 'PENDING');

        items.add(
          OutstandingItemDto(
            id: p.id,
            refNumber: p.purchaseNumber,
            date: p.purchaseDate,
            dueDate: dueDate,
            partyId: p.supplierId,
            partyName: p.supplierName,
            partyMobile: supplier?.mobile,
            amount: p.grandTotal,
            paidAmount: p.grandTotal - p.balanceAmount,
            balance: p.balanceAmount,
            ageDays: diffDays,
            statusLabel: statusLabel,
            bucket: bucket,
          ),
        );
      }
    }

    final catSummary = OutstandingCategorySummaryDto(
      totalOutstanding: totalOutstanding,
      dueToday: dueToday,
      totalOverdue: totalOverdue,
      totalPending: totalPending,
      count: items.length,
      ageingBuckets: AgeingBucketsDto(
        bucket0To30: bucket0To30,
        bucket31To60: bucket31To60,
        bucket61To90: bucket61To90,
        bucket91Plus: bucket91Plus,
      ),
    );

    final summary = state.selectedTab == 'Receivables'
        ? OutstandingSummaryResponseDto(
            receivables: catSummary,
            netWorkingCapital: totalOutstanding,
          )
        : OutstandingSummaryResponseDto(
            payables: catSummary,
            netWorkingCapital: -totalOutstanding,
          );

    // Apply filtering to items based on active filters in state
    var filteredItems = items;
    final stFilter = state.statusFilter.toUpperCase();
    if (stFilter != 'ALL') {
      filteredItems = filteredItems.where((i) => i.statusLabel.toUpperCase() == stFilter).toList();
    }
    final bkFilter = state.bucketFilter.toUpperCase();
    if (bkFilter != 'ALL') {
      filteredItems = filteredItems.where((i) => i.bucket == state.bucketFilter).toList();
    }
    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.trim().toLowerCase();
      filteredItems = filteredItems
          .where((i) =>
              i.partyName.toLowerCase().contains(q) ||
              i.refNumber.toLowerCase().contains(q) ||
              (i.partyMobile != null && i.partyMobile!.contains(q)))
          .toList();
    }

    state = state.copyWith(
      isLoading: false,
      summary: summary,
      items: filteredItems,
      isUsingLocalFallback: true,
    );
  }
}

final outstandingProvider =
    StateNotifierProvider<OutstandingNotifier, OutstandingState>((ref) {
  final apiService = ref.watch(outstandingApiServiceProvider);
  return OutstandingNotifier(apiService, ref);
});
