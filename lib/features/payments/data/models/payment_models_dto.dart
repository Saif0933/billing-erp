import 'dart:math' as math;
import '../../../../core/models/billing_models.dart';

/// Helper to safely parse numeric fields from Prisma / JSON (handles num, String, and Decimal object Map)
double parseNum(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  if (val is Map) {
    if (val.containsKey('d') && val['d'] is List) {
      final list = val['d'] as List;
      final digits = list.join('');
      final exp = (val['e'] as num?)?.toInt() ?? 0;
      final sign = (val['s'] as num?)?.toInt() ?? 1;
      final rawNum = double.tryParse(digits) ?? 0.0;
      final power = exp - digits.length + 1;
      return sign * rawNum * math.pow(10, power).toDouble();
    }
  }
  return double.tryParse(val.toString()) ?? 0.0;
}

int parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return parseNum(val).toInt();
}

/// DTO for unpaid invoices returned by /api/v1/receipts/customer/:id/unpaid-invoices
class ReceiptUnpaidInvoiceDto {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus;

  const ReceiptUnpaidInvoiceDto({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
  });

  factory ReceiptUnpaidInvoiceDto.fromJson(Map<String, dynamic> json) {
    return ReceiptUnpaidInvoiceDto(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      invoiceDate: DateTime.tryParse(json['invoiceDate']?.toString() ?? '') ?? DateTime.now(),
      grandTotal: parseNum(json['grandTotal']),
      paidAmount: parseNum(json['paidAmount']),
      balanceAmount: parseNum(json['balanceAmount']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
    );
  }
}

/// DTO for unpaid purchases returned by /api/v1/payments/supplier/:id/unpaid-purchases
class PaymentUnpaidPurchaseDto {
  final String id;
  final String purchaseNumber;
  final String? supplierInvoiceNumber;
  final DateTime purchaseDate;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus;

  const PaymentUnpaidPurchaseDto({
    required this.id,
    required this.purchaseNumber,
    this.supplierInvoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
  });

  factory PaymentUnpaidPurchaseDto.fromJson(Map<String, dynamic> json) {
    return PaymentUnpaidPurchaseDto(
      id: json['id']?.toString() ?? '',
      purchaseNumber: json['purchaseNumber']?.toString() ?? '',
      supplierInvoiceNumber: json['supplierInvoiceNumber']?.toString(),
      purchaseDate: DateTime.tryParse(json['purchaseDate']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: parseNum(json['totalAmount']),
      paidAmount: parseNum(json['paidAmount']),
      balanceAmount: parseNum(json['balanceAmount']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
    );
  }
}

/// DTO representing a saved Receipt from backend
class ReceiptResponseDto {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime receiptDate;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final List<ReceiptAllocation> allocations;

  const ReceiptResponseDto({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.receiptDate,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    this.allocations = const [],
  });

  factory ReceiptResponseDto.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final allocList = (json['allocations'] as List<dynamic>?) ?? [];

    return ReceiptResponseDto(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? customer?['id']?.toString() ?? '',
      customerName: customer?['name']?.toString() ?? json['customerName']?.toString() ?? 'Customer',
      amount: parseNum(json['amount']),
      receiptDate: DateTime.tryParse(json['receiptDate']?.toString() ?? '') ?? DateTime.now(),
      paymentMode: json['paymentMode']?.toString() ?? 'BANK',
      referenceNumber: json['referenceNumber']?.toString(),
      notes: json['notes']?.toString(),
      allocations: allocList.map((a) {
        final m = a as Map<String, dynamic>;
        return ReceiptAllocation(
          invoiceId: m['invoiceId']?.toString() ?? '',
          amountAllocated: parseNum(m['allocatedAmount'] ?? m['amountAllocated']),
        );
      }).toList(),
    );
  }

  Receipt toDomain() {
    return Receipt(
      id: id,
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      date: receiptDate,
      paymentMode: paymentMode,
      referenceNumber: referenceNumber ?? '',
      notes: notes ?? '',
      allocations: allocations,
    );
  }
}

/// DTO representing a saved Payment from backend
class PaymentResponseDto {
  final String id;
  final String supplierId;
  final String supplierName;
  final double amount;
  final DateTime paymentDate;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final List<PaymentAllocation> allocations;

  const PaymentResponseDto({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    this.allocations = const [],
  });

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] as Map<String, dynamic>?;
    final purId = json['purchaseId']?.toString();
    final paymentAmount = parseNum(json['amount']);

    return PaymentResponseDto(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? supplier?['id']?.toString() ?? '',
      supplierName: supplier?['name']?.toString() ?? json['supplierName']?.toString() ?? 'Supplier',
      amount: paymentAmount,
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? '') ?? DateTime.now(),
      paymentMode: json['paymentMode']?.toString() ?? 'BANK',
      referenceNumber: json['referenceNumber']?.toString(),
      notes: json['notes']?.toString(),
      allocations: purId != null && purId.isNotEmpty
          ? [
              PaymentAllocation(
                purchaseId: purId,
                amountAllocated: paymentAmount,
              ),
            ]
          : const [],
    );
  }

  Payment toDomain() {
    return Payment(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      amount: amount,
      date: paymentDate,
      paymentMode: paymentMode,
      referenceNumber: referenceNumber ?? '',
      notes: notes ?? '',
      allocations: allocations,
    );
  }
}

/// DTO for Receipt metrics
class ReceiptMetricsDto {
  final double todayReceived;
  final int todayCount;
  final double thisMonthReceived;
  final int thisMonthCount;
  final double totalReceived;
  final int totalReceipts;

  const ReceiptMetricsDto({
    this.todayReceived = 0.0,
    this.todayCount = 0,
    this.thisMonthReceived = 0.0,
    this.thisMonthCount = 0,
    this.totalReceived = 0.0,
    this.totalReceipts = 0,
  });

  factory ReceiptMetricsDto.fromJson(Map<String, dynamic> json) {
    return ReceiptMetricsDto(
      todayReceived: parseNum(json['todayReceived']),
      todayCount: parseInt(json['todayCount']),
      thisMonthReceived: parseNum(json['thisMonthReceived']),
      thisMonthCount: parseInt(json['thisMonthCount']),
      totalReceived: parseNum(json['totalReceived']),
      totalReceipts: parseInt(json['totalReceipts']),
    );
  }
}

/// DTO for Payment metrics
class PaymentMetricsDto {
  final double todayPaid;
  final int todayCount;
  final double thisMonthPaid;
  final int thisMonthCount;
  final double totalPaid;
  final int totalPayments;

  const PaymentMetricsDto({
    this.todayPaid = 0.0,
    this.todayCount = 0,
    this.thisMonthPaid = 0.0,
    this.thisMonthCount = 0,
    this.totalPaid = 0.0,
    this.totalPayments = 0,
  });

  factory PaymentMetricsDto.fromJson(Map<String, dynamic> json) {
    return PaymentMetricsDto(
      todayPaid: parseNum(json['todayPaid']),
      todayCount: parseInt(json['todayCount']),
      thisMonthPaid: parseNum(json['thisMonthPaid']),
      thisMonthCount: parseInt(json['thisMonthCount']),
      totalPaid: parseNum(json['totalPaid']),
      totalPayments: parseInt(json['totalPayments']),
    );
  }
}
