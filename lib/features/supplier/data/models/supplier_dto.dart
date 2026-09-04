import '../../../../core/models/billing_models.dart';

/// DTO for serializing and deserializing Supplier data between Frontend and Backend
class SupplierDto {
  final String id;
  final String? businessId;
  final String name;
  final String gstin;
  final String pan;
  final String mobile;
  final String email;
  final String address;
  final String state;
  final String stateCode;
  final int creditTerms;
  final double openingBalance;
  final double currentBalance;
  final String supplierGroup;
  final String notes;
  final bool isRegistered;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupplierDto({
    required this.id,
    this.businessId,
    required this.name,
    this.gstin = '',
    this.pan = '',
    this.mobile = '',
    this.email = '',
    this.address = '',
    this.state = '',
    this.stateCode = '',
    this.creditTerms = 0,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.supplierGroup = 'General',
    this.notes = '',
    this.isRegistered = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory from backend JSON response
  factory SupplierDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final gstin = json['gstin']?.toString() ?? '';
    final stateCode = json['stateCode']?.toString() ?? (gstin.length >= 2 ? gstin.substring(0, 2) : '');

    return SupplierDto(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString(),
      name: json['name']?.toString() ?? '',
      gstin: gstin,
      pan: json['pan']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['mobileNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: stateCode,
      creditTerms: parseInt(json['creditTerms']),
      openingBalance: parseDouble(json['openingBalance']),
      currentBalance: parseDouble(json['currentBalance']),
      supplierGroup: json['supplierGroup']?.toString() ?? 'General',
      notes: json['notes']?.toString() ?? '',
      isRegistered: json['isRegistered'] == true || gstin.length == 15,
      isActive: json['isActive'] != false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  /// Converts DTO to Domain Supplier entity
  Supplier toDomain() {
    return Supplier(
      id: id,
      name: name,
      gstin: gstin,
      pan: pan,
      mobile: mobile,
      email: email,
      address: address,
      state: state,
      stateCode: stateCode,
      creditTerms: creditTerms,
      openingBalance: openingBalance,
      currentBalance: currentBalance,
      supplierGroup: supplierGroup,
      notes: notes,
    );
  }

  /// Factory from Domain Supplier entity
  factory SupplierDto.fromDomain(
    Supplier supplier, {
    bool isRegistered = false,
    bool isActive = true,
  }) {
    return SupplierDto(
      id: supplier.id,
      name: supplier.name,
      gstin: supplier.gstin,
      pan: supplier.pan,
      mobile: supplier.mobile,
      email: supplier.email,
      address: supplier.address,
      state: supplier.state,
      stateCode: supplier.stateCode,
      creditTerms: supplier.creditTerms,
      openingBalance: supplier.openingBalance,
      currentBalance: supplier.currentBalance,
      supplierGroup: supplier.supplierGroup,
      notes: supplier.notes,
      isRegistered: isRegistered || supplier.gstin.isNotEmpty,
      isActive: isActive,
    );
  }

  /// Convert to JSON payload for backend POST / PUT requests
  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final map = <String, dynamic>{
      'name': name,
      'gstin': gstin.isNotEmpty ? gstin : null,
      'pan': pan.isNotEmpty ? pan : null,
      'mobileNumber': mobile.isNotEmpty ? mobile : null,
      'email': email.isNotEmpty ? email : null,
      'address': address.isNotEmpty ? address : null,
      'state': state.isNotEmpty ? state : null,
      'stateCode': stateCode.isNotEmpty ? stateCode : null,
      'creditTerms': creditTerms.toString(),
      'openingBalance': openingBalance,
      'supplierGroup': supplierGroup.isNotEmpty ? supplierGroup : 'General',
      'notes': notes.isNotEmpty ? notes : null,
      'isActive': isActive,
    };

    if (!isUpdate && businessId != null && businessId!.isNotEmpty) {
      map['businessId'] = businessId;
    }

    return map;
  }
}

/// Paginated response from GET /api/v1/suppliers
class SupplierListResponse {
  final List<Supplier> suppliers;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const SupplierListResponse({
    required this.suppliers,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory SupplierListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['suppliers'] as List<dynamic>? ?? [];
    final suppliers = rawList
        .map((e) => SupplierDto.fromJson(e as Map<String, dynamic>))
        .where((dto) => dto.isActive)
        .map((dto) => dto.toDomain())
        .toList();


    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return SupplierListResponse(
      suppliers: suppliers,
      total: (pagination['total'] as num?)?.toInt() ?? suppliers.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: pagination['hasNextPage'] == true,
      hasPrevPage: pagination['hasPrevPage'] == true,
    );
  }
}

/// Metrics summary from GET /api/v1/suppliers/metrics/summary
class SupplierMetricsDto {
  final int totalSuppliers;
  final int activeSuppliers;
  final int inactiveSuppliers;
  final int registeredSuppliers;
  final int unregisteredSuppliers;
  final double totalOpeningBalance;
  final double totalPurchased;
  final double totalPaid;
  final double totalPayable;

  const SupplierMetricsDto({
    this.totalSuppliers = 0,
    this.activeSuppliers = 0,
    this.inactiveSuppliers = 0,
    this.registeredSuppliers = 0,
    this.unregisteredSuppliers = 0,
    this.totalOpeningBalance = 0.0,
    this.totalPurchased = 0.0,
    this.totalPaid = 0.0,
    this.totalPayable = 0.0,
  });

  factory SupplierMetricsDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return SupplierMetricsDto(
      totalSuppliers: parseInt(json['totalSuppliers']),
      activeSuppliers: parseInt(json['activeSuppliers']),
      inactiveSuppliers: parseInt(json['inactiveSuppliers']),
      registeredSuppliers: parseInt(json['registeredSuppliers']),
      unregisteredSuppliers: parseInt(json['unregisteredSuppliers']),
      totalOpeningBalance: parseDouble(json['totalOpeningBalance']),
      totalPurchased: parseDouble(json['totalPurchased']),
      totalPaid: parseDouble(json['totalPaid']),
      totalPayable: parseDouble(json['totalPayable']),
    );
  }
}

/// Detailed Supplier profile response from GET /api/v1/suppliers/:id
class SupplierDetailDto {
  final Supplier supplier;
  final Map<String, dynamic> statistics;
  final List<Map<String, dynamic>> recentPurchases;
  final List<Map<String, dynamic>> recentPayments;
  final List<Map<String, dynamic>> recentLedgerEntries;

  const SupplierDetailDto({
    required this.supplier,
    required this.statistics,
    required this.recentPurchases,
    required this.recentPayments,
    required this.recentLedgerEntries,
  });

  factory SupplierDetailDto.fromJson(Map<String, dynamic> json) {
    final supplier = SupplierDto.fromJson(json).toDomain();
    final stats = json['statistics'] as Map<String, dynamic>? ?? {};

    final rawPurchases = json['recentPurchases'] as List<dynamic>? ?? [];
    final purchases =
        rawPurchases.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawPayments = json['recentPayments'] as List<dynamic>? ?? [];
    final payments =
        rawPayments.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawLedger = json['recentLedgerEntries'] as List<dynamic>? ?? [];
    final ledger =
        rawLedger.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return SupplierDetailDto(
      supplier: supplier,
      statistics: stats,
      recentPurchases: purchases,
      recentPayments: payments,
      recentLedgerEntries: ledger,
    );
  }
}
