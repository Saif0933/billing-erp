// Sales Return DTOs matching backend module/salesopration/sales-return

import '../../../../core/models/billing_models.dart';

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class SalesReturnDto {
  final String id;
  final String returnNumber;
  final DateTime returnDate;
  final String? invoiceId;
  final String? originalInvoiceNumber;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? billingAddress;
  final String? shippingAddress;
  final String? placeOfSupply;
  final String status;
  final String? reason;
  final String? refundMode;
  final String? warehouseId;
  final double subtotal;
  final double discountAmount;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double roundOff;
  final double totalAmount;
  final String? notes;
  final String? termsConditions;
  final List<SalesReturnItemDto> items;

  const SalesReturnDto({
    required this.id,
    required this.returnNumber,
    required this.returnDate,
    this.invoiceId,
    this.originalInvoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.billingAddress,
    this.shippingAddress,
    this.placeOfSupply,
    required this.status,
    this.reason,
    this.refundMode,
    this.warehouseId,
    required this.subtotal,
    required this.discountAmount,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.cessAmount,
    required this.roundOff,
    required this.totalAmount,
    this.notes,
    this.termsConditions,
    this.items = const [],
  });

  factory SalesReturnDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['returnDate'] ?? json['createdAt'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];

    String? originalInv;
    if (json['invoice'] is Map) {
      originalInv = json['invoice']['invoiceNumber']?.toString();
    }

    return SalesReturnDto(
      id: json['id']?.toString() ?? '',
      returnNumber: json['returnNumber']?.toString() ?? '',
      returnDate: parsedDate,
      invoiceId: json['invoiceId']?.toString(),
      originalInvoiceNumber: originalInv,
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString() ?? 'Walk-in Customer',
      customerPhone: json['customerPhone']?.toString(),
      billingAddress: json['billingAddress']?.toString(),
      shippingAddress: json['shippingAddress']?.toString(),
      placeOfSupply: json['placeOfSupply']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      reason: json['reason']?.toString(),
      refundMode: json['refundMode']?.toString() ?? 'Credit Note (Store Credit)',
      warehouseId: json['warehouseId']?.toString(),
      subtotal: _asDouble(json['subtotal']),
      discountAmount: _asDouble(json['discountAmount']),
      taxableValue: _asDouble(json['taxableValue']),
      cgstAmount: _asDouble(json['cgstAmount']),
      sgstAmount: _asDouble(json['sgstAmount']),
      igstAmount: _asDouble(json['igstAmount']),
      cessAmount: _asDouble(json['cessAmount']),
      roundOff: _asDouble(json['roundOff']),
      totalAmount: _asDouble(json['totalAmount'] ?? json['grandTotal']),
      notes: json['notes']?.toString(),
      termsConditions: json['termsConditions']?.toString(),
      items: rawItems
          .whereType<Map>()
          .map((it) => SalesReturnItemDto.fromJson(Map<String, dynamic>.from(it)))
          .toList(),
    );
  }

  InvoiceStatus get domainStatus {
    switch (status.toUpperCase()) {
      case 'CANCELLED':
        return InvoiceStatus.cancelled;
      case 'DRAFT':
        return InvoiceStatus.draft;
      case 'ADJUSTED':
        return InvoiceStatus.partiallyPaid;
      default:
        return InvoiceStatus.confirmed;
    }
  }

  Invoice toInvoice() {
    return Invoice(
      id: id,
      invoiceNumber: returnNumber,
      invoiceDate: returnDate,
      customerId: customerId ?? '',
      customerName: customerName,
      billingAddress: billingAddress ?? '',
      shippingAddress: shippingAddress ?? '',
      placeOfSupply: placeOfSupply ?? '',
      items: items.map((it) => it.toInvoiceItem()).toList(),
      taxableAmount: taxableValue,
      cgst: cgstAmount,
      sgst: sgstAmount,
      igst: igstAmount,
      cess: cessAmount,
      roundOff: roundOff,
      grandTotal: totalAmount,
      balanceAmount: 0,
      paymentMode: refundMode ?? 'Credit Note (Store Credit)',
      status: domainStatus,
      notes: notes ?? (reason ?? ''),
      termsConditions: termsConditions ?? '',
      originalInvoiceId: originalInvoiceNumber ?? invoiceId ?? '',
      warehouseId: warehouseId ?? '',
      isCreditNote: true,
    );
  }
}

