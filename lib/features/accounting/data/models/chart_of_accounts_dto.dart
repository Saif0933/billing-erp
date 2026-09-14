import 'dart:math' as math;

/// Standard double-entry account categories
enum CoaAccountType {
  asset,
  liability,
  equity,
  income,
  expense,
}

CoaAccountType parseCoaType(dynamic val) {
  if (val == null) return CoaAccountType.asset;
  final str = val.toString().toLowerCase().trim();
  switch (str) {
    case 'asset':
    case 'assets':
      return CoaAccountType.asset;
    case 'liability':
    case 'liabilities':
      return CoaAccountType.liability;
    case 'equity':
      return CoaAccountType.equity;
    case 'income':
      return CoaAccountType.income;
    case 'expense':
    case 'expenses':
      return CoaAccountType.expense;
    default:
      return CoaAccountType.asset;
  }
}

/// Helper to parse numeric values safely
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

/// Tree item representation for an account or group
class CoaAccountItemDto {
  final String id;
  final String code;
  final String name;
  final String description;
  final CoaAccountType type;
  final double balance;
  final bool isGroup;
  final String? parentCode;
  final bool isActive;
  final List<CoaAccountItemDto> children;

  const CoaAccountItemDto({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.balance,
    this.isGroup = false,
    this.parentCode,
    this.isActive = true,
    this.children = const [],
  });

  factory CoaAccountItemDto.fromJson(Map<String, dynamic> json) {
    final childrenRaw = json['children'] as List<dynamic>? ?? [];
    final children = childrenRaw
        .whereType<Map<String, dynamic>>()
        .map((c) => CoaAccountItemDto.fromJson(c))
        .toList();

    return CoaAccountItemDto(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: parseCoaType(json['type']),
      balance: parseNum(json['balance']),
      isGroup: json['isGroup'] == true,
      parentCode: json['parentCode']?.toString(),
      isActive: json['isActive'] != false,
      children: children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'type': type.name,
      'balance': balance,
      'isGroup': isGroup,
      'parentCode': parentCode,
      'isActive': isActive,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }

  CoaAccountItemDto copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    CoaAccountType? type,
    double? balance,
    bool? isGroup,
    String? parentCode,
    bool? isActive,
    List<CoaAccountItemDto>? children,
  }) {
    return CoaAccountItemDto(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isGroup: isGroup ?? this.isGroup,
      parentCode: parentCode ?? this.parentCode,
      isActive: isActive ?? this.isActive,
      children: children ?? this.children,
    );
  }
}

/// DTO for Chart of Accounts summary response and KPI metrics
class CoaSummaryDataDto {
  final int totalAccounts;
  final int groups;
  final int ledgerAccounts;
  final double totalBalance;
  final List<CoaAccountItemDto> displayedGroups;

  const CoaSummaryDataDto({
    this.totalAccounts = 0,
    this.groups = 0,
    this.ledgerAccounts = 0,
    this.totalBalance = 0.0,
    this.displayedGroups = const [],
  });

  factory CoaSummaryDataDto.fromJson(Map<String, dynamic> json) {
    final groupsRaw = json['displayedGroups'] as List<dynamic>? ?? [];
    final displayedGroups = groupsRaw
        .whereType<Map<String, dynamic>>()
        .map((g) => CoaAccountItemDto.fromJson(g))
        .toList();

    return CoaSummaryDataDto(
      totalAccounts: parseInt(json['totalAccounts']),
      groups: parseInt(json['groups']),
      ledgerAccounts: parseInt(json['ledgerAccounts']),
      totalBalance: parseNum(json['totalBalance']),
      displayedGroups: displayedGroups,
    );
  }
}

/// Payload for creating a new Chart of Account
class CreateCoaAccountDto {
  final String name;
  final String code;
  final CoaAccountType type;
  final String? parentCode;
  final double openingBalance;
  final String description;
  final bool isGroup;

  const CreateCoaAccountDto({
    required this.name,
    required this.code,
    required this.type,
    this.parentCode,
    this.openingBalance = 0.0,
    this.description = '',
    this.isGroup = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'code': code.trim(),
      'type': type.name,
      if (parentCode != null && parentCode!.trim().isNotEmpty) 'parentCode': parentCode!.trim(),
      'openingBalance': openingBalance,
      'description': description.trim(),
      'isGroup': isGroup,
    };
  }
}
