enum PurchaseReturnStatus {
  draft,
  confirmed,
  adjusted,
  refunded,
  cancelled,
}

class PurchaseReturnItem {
  final String id;
  final String productId;
  final String productName;
  final String hsnCode;
  final double quantityReturned;
  final String unit;
  final double unitPrice;
  final double gstRate;
  final double taxAmount;
  final double totalAmount;
  final String returnReason;

  const PurchaseReturnItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.hsnCode = '',
    required this.quantityReturned,
    this.unit = 'PCS',
    required this.unitPrice,
    required this.gstRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.returnReason,
  });
}

class PurchaseReturn {
  final String id;
  final String debitNoteNumber;
  final String originalPurchaseId;
  final String originalPurchaseBillNumber;
  final String supplierId;
  final String supplierName;
  final String supplierGstin;
  final DateTime returnDate;
  final List<PurchaseReturnItem> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double amountAdjusted;
  final PurchaseReturnStatus status;
  final String returnReason;
  final String notes;

  const PurchaseReturn({
    required this.id,
    required this.debitNoteNumber,
    required this.originalPurchaseId,
    required this.originalPurchaseBillNumber,
    required this.supplierId,
    required this.supplierName,
    this.supplierGstin = '',
    required this.returnDate,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.amountAdjusted = 0.0,
    required this.status,
    required this.returnReason,
    this.notes = '',
  });

  PurchaseReturn copyWith({
    String? id,
    String? debitNoteNumber,
    String? originalPurchaseId,
    String? originalPurchaseBillNumber,
    String? supplierId,
    String? supplierName,
    String? supplierGstin,
    DateTime? returnDate,
    List<PurchaseReturnItem>? items,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    double? amountAdjusted,
    PurchaseReturnStatus? status,
    String? returnReason,
    String? notes,
  }) {
    return PurchaseReturn(
      id: id ?? this.id,
      debitNoteNumber: debitNoteNumber ?? this.debitNoteNumber,
      originalPurchaseId: originalPurchaseId ?? this.originalPurchaseId,
      originalPurchaseBillNumber: originalPurchaseBillNumber ?? this.originalPurchaseBillNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierGstin: supplierGstin ?? this.supplierGstin,
      returnDate: returnDate ?? this.returnDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountAdjusted: amountAdjusted ?? this.amountAdjusted,
      status: status ?? this.status,
      returnReason: returnReason ?? this.returnReason,
      notes: notes ?? this.notes,
    );
  }
}