class SalesReturnItemDto {
  final String id;
  final String? productId;
  final String? serviceId;
  final String productName;
  final String? hsnSac;
  final double quantity;
  final String unit;
  final double rate;
  final double discountPercentage;
  final double discountAmount;
  final double taxableValue;
  final double gstRatePercent;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double lineTotal;
  final String? reason;
  final bool stockRestocked;

  const SalesReturnItemDto({
    required this.id,
    this.productId,
    this.serviceId,
    required this.productName,
    this.hsnSac,
    required this.quantity,
    this.unit = 'PCS',
    required this.rate,
    this.discountPercentage = 0.0,
    this.discountAmount = 0.0,
    required this.taxableValue,
    this.gstRatePercent = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
    required this.lineTotal,
    this.reason,
    this.stockRestocked = false,
  });

  factory SalesReturnItemDto.fromJson(Map<String, dynamic> json) {
    return SalesReturnItemDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      serviceId: json['serviceId']?.toString(),
      productName: json['productName']?.toString() ?? 'Returned Item',
      hsnSac: json['hsnSac']?.toString(),
      quantity: _asDouble(json['quantity'], 1),
      unit: json['unit']?.toString() ?? 'PCS',
      rate: _asDouble(json['rate']),
      discountPercentage: _asDouble(json['discountPercentage']),
      discountAmount: _asDouble(json['discountAmount']),
      taxableValue: _asDouble(json['taxableValue']),
      gstRatePercent: _asDouble(json['gstRatePercent'] ?? json['gstRate']),
      cgstAmount: _asDouble(json['cgstAmount']),
      sgstAmount: _asDouble(json['sgstAmount']),
      igstAmount: _asDouble(json['igstAmount']),
      cessAmount: _asDouble(json['cessAmount']),
      lineTotal: _asDouble(json['lineTotal']),
      reason: json['reason']?.toString(),
      stockRestocked: json['stockRestocked'] == true,
    );
  }

  InvoiceItem toInvoiceItem() {
    return InvoiceItem(
      id: id.isNotEmpty ? id : 'ret_item_${productName.hashCode}',
      productId: productId ?? '',
      serviceId: serviceId ?? '',
      name: productName,
      hsnSac: hsnSac ?? '',
      quantity: quantity,
      unit: unit,
      rate: rate,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      taxableValue: taxableValue,
      gstRate: gstRatePercent,
      cgst: cgstAmount,
      sgst: sgstAmount,
      igst: igstAmount,
      cess: cessAmount,
    );
  }
}

class SalesReturnSummaryMetricsDto {
  final double totalReturnValue;
  final int confirmedCount;
  final int draftCount;
  final int cancelledCount;
  final double itemsRestocked;
  final int totalCount;

  const SalesReturnSummaryMetricsDto({
    this.totalReturnValue = 0.0,
    this.confirmedCount = 0,
    this.draftCount = 0,
    this.cancelledCount = 0,
    this.itemsRestocked = 0.0,
    this.totalCount = 0,
  });

  factory SalesReturnSummaryMetricsDto.fromJson(Map<String, dynamic> json) {
    return SalesReturnSummaryMetricsDto(
      totalReturnValue: _asDouble(json['totalReturnValue']),
      confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
      draftCount: (json['draftCount'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelledCount'] as num?)?.toInt() ?? 0,
      itemsRestocked: _asDouble(json['itemsRestocked']),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}
