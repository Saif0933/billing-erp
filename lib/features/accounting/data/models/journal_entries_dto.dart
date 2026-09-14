import 'dart:math' as math;

/// Types of journal entries supported in General Journal
enum JournalType {
  standard,
  adjustment,
  recurring,
  template,
}

/// Status of journal entries
enum JournalEntryStatus {
  posted,
  draft,
  voided,
}

JournalType parseJournalType(dynamic val) {
  if (val == null) return JournalType.standard;
  final str = val.toString().toLowerCase().trim();
  switch (str) {
    case 'standard':
      return JournalType.standard;
    case 'adjustment':
      return JournalType.adjustment;
    case 'recurring':
      return JournalType.recurring;
    case 'template':
      return JournalType.template;
    default:
      return JournalType.standard;
  }
}

JournalEntryStatus parseJournalStatus(dynamic val) {
  if (val == null) return JournalEntryStatus.posted;
  final str = val.toString().toLowerCase().trim();
  switch (str) {
    case 'posted':
      return JournalEntryStatus.posted;
    case 'draft':
      return JournalEntryStatus.draft;
    case 'voided':
      return JournalEntryStatus.voided;
    default:
      return JournalEntryStatus.posted;
  }
}

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

/// Double-entry line representing an account leg
class JournalLineDto {
  final String? id;
  final String accountId;
  final String accountName;
  final String? accountCode;
  final double debitAmount;
  final double creditAmount;
  final String? narration;

  const JournalLineDto({
    this.id,
    required this.accountId,
    required this.accountName,
    this.accountCode,
    this.debitAmount = 0.0,
    this.creditAmount = 0.0,
    this.narration,
  });

  factory JournalLineDto.fromJson(Map<String, dynamic> json) {
    return JournalLineDto(
      id: json['id']?.toString(),
      accountId: json['accountId']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? 'Account',
      accountCode: json['accountCode']?.toString(),
      debitAmount: parseNum(json['debitAmount'] ?? json['debit']),
      creditAmount: parseNum(json['creditAmount'] ?? json['credit']),
      narration: json['narration']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'accountId': accountId,
      'accountName': accountName,
      if (accountCode != null) 'accountCode': accountCode,
      'debitAmount': debitAmount,
      'creditAmount': creditAmount,
      if (narration != null) 'narration': narration,
    };
  }
}

/// Single Journal Entry representation matching the table row item
class JournalEntryItemDto {
  final String id;
  final String date;
  final String time;
  final DateTime dateTime;
  final String journalNo;
  final String journalTypeLabel;
  final JournalType type;
  final String reference;
  final String narration;
  final double debit;
  final double credit;
  final JournalEntryStatus status;
  final List<JournalLineDto> lines;

  const JournalEntryItemDto({
    required this.id,
    required this.date,
    required this.time,
    required this.dateTime,
    required this.journalNo,
    required this.journalTypeLabel,
    required this.type,
    required this.reference,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.status,
    this.lines = const [],
  });

  factory JournalEntryItemDto.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    final lines = rawLines
        .whereType<Map<String, dynamic>>()
        .map((l) => JournalLineDto.fromJson(l))
        .toList();

    DateTime parsedDt;
    if (json['dateTime'] != null) {
      parsedDt = DateTime.tryParse(json['dateTime'].toString()) ?? DateTime.now();
    } else if (json['entryDate'] != null) {
      parsedDt = DateTime.tryParse(json['entryDate'].toString()) ?? DateTime.now();
    } else {
      parsedDt = DateTime.now();
    }

    return JournalEntryItemDto(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      dateTime: parsedDt,
      journalNo: json['journalNo']?.toString() ?? '',
      journalTypeLabel: json['journalTypeLabel']?.toString() ?? 'Standard',
      type: parseJournalType(json['type']),
      reference: json['reference']?.toString() ?? '-',
      narration: json['narration']?.toString() ?? '',
      debit: parseNum(json['debit']),
      credit: parseNum(json['credit']),
      status: parseJournalStatus(json['status']),
      lines: lines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'dateTime': dateTime.toIso8601String(),
      'journalNo': journalNo,
      'journalTypeLabel': journalTypeLabel,
      'type': type.name,
      'reference': reference,
      'narration': narration,
      'debit': debit,
      'credit': credit,
      'status': status.name,
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }
}

/// Container for General Journal KPI metrics and paginated records
class GeneralJournalSummaryResponseDto {
  final int totalJournals;
  final double totalDebit;
  final double totalCredit;
  final int outOfBalanceCount;
  final double difference;
  final bool isBalanced;
  final List<JournalEntryItemDto> pagedItems;
  final int totalCount;
  final int totalPages;
  final int currentPage;

  const GeneralJournalSummaryResponseDto({
    this.totalJournals = 0,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.outOfBalanceCount = 0,
    this.difference = 0.0,
    this.isBalanced = true,
    this.pagedItems = const [],
    this.totalCount = 0,
    this.totalPages = 1,
    this.currentPage = 1,
  });

  factory GeneralJournalSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['pagedItems'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((i) => JournalEntryItemDto.fromJson(i))
        .toList();

    return GeneralJournalSummaryResponseDto(
      totalJournals: parseInt(json['totalJournals']),
      totalDebit: parseNum(json['totalDebit']),
      totalCredit: parseNum(json['totalCredit']),
      outOfBalanceCount: parseInt(json['outOfBalanceCount']),
      difference: parseNum(json['difference']),
      isBalanced: json['isBalanced'] != false,
      pagedItems: items,
      totalCount: parseInt(json['totalCount']),
      totalPages: parseInt(json['totalPages']) > 0 ? parseInt(json['totalPages']) : 1,
      currentPage: parseInt(json['currentPage']) > 0 ? parseInt(json['currentPage']) : 1,
    );
  }
}

/// Payload for creating a new Journal Entry
class CreateJournalEntryDto {
  final DateTime? entryDate;
  final JournalType type;
  final String reference;
  final String narration;
  final JournalEntryStatus status;
  final List<JournalLineDto>? lines;
  final String? debitAccountId;
  final String? creditAccountId;
  final double? debitAmount;
  final double? creditAmount;

  const CreateJournalEntryDto({
    this.entryDate,
    this.type = JournalType.standard,
    this.reference = '',
    required this.narration,
    this.status = JournalEntryStatus.posted,
    this.lines,
    this.debitAccountId,
    this.creditAccountId,
    this.debitAmount,
    this.creditAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      if (entryDate != null) 'entryDate': entryDate!.toIso8601String(),
      'type': type.name,
      'reference': reference.trim(),
      'narration': narration.trim(),
      'status': status.name,
      if (lines != null && lines!.isNotEmpty)
        'lines': lines!.map((l) => l.toJson()).toList(),
      if (debitAccountId != null) 'debitAccountId': debitAccountId,
      if (creditAccountId != null) 'creditAccountId': creditAccountId,
      if (debitAmount != null) 'debitAmount': debitAmount,
      if (creditAmount != null) 'creditAmount': creditAmount,
    };
  }
}

/// Account item for Dr/Cr selection dropdowns
class AccountDropdownItemDto {
  final String id;
  final String name;
  final String code;
  final String type;

  const AccountDropdownItemDto({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
  });

  factory AccountDropdownItemDto.fromJson(Map<String, dynamic> json) {
    return AccountDropdownItemDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}
