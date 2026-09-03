import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/purchase_return_model.dart';

class PurchaseReturnFilterState {
  final String searchQuery;
  final String selectedStatus; // 'All', 'Draft', 'Confirmed', 'Adjusted', 'Refunded', 'Cancelled'
  final String sortBy;
  final int currentPage;
  final int rowsPerPage;

  const PurchaseReturnFilterState({
    this.searchQuery = '',
    this.selectedStatus = 'All',
    this.sortBy = 'Date (Newest)',
    this.currentPage = 1,
    this.rowsPerPage = 10,
  });

  PurchaseReturnFilterState copyWith({
    String? searchQuery,
    String? selectedStatus,
    String? sortBy,
    int? currentPage,
    int? rowsPerPage,
  }) {
    return PurchaseReturnFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
      currentPage: currentPage ?? this.currentPage,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
    );
  }
}

class PurchaseReturnNotifier extends StateNotifier<List<PurchaseReturn>> {
  PurchaseReturnNotifier() : super(_initialMockReturns);

  static final List<PurchaseReturn> _initialMockReturns = [
    PurchaseReturn(
      id: 'pr_001',
      debitNoteNumber: 'DN/26-27/001',
      originalPurchaseId: 'pur_101',
      originalPurchaseBillNumber: 'PUR-2026-0045',
      supplierId: 'sup_01',
      supplierName: 'Apex Electronics Ltd',
      supplierGstin: '27AAAAA0000A1Z5',
      returnDate: DateTime(2026, 5, 24),
      items: const [
        PurchaseReturnItem(
          id: 'pri_01',
          productId: 'prod_01',
          productName: 'Wireless Bluetooth Headphones',
          hsnCode: '85183000',
          quantityReturned: 5,
          unit: 'PCS',
          unitPrice: 1500.0,
          gstRate: 18.0,
          taxAmount: 1350.0,
          totalAmount: 8850.0,
          returnReason: 'Defective Audio / Mic Issue',
        ),
        PurchaseReturnItem(
          id: 'pri_02',
          productId: 'prod_02',
          productName: 'USB-C Fast Charging Cable 2M',
          hsnCode: '85444299',
          quantityReturned: 10,
          unit: 'PCS',
          unitPrice: 350.0,
          gstRate: 18.0,
          taxAmount: 630.0,
          totalAmount: 4130.0,
          returnReason: 'Damaged in transit packaging',
        ),
      ],
      subtotal: 11000.00,
      taxAmount: 1980.00,
      totalAmount: 12980.00,
      amountAdjusted: 12980.00,
      status: PurchaseReturnStatus.adjusted,
      returnReason: 'Defective and Damaged Goods',
      notes: 'Debit Note issued and adjusted against next supplier invoice.',
    ),
    PurchaseReturn(
      id: 'pr_002',
      debitNoteNumber: 'DN/26-27/002',
      originalPurchaseId: 'pur_102',
      originalPurchaseBillNumber: 'PUR-2026-0052',
      supplierId: 'sup_02',
      supplierName: 'Global Traders Pvt Ltd',
      supplierGstin: '29BBBBB1111B2Z6',
      returnDate: DateTime(2026, 5, 22),
      items: const [
        PurchaseReturnItem(
          id: 'pri_03',
          productId: 'prod_03',
          productName: 'Ultra HD 4K LED Monitor 27"',
          hsnCode: '85285200',
          quantityReturned: 2,
          unit: 'PCS',
          unitPrice: 18000.0,
          gstRate: 18.0,
          taxAmount: 6480.0,
          totalAmount: 42480.0,
          returnReason: 'Dead pixels on screen display',
        ),
      ],
      subtotal: 36000.00,
      taxAmount: 6480.00,
      totalAmount: 42480.00,
      amountAdjusted: 0.0,
      status: PurchaseReturnStatus.confirmed,
      returnReason: 'Screen defect found during QA testing',
      notes: 'Awaiting supplier credit approval or bank refund.',
    ),
    PurchaseReturn(
      id: 'pr_003',
      debitNoteNumber: 'DN/26-27/003',
      originalPurchaseId: 'pur_103',
      originalPurchaseBillNumber: 'PUR-2026-0060',
      supplierId: 'sup_03',
      supplierName: 'Vertex Logistics & Supplies',
      supplierGstin: '07CCCCC2222C3Z7',
      returnDate: DateTime(2026, 5, 20),
      items: const [
        PurchaseReturnItem(
          id: 'pri_04',
          productId: 'prod_04',
          productName: 'Ergonomic Mesh Office Chair',
          hsnCode: '94013000',
          quantityReturned: 4,
          unit: 'PCS',
          unitPrice: 5500.0,
          gstRate: 18.0,
          taxAmount: 3960.0,
          totalAmount: 25960.0,
          returnReason: 'Wrong color model supplied',
        ),
      ],
      subtotal: 22000.00,
      taxAmount: 3960.00,
      totalAmount: 25960.00,
      amountAdjusted: 25960.00,
      status: PurchaseReturnStatus.refunded,
      returnReason: 'Incorrect specification delivered',
      notes: 'Supplier refunded amount via NEFT.',
    ),
    PurchaseReturn(
      id: 'pr_004',
      debitNoteNumber: 'DN/26-27/004',
      originalPurchaseId: 'pur_104',
      originalPurchaseBillNumber: 'PUR-2026-0068',
      supplierId: 'sup_04',
      supplierName: 'Premier Wholesale Distributors',
      supplierGstin: '19DDDDD3333D4Z8',
      returnDate: DateTime(2026, 5, 18),
      items: const [
        PurchaseReturnItem(
          id: 'pri_05',
          productId: 'prod_05',
          productName: 'Mechanical Gaming Keyboard RGB',
          hsnCode: '84716060',
          quantityReturned: 6,
          unit: 'PCS',
          unitPrice: 2200.0,
          gstRate: 18.0,
          taxAmount: 2376.0,
          totalAmount: 15576.0,
          returnReason: 'Key switches not functioning',
        ),
      ],
      subtotal: 13200.00,
      taxAmount: 2376.00,
      totalAmount: 15576.00,
      amountAdjusted: 0.0,
      status: PurchaseReturnStatus.draft,
      returnReason: 'Defective batches',
      notes: 'Draft debit note created for review.',
    ),
    PurchaseReturn(
      id: 'pr_005',
      debitNoteNumber: 'DN/26-27/005',
      originalPurchaseId: 'pur_105',
      originalPurchaseBillNumber: 'PUR-2026-0074',
      supplierId: 'sup_05',
      supplierName: 'Om Paper Products & Stationery',
      supplierGstin: '24EEEEE4444E5Z9',
      returnDate: DateTime(2026, 5, 15),
      items: const [
        PurchaseReturnItem(
          id: 'pri_06',
          productId: 'prod_06',
          productName: 'A4 Copier Paper 75 GSM (Box of 5)',
          hsnCode: '48025690',
          quantityReturned: 20,
          unit: 'BOX',
          unitPrice: 1100.0,
          gstRate: 12.0,
          taxAmount: 2640.0,
          totalAmount: 24640.0,
          returnReason: 'Water damaged outer boxes',
        ),
      ],
      subtotal: 22000.00,
      taxAmount: 2640.00,
      totalAmount: 24640.00,
      amountAdjusted: 24640.00,
      status: PurchaseReturnStatus.adjusted,
      returnReason: 'Water damage in monsoon transit',
      notes: 'Offset against current outstanding balance.',
    ),
  ];

