import 'dart:math' as math;

/// Safely parse numeric fields from backend / Prisma (handles num, String, and Decimal object Map)
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

DateTime parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  if (val is String) {
    final parsed = DateTime.tryParse(val);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

/// Double-entry leg DTO (individual Debit or Credit leg of a transaction)
class DoubleEntryLegDto {
  final String accountId;
  final String accountName;
  final double debit;
  final double credit;
  final String? narration;

  const DoubleEntryLegDto({
    required this.accountId,
    required this.accountName,
    this.debit = 0.0,
    this.credit = 0.0,
    this.narration,
  });

  factory DoubleEntryLegDto.fromJson(Map<String, dynamic> json) {
    return DoubleEntryLegDto(
      accountId: json['accountId']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? 'Account',
      debit: parseNum(json['debit']),
      credit: parseNum(json['credit']),
      narration: json['narration']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'debit': debit,
      'credit': credit,
      if (narration != null) 'narration': narration,
    };
  }
}

/// Ledger Item DTO (represents a single row in the General Ledger table)
class LedgerItemDto {
  final String id;
  final String date;
  final String time;
  final DateTime dateTime;
  final String voucherNo;
  final String voucherType;
  final String account;
  final String narration;
  final double debit;
  final double credit;
  final double balance;
  final bool isDebitBalance;
  final List<DoubleEntryLegDto> legs;

  const LedgerItemDto({
    required this.id,
    required this.date,
    required this.time,
    required this.dateTime,
    required this.voucherNo,
    required this.voucherType,
    required this.account,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.isDebitBalance,
    this.legs = const [],
  });

  factory LedgerItemDto.fromJson(Map<String, dynamic> json) {
    final legsRaw = json['legs'] as List<dynamic>? ?? [];
    final legs = legsRaw
        .whereType<Map<String, dynamic>>()
        .map((l) => DoubleEntryLegDto.fromJson(l))
        .toList();

    return LedgerItemDto(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      dateTime: parseDateTime(json['dateTime']),
      voucherNo: json['voucherNo']?.toString() ?? '',
      voucherType: json['voucherType']?.toString() ?? 'General',
      account: json['account']?.toString() ?? '',
      narration: json['narration']?.toString() ?? '',
      debit: parseNum(json['debit']),
      credit: parseNum(json['credit']),
      balance: parseNum(json['balance']),
      isDebitBalance: json['isDebitBalance'] == true,
      legs: legs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'dateTime': dateTime.toIso8601String(),
      'voucherNo': voucherNo,
      'voucherType': voucherType,
      'account': account,
      'narration': narration,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'isDebitBalance': isDebitBalance,
      'legs': legs.map((l) => l.toJson()).toList(),
    };
  }
}

/// General Ledger Summary DTO (for KPI cards)
class GeneralLedgerSummaryDto {
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final int totalEntries;
  final bool isBalanced;
  final bool isDebitBalance;

  const GeneralLedgerSummaryDto({
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.closingBalance = 0.0,
    this.totalEntries = 0,
    this.isBalanced = true,
    this.isDebitBalance = true,
  });

  factory GeneralLedgerSummaryDto.fromJson(Map<String, dynamic> json) {
    return GeneralLedgerSummaryDto(
      totalDebit: parseNum(json['totalDebit']),
      totalCredit: parseNum(json['totalCredit']),
      closingBalance: parseNum(json['closingBalance']),
      totalEntries: parseInt(json['totalEntries']),
      isBalanced: json['isBalanced'] == true,
      isDebitBalance: json['isDebitBalance'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'closingBalance': closingBalance,
      'totalEntries': totalEntries,
      'isBalanced': isBalanced,
      'isDebitBalance': isDebitBalance,
    };
  }
}

/// Smart Insights DTO (audit & ledger health verification)
class SmartInsightsDto {
  final bool isBalanced;
  final double difference;
  final String status;
  final String message;

  const SmartInsightsDto({
    this.isBalanced = true,
    this.difference = 0.0,
    this.status = 'BALANCED',
    this.message = 'All transactions in the ledger are balanced.',
  });

  factory SmartInsightsDto.fromJson(Map<String, dynamic> json) {
    return SmartInsightsDto(
      isBalanced: json['isBalanced'] == true,
      difference: parseNum(json['difference']),
      status: json['status']?.toString() ?? 'BALANCED',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isBalanced': isBalanced,
      'difference': difference,
      'status': status,
      'message': message,
    };
  }
}

/// Pagination DTO
class GeneralLedgerPaginationDto {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const GeneralLedgerPaginationDto({
    this.total = 0,
    this.page = 1,
    this.limit = 10,
    this.totalPages = 1,
  });

  factory GeneralLedgerPaginationDto.fromJson(Map<String, dynamic> json) {
    return GeneralLedgerPaginationDto(
      total: parseInt(json['total']),
      page: parseInt(json['page']) > 0 ? parseInt(json['page']) : 1,
      limit: parseInt(json['limit']) > 0 ? parseInt(json['limit']) : 10,
      totalPages: parseInt(json['totalPages']) > 0 ? parseInt(json['totalPages']) : 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }
}

/// Encompassing General Ledger Response DTO from backend
class GeneralLedgerResponseDto {
  final GeneralLedgerSummaryDto summary;
  final SmartInsightsDto smartInsights;
  final List<LedgerItemDto> items;
  final List<String> accounts;
  final List<String> voucherTypes;
  final GeneralLedgerPaginationDto pagination;

  const GeneralLedgerResponseDto({
    this.summary = const GeneralLedgerSummaryDto(),
    this.smartInsights = const SmartInsightsDto(),
    this.items = const [],
    this.accounts = const [],
    this.voucherTypes = const [],
    this.pagination = const GeneralLedgerPaginationDto(),
  });

  factory GeneralLedgerResponseDto.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => LedgerItemDto.fromJson(e))
        .toList();

    final accountsRaw = json['accounts'] as List<dynamic>? ?? [];
    final accounts = accountsRaw.map((e) => e.toString()).toList();

    final voucherTypesRaw = json['voucherTypes'] as List<dynamic>? ?? [];
    final voucherTypes = voucherTypesRaw.map((e) => e.toString()).toList();

    return GeneralLedgerResponseDto(
      summary: json['summary'] is Map<String, dynamic>
          ? GeneralLedgerSummaryDto.fromJson(json['summary'])
          : const GeneralLedgerSummaryDto(),
      smartInsights: json['smartInsights'] is Map<String, dynamic>
          ? SmartInsightsDto.fromJson(json['smartInsights'])
          : const SmartInsightsDto(),
      items: items,
      accounts: accounts,
      voucherTypes: voucherTypes,
      pagination: json['pagination'] is Map<String, dynamic>
          ? GeneralLedgerPaginationDto.fromJson(json['pagination'])
          : const GeneralLedgerPaginationDto(),
    );
  }
}
