import '../../domain/models/purchase_return_model.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

PurchaseReturnStatus _parseStatus(dynamic value) {
  final raw = (value?.toString() ?? 'draft').trim().toLowerCase();
  switch (raw) {
    case 'confirmed':
      return PurchaseReturnStatus.confirmed;
    case 'adjusted':
      return PurchaseReturnStatus.adjusted;
    case 'refunded':
      return PurchaseReturnStatus.refunded;
    case 'cancelled':
    case 'canceled':
      return PurchaseReturnStatus.cancelled;
    case 'draft':
    default:
      return PurchaseReturnStatus.draft;
  }
}

String statusToApi(PurchaseReturnStatus status) {
  switch (status) {
    case PurchaseReturnStatus.confirmed:
      return 'CONFIRMED';
    case PurchaseReturnStatus.adjusted:
      return 'ADJUSTED';
    case PurchaseReturnStatus.refunded:
      return 'REFUNDED';
    case PurchaseReturnStatus.cancelled:
      return 'CANCELLED';
    case PurchaseReturnStatus.draft:
      return 'DRAFT';
  }
}

class PurchaseReturnItemDto {
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

  const PurchaseReturnItemDto({
    required this.id,
    required this.productId,
    required this.productName,
    this.hsnCode = '',
    required this.quantityReturned,
    this.unit = 'PCS',
    required this.unitPrice,
    this.gstRate = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.returnReason = '',
  });

  factory PurchaseReturnItemDto.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnItemDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ??
          json['name']?.toString() ??
          '',
      hsnCode: json['hsnCode']?.toString() ?? '',
      quantityReturned: _parseDouble(
        json['quantityReturned'] ?? json['quantity'],
      ),
      unit: json['unit']?.toString() ?? 'PCS',
      unitPrice: _parseDouble(json['unitPrice'] ?? json['rate']),
      gstRate: _parseDouble(json['gstRate'] ?? json['gstRatePercent']),
      taxAmount: _parseDouble(json['taxAmount'] ?? json['gstAmount']),
      totalAmount: _parseDouble(json['totalAmount'] ?? json['lineTotal']),
      returnReason: json['returnReason']?.toString() ?? '',
    );
  }

  PurchaseReturnItem toDomain() {
    return PurchaseReturnItem(
      id: id,
      productId: productId,
      productName: productName,
      hsnCode: hsnCode,
      quantityReturned: quantityReturned,
      unit: unit,
      unitPrice: unitPrice,
      gstRate: gstRate,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      returnReason: returnReason,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'productId': productId,
      'productName': productName,
      'hsnCode': hsnCode,
      'unit': unit,
      'quantity': quantityReturned,
      'quantityReturned': quantityReturned,
      'rate': unitPrice,
      'unitPrice': unitPrice,
      'gstRate': gstRate,
      'gstRatePercent': gstRate,
      'taxableValue': unitPrice * quantityReturned,
      'gstAmount': taxAmount,
      'taxAmount': taxAmount,
      'lineTotal': totalAmount,
      'totalAmount': totalAmount,
      'returnReason': returnReason,
    };
  }
}

class PurchaseReturnDto {
  final String id;
  final String debitNoteNumber;
  final String originalPurchaseId;
  final String originalPurchaseBillNumber;
  final String supplierId;
  final String supplierName;
  final String supplierGstin;
  final DateTime returnDate;
  final List<PurchaseReturnItemDto> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double amountAdjusted;
  final PurchaseReturnStatus status;
  final String returnReason;
  final String notes;

  const PurchaseReturnDto({
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
    this.amountAdjusted = 0,
    required this.status,
    required this.returnReason,
    this.notes = '',
  });

  factory PurchaseReturnDto.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => PurchaseReturnItemDto.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <PurchaseReturnItemDto>[];

