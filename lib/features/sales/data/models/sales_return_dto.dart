// Sales Return DTOs matching backend module/salesopration/sales-return

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
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0.0,
      cessAmount: (json['cessAmount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (json['roundOff'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      termsConditions: json['termsConditions']?.toString(),
      items: rawItems
          .map((it) => SalesReturnItemDto.fromJson(it as Map<String, dynamic>))
          .toList(),
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
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'PCS',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      gstRatePercent: (json['gstRatePercent'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0.0,
      cessAmount: (json['cessAmount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString(),
      stockRestocked: json['stockRestocked'] == true,
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
      totalReturnValue: (json['totalReturnValue'] as num?)?.toDouble() ?? 0.0,
      confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
      draftCount: (json['draftCount'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelledCount'] as num?)?.toInt() ?? 0,
      itemsRestocked: (json['itemsRestocked'] as num?)?.toDouble() ?? 0.0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}