  void addReturn(PurchaseReturn item) {
    state = [item, ...state];
  }

  void updateReturn(PurchaseReturn item) {
    state = state.map((r) => r.id == item.id ? item : r).toList();
  }

  void deleteReturn(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void updateStatus(String id, PurchaseReturnStatus status) {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(status: status);
      }
      return r;
    }).toList();
  }
}

final purchaseReturnsProvider =
    StateNotifierProvider<PurchaseReturnNotifier, List<PurchaseReturn>>((ref) {
  return PurchaseReturnNotifier();
});

class PurchaseReturnFilterNotifier extends StateNotifier<PurchaseReturnFilterState> {
  PurchaseReturnFilterNotifier() : super(const PurchaseReturnFilterState());

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q, currentPage: 1);
  void setSelectedStatus(String s) => state = state.copyWith(selectedStatus: s, currentPage: 1);
  void setSortBy(String s) => state = state.copyWith(sortBy: s);
  void setPage(int p) => state = state.copyWith(currentPage: p);
  void reset() => state = const PurchaseReturnFilterState();
}

final purchaseReturnFilterProvider =
    StateNotifierProvider<PurchaseReturnFilterNotifier, PurchaseReturnFilterState>((ref) {
  return PurchaseReturnFilterNotifier();
});

class PurchaseReturnMetrics {
  final int totalReturnsCount;
  final double totalReturnValue;
  final double adjustedAgainstBills;
  final double pendingRefunds;
  final List<PurchaseReturn> filteredItems;

  const PurchaseReturnMetrics({
    required this.totalReturnsCount,
    required this.totalReturnValue,
    required this.adjustedAgainstBills,
    required this.pendingRefunds,
    required this.filteredItems,
  });
}

final purchaseReturnMetricsProvider = Provider<PurchaseReturnMetrics>((ref) {
  final allReturns = ref.watch(purchaseReturnsProvider);
  final filter = ref.watch(purchaseReturnFilterProvider);

  final totalCount = allReturns.length;
  final totalValue = allReturns.fold(0.0, (sum, r) => sum + r.totalAmount);
  final adjusted = allReturns
      .where((r) => r.status == PurchaseReturnStatus.adjusted || r.status == PurchaseReturnStatus.refunded)
      .fold(0.0, (sum, r) => sum + r.amountAdjusted);
  final pending = allReturns
      .where((r) => r.status == PurchaseReturnStatus.confirmed || r.status == PurchaseReturnStatus.draft)
      .fold(0.0, (sum, r) => sum + (r.totalAmount - r.amountAdjusted));

  var filtered = List<PurchaseReturn>.from(allReturns);

  // Status filter
  if (filter.selectedStatus != 'All') {
    filtered = filtered.where((r) => r.status.name.toLowerCase() == filter.selectedStatus.toLowerCase()).toList();
  }

  // Search filter
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    filtered = filtered.where((r) {
      return r.debitNoteNumber.toLowerCase().contains(q) ||
          r.originalPurchaseBillNumber.toLowerCase().contains(q) ||
          r.supplierName.toLowerCase().contains(q) ||
          r.returnReason.toLowerCase().contains(q);
    }).toList();
  }

  // Sort
  if (filter.sortBy == 'Date (Newest)') {
    filtered.sort((a, b) => b.returnDate.compareTo(a.returnDate));
  } else if (filter.sortBy == 'Date (Oldest)') {
    filtered.sort((a, b) => a.returnDate.compareTo(b.returnDate));
  } else if (filter.sortBy == 'Amount (High to Low)') {
    filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  } else if (filter.sortBy == 'Amount (Low to High)') {
    filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
  }

  return PurchaseReturnMetrics(
    totalReturnsCount: totalCount,
    totalReturnValue: totalValue,
    adjustedAgainstBills: adjusted,
    pendingRefunds: pending,
    filteredItems: filtered,
  );
});