    return PurchaseReturnDto(
      id: json['id']?.toString() ?? '',
      debitNoteNumber: json['debitNoteNumber']?.toString() ??
          json['noteNumber']?.toString() ??
          '',
      originalPurchaseId: json['originalPurchaseId']?.toString() ??
          json['purchaseId']?.toString() ??
          '',
      originalPurchaseBillNumber:
          json['originalPurchaseBillNumber']?.toString() ??
              json['purchaseNumber']?.toString() ??
              '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ??
          (json['supplier'] is Map
              ? json['supplier']['name']?.toString() ?? ''
              : ''),
      supplierGstin: json['supplierGstin']?.toString() ??
          (json['supplier'] is Map
              ? json['supplier']['gstin']?.toString() ?? ''
              : ''),
      returnDate: _parseDate(json['returnDate']),
      items: items,
      subtotal: _parseDouble(json['subtotal'] ?? json['taxableValue']),
      taxAmount: _parseDouble(json['taxAmount'] ?? json['gstAmount']),
      totalAmount: _parseDouble(json['totalAmount']),
      amountAdjusted: _parseDouble(json['amountAdjusted']),
      status: _parseStatus(json['status']),
      returnReason:
          json['returnReason']?.toString() ?? json['reason']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  factory PurchaseReturnDto.fromDomain(PurchaseReturn item) {
    return PurchaseReturnDto(
      id: item.id,
      debitNoteNumber: item.debitNoteNumber,
      originalPurchaseId: item.originalPurchaseId,
      originalPurchaseBillNumber: item.originalPurchaseBillNumber,
      supplierId: item.supplierId,
      supplierName: item.supplierName,
      supplierGstin: item.supplierGstin,
      returnDate: item.returnDate,
      items: item.items
          .map(
            (i) => PurchaseReturnItemDto(
              id: i.id,
              productId: i.productId,
              productName: i.productName,
              hsnCode: i.hsnCode,
              quantityReturned: i.quantityReturned,
              unit: i.unit,
              unitPrice: i.unitPrice,
              gstRate: i.gstRate,
              taxAmount: i.taxAmount,
              totalAmount: i.totalAmount,
              returnReason: i.returnReason,
            ),
          )
          .toList(),
      subtotal: item.subtotal,
      taxAmount: item.taxAmount,
      totalAmount: item.totalAmount,
      amountAdjusted: item.amountAdjusted,
      status: item.status,
      returnReason: item.returnReason,
      notes: item.notes,
    );
  }

  PurchaseReturn toDomain() {
    return PurchaseReturn(
      id: id,
      debitNoteNumber: debitNoteNumber,
      originalPurchaseId: originalPurchaseId,
      originalPurchaseBillNumber: originalPurchaseBillNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      supplierGstin: supplierGstin,
      returnDate: returnDate,
      items: items.map((e) => e.toDomain()).toList(),
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      amountAdjusted: amountAdjusted,
      status: status,
      returnReason: returnReason,
      notes: notes,
    );
  }

  Map<String, dynamic> toCreateJson({PurchaseReturnStatus? saveAs}) {
    return {
      'purchaseId': originalPurchaseId,
      'debitNoteNumber': debitNoteNumber,
      'noteNumber': debitNoteNumber,
      'returnDate': returnDate.toIso8601String(),
      'reason': returnReason,
      'returnReason': returnReason,
      'notes': notes,
      'status': statusToApi(saveAs ?? status),
      'amountAdjusted': amountAdjusted,
      'items': items.map((e) => e.toCreateJson()).toList(),
    };
  }
}

class PurchaseReturnListResponse {
  final List<PurchaseReturn> returns;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PurchaseReturnListResponse({
    required this.returns,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory PurchaseReturnListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['purchaseReturns'] ?? json['returns'] ?? json['data'];
    final items = list is List
        ? list
            .whereType<Map>()
            .map(
              (e) => PurchaseReturnDto.fromJson(Map<String, dynamic>.from(e))
                  .toDomain(),
            )
            .toList()
        : <PurchaseReturn>[];

    final pagination = json['pagination'];
    if (pagination is Map) {
      return PurchaseReturnListResponse(
        returns: items,
        total: int.tryParse(pagination['total']?.toString() ?? '') ??
            items.length,
        page: int.tryParse(pagination['page']?.toString() ?? '') ?? 1,
        limit: int.tryParse(pagination['limit']?.toString() ?? '') ?? 20,
        totalPages:
            int.tryParse(pagination['totalPages']?.toString() ?? '') ?? 1,
      );
    }

    return PurchaseReturnListResponse(
      returns: items,
      total: items.length,
      page: 1,
      limit: items.length,
      totalPages: 1,
    );
  }
}

class PurchaseReturnMetricsDto {
  final int totalReturnsCount;
  final double totalReturnValue;
  final double adjustedAgainstBills;
  final double pendingRefunds;

