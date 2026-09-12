// Sales Invoice DTOs matching backend module/salesopration/sales-invoice

import '../../../../core/models/billing_models.dart';

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class SalesInvoiceDto {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String paymentMode;
  final String paymentStatus;
  final String status;
  final bool isHeld;
  final String? notes;
  final String? billingAddress;
  final String? shippingAddress;
  final String? placeOfSupply;
  final List<SalesInvoiceItemDto> items;

  const SalesInvoiceDto({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    this.cessAmount = 0,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentMode,
    required this.paymentStatus,
    required this.status,
    required this.isHeld,
    this.notes,
    this.billingAddress,
    this.shippingAddress,
    this.placeOfSupply,
    this.items = const [],
  });

  factory SalesInvoiceDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['invoiceDate'] ?? json['createdAt'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];

    return SalesInvoiceDto(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      invoiceDate: parsedDate,
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString() ??
          (json['customer'] is Map ? json['customer']['name']?.toString() : null) ??
          'Walk-in Customer',
      customerPhone: json['customerPhone']?.toString() ??
          (json['customer'] is Map ? json['customer']['mobileNumber']?.toString() : null),
      subtotal: _asDouble(json['subtotal']),
      discountPercent: _asDouble(json['discountPercent']),
      discountAmount: _asDouble(json['discountAmount']),
      taxableValue: _asDouble(json['taxableValue']),
      cgstAmount: _asDouble(json['cgstAmount']),
      sgstAmount: _asDouble(json['sgstAmount']),
      igstAmount: _asDouble(json['igstAmount']),
      cessAmount: _asDouble(json['cessAmount']),
      grandTotal: _asDouble(json['grandTotal']),
      paidAmount: _asDouble(json['paidAmount']),
      balanceAmount: _asDouble(json['balanceAmount']),
      paymentMode: json['paymentMode']?.toString() ?? 'CASH',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PAID',
      status: json['status']?.toString() ?? 'SAVED',
      isHeld: json['isHeld'] == true || json['status'] == 'HELD',
      notes: json['notes']?.toString(),
      billingAddress: json['billingAddress']?.toString(),
      shippingAddress: json['shippingAddress']?.toString(),
      placeOfSupply: json['placeOfSupply']?.toString(),
      items: rawItems
          .map((item) => SalesInvoiceItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  InvoiceStatus get domainStatus {
    final s = status.toUpperCase();
    final pay = paymentStatus.toUpperCase();
    if (s == 'CANCELLED') return InvoiceStatus.cancelled;
    if (s == 'DRAFT' || s == 'HELD') return InvoiceStatus.draft;
    if (pay == 'PAID') return InvoiceStatus.paid;
    if (pay == 'PARTIALLY_PAID' || pay == 'PARTIAL') {
      return InvoiceStatus.partiallyPaid;
    }
    return InvoiceStatus.confirmed;
  }

  Invoice toInvoice() {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
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
      roundOff: 0,
      grandTotal: grandTotal,
      balanceAmount: balanceAmount,
      paymentMode: paymentMode,
      status: domainStatus,
      notes: notes ?? '',
      termsConditions: '',
    );
  }
}

class SalesInvoiceItemDto {
  final String id;
  final String? productId;
  final String productName;
  final double quantity;
  final String unit;
  final double rate;
  final double mrp;
  final double discountPercent;
  final double discountAmount;
  final double taxableValue;
  final double gstRatePercent;
  final double cgstAmount;
  final double sgstAmount;
  final double lineTotal;

  const SalesInvoiceItemDto({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.mrp,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxableValue,
    required this.gstRatePercent,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.lineTotal,
  });

  factory SalesInvoiceItemDto.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceItemDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productName: json['productName']?.toString() ??
          (json['product'] is Map ? json['product']['name']?.toString() : null) ??
          'Item',
      quantity: _asDouble(json['quantity'], 1),
      unit: json['unit']?.toString() ?? 'PCS',
      rate: _asDouble(json['rate']),
      mrp: _asDouble(json['mrp'], _asDouble(json['rate'])),
      discountPercent: _asDouble(json['discountPercent']),
      discountAmount: _asDouble(json['discountAmount']),
      taxableValue: _asDouble(json['taxableValue']),
      gstRatePercent: _asDouble(json['gstRatePercent'] ?? json['gstRate']),
      cgstAmount: _asDouble(json['cgstAmount']),
      sgstAmount: _asDouble(json['sgstAmount']),
      lineTotal: _asDouble(json['lineTotal']),
    );
  }

  InvoiceItem toInvoiceItem() {
    return InvoiceItem(
      id: id.isNotEmpty ? id : 'item_${productName.hashCode}',
      productId: productId ?? '',
      serviceId: '',
      name: productName,
      hsnSac: '',
      quantity: quantity,
      unit: unit,
      rate: rate,
      discountPercentage: discountPercent,
      discountAmount: discountAmount,
      taxableValue: taxableValue,
      gstRate: gstRatePercent,
      cgst: cgstAmount,
      sgst: sgstAmount,
      igst: 0,
      cess: 0,
    );
  }
}

class SalesInvoiceMetricsDto {
  final double todaySales;
  final int todayInvoicesCount;
  final double todayCollected;
  final int activeHeldBillsCount;
  final int totalInvoicesCount;
  final double averageTicketSize;

  const SalesInvoiceMetricsDto({
    required this.todaySales,
    required this.todayInvoicesCount,
    required this.todayCollected,
    required this.activeHeldBillsCount,
    required this.totalInvoicesCount,
    required this.averageTicketSize,
  });

  factory SalesInvoiceMetricsDto.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceMetricsDto(
      todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0.0,
      todayInvoicesCount: (json['todayInvoicesCount'] as num?)?.toInt() ?? 0,
      todayCollected: (json['todayCollected'] as num?)?.toDouble() ?? 0.0,
      activeHeldBillsCount: (json['activeHeldBillsCount'] as num?)?.toInt() ?? 0,
      totalInvoicesCount: (json['totalInvoicesCount'] as num?)?.toInt() ?? 0,
      averageTicketSize: (json['averageTicketSize'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesInvoiceResponse {
  final SalesInvoiceDto invoice;
  final Map<String, dynamic>? receipt;

  const SalesInvoiceResponse({
    required this.invoice,
    this.receipt,
  });

  factory SalesInvoiceResponse.fromJson(Map<String, dynamic> json) {
    final invoiceJson = json['invoice'] as Map<String, dynamic>? ?? json;
    final receiptJson = json['receipt'] as Map<String, dynamic>?;

    return SalesInvoiceResponse(
      invoice: SalesInvoiceDto.fromJson(invoiceJson),
      receipt: receiptJson,
    );
  }
}
