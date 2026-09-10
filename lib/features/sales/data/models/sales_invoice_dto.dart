// Sales Invoice DTOs matching backend module/salesopration/sales-invoice

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
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String paymentMode;
  final String paymentStatus;
  final String status;
  final bool isHeld;
  final String? notes;
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
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentMode,
    required this.paymentStatus,
    required this.status,
    required this.isHeld,
    this.notes,
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
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? 'CASH',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PAID',
      status: json['status']?.toString() ?? 'SAVED',
      isHeld: json['isHeld'] == true || json['status'] == 'HELD',
      notes: json['notes']?.toString(),
      items: rawItems
          .map((item) => SalesInvoiceItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
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
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'PCS',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? (json['rate'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      gstRatePercent: (json['gstRatePercent'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
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
