import 'dart:math' as math;

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

/// Ageing bucket distribution DTO
class AgeingBucketsDto {
  final double bucket0To30;
  final double bucket31To60;
  final double bucket61To90;
  final double bucket91Plus;

  const AgeingBucketsDto({
    this.bucket0To30 = 0.0,
    this.bucket31To60 = 0.0,
    this.bucket61To90 = 0.0,
    this.bucket91Plus = 0.0,
  });

  factory AgeingBucketsDto.fromJson(Map<String, dynamic> json) {
    return AgeingBucketsDto(
      bucket0To30: parseNum(json['bucket0To30']),
      bucket31To60: parseNum(json['bucket31To60']),
      bucket61To90: parseNum(json['bucket61To90']),
      bucket91Plus: parseNum(json['bucket91Plus']),
    );
  }
}

/// Category summary (for Receivables or Payables)
class OutstandingCategorySummaryDto {
  final double totalOutstanding;
  final double dueToday;
  final double totalOverdue;
  final double totalPending;
  final int count;
  final AgeingBucketsDto ageingBuckets;

  const OutstandingCategorySummaryDto({
    this.totalOutstanding = 0.0,
    this.dueToday = 0.0,
    this.totalOverdue = 0.0,
    this.totalPending = 0.0,
    this.count = 0,
    this.ageingBuckets = const AgeingBucketsDto(),
  });

  factory OutstandingCategorySummaryDto.fromJson(Map<String, dynamic> json) {
    return OutstandingCategorySummaryDto(
      totalOutstanding: parseNum(json['totalOutstanding']),
      dueToday: parseNum(json['dueToday']),
      totalOverdue: parseNum(json['totalOverdue']),
      totalPending: parseNum(json['totalPending']),
      count: parseInt(json['count']),
      ageingBuckets: json['ageingBuckets'] != null
          ? AgeingBucketsDto.fromJson(json['ageingBuckets'] as Map<String, dynamic>)
          : const AgeingBucketsDto(),
    );
  }
}

/// Overall KPI summary response
class OutstandingSummaryResponseDto {
  final OutstandingCategorySummaryDto receivables;
  final OutstandingCategorySummaryDto payables;
  final double netWorkingCapital;

  const OutstandingSummaryResponseDto({
    this.receivables = const OutstandingCategorySummaryDto(),
    this.payables = const OutstandingCategorySummaryDto(),
    this.netWorkingCapital = 0.0,
  });

  factory OutstandingSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return OutstandingSummaryResponseDto(
      receivables: json['receivables'] != null
          ? OutstandingCategorySummaryDto.fromJson(json['receivables'] as Map<String, dynamic>)
          : const OutstandingCategorySummaryDto(),
      payables: json['payables'] != null
          ? OutstandingCategorySummaryDto.fromJson(json['payables'] as Map<String, dynamic>)
          : const OutstandingCategorySummaryDto(),
      netWorkingCapital: parseNum(json['netWorkingCapital']),
    );
  }
}

/// Individual item matching OutstandingPage row
class OutstandingItemDto {
  final String id;
  final String refNumber;
  final DateTime date;
  final DateTime dueDate;
  final String partyId;
  final String partyName;
  final String? partyMobile;
  final double amount;
  final double paidAmount;
  final double balance;
  final int ageDays;
  final String statusLabel; // 'OVERDUE', 'DUE TODAY', 'PENDING'
  final String bucket; // '0-30', '31-60', '61-90', '91+'

  const OutstandingItemDto({
    required this.id,
    required this.refNumber,
    required this.date,
    required this.dueDate,
    required this.partyId,
    required this.partyName,
    this.partyMobile,
    required this.amount,
    required this.paidAmount,
    required this.balance,
    required this.ageDays,
    required this.statusLabel,
    required this.bucket,
  });

  factory OutstandingItemDto.fromJson(Map<String, dynamic> json) {
    return OutstandingItemDto(
      id: json['id']?.toString() ?? '',
      refNumber: json['refNumber']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      partyId: json['partyId']?.toString() ?? '',
      partyName: json['partyName']?.toString() ?? 'Party',
      partyMobile: json['partyMobile']?.toString(),
      amount: parseNum(json['amount']),
      paidAmount: parseNum(json['paidAmount']),
      balance: parseNum(json['balance']),
      ageDays: parseInt(json['ageDays']),
      statusLabel: json['statusLabel']?.toString() ?? 'PENDING',
      bucket: json['bucket']?.toString() ?? '0-30',
    );
  }
}

/// List response wrapper with pagination
class OutstandingListResponseDto {
  final List<OutstandingItemDto> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const OutstandingListResponseDto({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
  });

  factory OutstandingListResponseDto.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?) ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>?;

    return OutstandingListResponseDto(
      items: list.map((e) => OutstandingItemDto.fromJson(e as Map<String, dynamic>)).toList(),
      total: parseInt(pagination?['total'] ?? list.length),
      page: parseInt(pagination?['page'] ?? 1),
      limit: parseInt(pagination?['limit'] ?? 50),
      totalPages: parseInt(pagination?['totalPages'] ?? 1),
    );
  }
}