  const PurchaseReturnMetricsDto({
    this.totalReturnsCount = 0,
    this.totalReturnValue = 0,
    this.adjustedAgainstBills = 0,
    this.pendingRefunds = 0,
  });

  factory PurchaseReturnMetricsDto.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnMetricsDto(
      totalReturnsCount: int.tryParse(
            json['totalReturnsCount']?.toString() ?? '',
          ) ??
          0,
      totalReturnValue: _parseDouble(json['totalReturnValue']),
      adjustedAgainstBills: _parseDouble(json['adjustedAgainstBills']),
      pendingRefunds: _parseDouble(json['pendingRefunds']),
    );
  }
}

class EligiblePurchaseItemDto {
  final String id;
  final String productId;
  final String productName;
  final String hsnCode;
  final double quantity;
  final double alreadyReturned;
  final double remainingQty;
  final String unit;
  final double rate;
  final double gstRate;

  const EligiblePurchaseItemDto({
    required this.id,
    required this.productId,
    required this.productName,
    this.hsnCode = '',
    required this.quantity,
    this.alreadyReturned = 0,
    required this.remainingQty,
    this.unit = 'PCS',
    required this.rate,
    this.gstRate = 0,
  });

  factory EligiblePurchaseItemDto.fromJson(Map<String, dynamic> json) {
    return EligiblePurchaseItemDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString() ?? '',
      quantity: _parseDouble(json['quantity']),
      alreadyReturned: _parseDouble(json['alreadyReturned']),
      remainingQty: _parseDouble(json['remainingQty']),
      unit: json['unit']?.toString() ?? 'PCS',
      rate: _parseDouble(json['rate']),
      gstRate: _parseDouble(json['gstRate'] ?? json['gstRatePercent']),
    );
  }
}

class EligiblePurchaseDto {
  final String id;
  final String purchaseNumber;
  final String supplierInvoiceNumber;
  final String supplierId;
  final String supplierName;
  final String supplierGstin;
  final DateTime purchaseDate;
  final double totalAmount;
  final List<EligiblePurchaseItemDto> items;

  const EligiblePurchaseDto({
    required this.id,
    required this.purchaseNumber,
    this.supplierInvoiceNumber = '',
    required this.supplierId,
    required this.supplierName,
    this.supplierGstin = '',
    required this.purchaseDate,
    this.totalAmount = 0,
    this.items = const [],
  });

  factory EligiblePurchaseDto.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => EligiblePurchaseItemDto.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <EligiblePurchaseItemDto>[];

    return EligiblePurchaseDto(
      id: json['id']?.toString() ?? json['purchaseId']?.toString() ?? '',
      purchaseNumber: json['purchaseNumber']?.toString() ?? '',
      supplierInvoiceNumber: json['supplierInvoiceNumber']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      supplierGstin: json['supplierGstin']?.toString() ?? '',
      purchaseDate: _parseDate(json['purchaseDate']),
      totalAmount: _parseDouble(json['totalAmount']),
      items: items,
    );
  }

  String get displayBillNumber =>
      purchaseNumber.isNotEmpty ? purchaseNumber : supplierInvoiceNumber;
}
