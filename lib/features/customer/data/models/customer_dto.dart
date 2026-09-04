import '../../../../core/models/billing_models.dart';

/// DTO for serializing and deserializing Customer data between Frontend and Backend
class CustomerDto {
  final String id;
  final String? businessId;
  final String name;
  final String customerType;
  final String type;
  final bool isRegistered;
  final String gstin;
  final String pan;
  final String mobile;
  final String email;
  final String billingAddress;
  final String shippingAddress;
  final String state;
  final String stateCode;
  final double creditLimit;
  final int creditPeriod;
  final double openingBalance;
  final double currentBalance;
  final String customerGroup;
  final String notes;
  final String priceList;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerDto({
    required this.id,
    this.businessId,
    required this.name,
    this.customerType = 'CUSTOMER',
    this.type = 'Retail',
    this.isRegistered = false,
    this.gstin = '',
    this.pan = '',
    this.mobile = '',
    this.email = '',
    this.billingAddress = '',
    this.shippingAddress = '',
    this.state = '',
    this.stateCode = '',
    this.creditLimit = 0.0,
    this.creditPeriod = 0,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.customerGroup = 'General',
    this.notes = '',
    this.priceList = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory from backend JSON response
  factory CustomerDto.fromJson(Map<String, dynamic> json) {
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

    return CustomerDto(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString(),
      name: json['name']?.toString() ?? '',
      customerType: json['customerType']?.toString() ?? 'CUSTOMER',
      type: json['type']?.toString() ?? json['customerGroup']?.toString() ?? 'Retail',
      isRegistered: json['isRegistered'] == true,
      gstin: json['gstin']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['mobileNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      billingAddress: json['billingAddress']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',
      creditLimit: parseDouble(json['creditLimit']),
      creditPeriod: parseInt(json['creditPeriod'] ?? json['creditPeriodDays']),
      openingBalance: parseDouble(json['openingBalance']),
      currentBalance: parseDouble(json['currentBalance']),
      customerGroup: json['customerGroup']?.toString() ?? json['type']?.toString() ?? 'General',
      notes: json['notes']?.toString() ?? '',
      priceList: json['priceList']?.toString() ?? '',
      isActive: json['isActive'] != false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  /// Converts DTO to Domain Customer entity
  Customer toDomain() {
    return Customer(
      id: id,
      name: name,
      type: type,
      gstin: gstin,
      pan: pan,
      mobile: mobile,
      email: email,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      state: state,
      stateCode: stateCode,
      creditLimit: creditLimit,
      creditPeriod: creditPeriod,
      openingBalance: openingBalance,
      currentBalance: currentBalance,
      customerGroup: customerGroup,
      notes: notes,
      isRegistered: isRegistered,
    );
  }

  /// Factory from Domain Customer entity
  factory CustomerDto.fromDomain(Customer customer) {
    return CustomerDto(
      id: customer.id,
      name: customer.name,
      type: customer.type,
      gstin: customer.gstin,
      pan: customer.pan,
      mobile: customer.mobile,
      email: customer.email,
      billingAddress: customer.billingAddress,
      shippingAddress: customer.shippingAddress,
      state: customer.state,
      stateCode: customer.stateCode,
      creditLimit: customer.creditLimit,
      creditPeriod: customer.creditPeriod,
      openingBalance: customer.openingBalance,
      currentBalance: customer.currentBalance,
      customerGroup: customer.customerGroup,
      notes: customer.notes,
      isRegistered: customer.isRegistered,
    );
  }

  /// Convert to JSON payload for backend POST / PUT requests
  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
      'customerGroup': customerGroup,
      'isRegistered': isRegistered,
      'gstin': gstin.isNotEmpty ? gstin : null,
      'pan': pan.isNotEmpty ? pan : null,
      'mobileNumber': mobile.isNotEmpty ? mobile : null,
      'email': email.isNotEmpty ? email : null,
      'billingAddress': billingAddress.isNotEmpty ? billingAddress : null,
      'shippingAddress': shippingAddress.isNotEmpty ? shippingAddress : null,
      'state': state.isNotEmpty ? state : null,
      'stateCode': stateCode.isNotEmpty ? stateCode : null,
      'creditLimit': creditLimit,
      'creditPeriodDays': creditPeriod,
      'openingBalance': openingBalance,
      'notes': notes.isNotEmpty ? notes : null,
      'priceList': priceList.isNotEmpty ? priceList : null,
      'isActive': isActive,
    };

    if (!isUpdate && businessId != null && businessId!.isNotEmpty) {
      map['businessId'] = businessId;
    }

    return map;
  }
}

/// Paginated response from GET /api/v1/customers
class CustomerListResponse {
  final List<Customer> customers;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const CustomerListResponse({
    required this.customers,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['customers'] as List<dynamic>? ?? [];
    final customers = rawList
        .map((e) => CustomerDto.fromJson(e as Map<String, dynamic>))
        .where((dto) => dto.isActive)
        .map((dto) => dto.toDomain())
        .toList();


    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return CustomerListResponse(
      customers: customers,
      total: (pagination['total'] as num?)?.toInt() ?? customers.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: pagination['hasNextPage'] == true,
      hasPrevPage: pagination['hasPrevPage'] == true,
    );
  }
}

/// Metrics summary from GET /api/v1/customers/metrics/summary
class CustomerMetricsDto {
  final int totalCustomers;
  final int activeCustomers;
  final int inactiveCustomers;
  final int registeredCustomers;
  final int unregisteredCustomers;
  final double totalOpeningBalance;
  final double totalInvoiced;
  final double totalReceived;
  final double totalReceivables;

  const CustomerMetricsDto({
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.inactiveCustomers = 0,
    this.registeredCustomers = 0,
    this.unregisteredCustomers = 0,
    this.totalOpeningBalance = 0.0,
    this.totalInvoiced = 0.0,
    this.totalReceived = 0.0,
    this.totalReceivables = 0.0,
  });

  factory CustomerMetricsDto.fromJson(Map<String, dynamic> json) {
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

    return CustomerMetricsDto(
      totalCustomers: parseInt(json['totalCustomers']),
      activeCustomers: parseInt(json['activeCustomers']),
      inactiveCustomers: parseInt(json['inactiveCustomers']),
      registeredCustomers: parseInt(json['registeredCustomers']),
      unregisteredCustomers: parseInt(json['unregisteredCustomers']),
      totalOpeningBalance: parseDouble(json['totalOpeningBalance']),
      totalInvoiced: parseDouble(json['totalInvoiced']),
      totalReceived: parseDouble(json['totalReceived']),
      totalReceivables: parseDouble(json['totalReceivables']),
    );
  }
}

/// Detailed Customer profile response from GET /api/v1/customers/:id
class CustomerDetailDto {
  final Customer customer;
  final Map<String, dynamic> statistics;
  final List<Map<String, dynamic>> recentInvoices;
  final List<Map<String, dynamic>> recentReceipts;
  final List<Map<String, dynamic>> recentLedgerEntries;

  const CustomerDetailDto({
    required this.customer,
    required this.statistics,
    required this.recentInvoices,
    required this.recentReceipts,
    required this.recentLedgerEntries,
  });

  factory CustomerDetailDto.fromJson(Map<String, dynamic> json) {
    final customer = CustomerDto.fromJson(json).toDomain();
    final stats = json['statistics'] as Map<String, dynamic>? ?? {};
    
    final rawInvoices = json['recentInvoices'] as List<dynamic>? ?? [];
    final invoices = rawInvoices.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawReceipts = json['recentReceipts'] as List<dynamic>? ?? [];
    final receipts = rawReceipts.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawLedger = json['recentLedgerEntries'] as List<dynamic>? ?? [];
    final ledger = rawLedger.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return CustomerDetailDto(
      customer: customer,
      statistics: stats,
      recentInvoices: invoices,
      recentReceipts: receipts,
      recentLedgerEntries: ledger,
    );
  }
}
