import '../../../../core/models/billing_models.dart';

/// DTO for serializing and deserializing Service data between Frontend and Backend
class ServiceDto {
  final String id;
  final String? businessId;
  final String name;
  final String code;
  final String serviceCode;
  final String sacCode;
  final String description;
  final double rate;
  final double gstRate;
  final String unit;
  final double discount;
  final String incomeLedger;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceDto({
    required this.id,
    this.businessId,
    required this.name,
    this.code = '',
    this.serviceCode = '',
    this.sacCode = '',
    this.description = '',
    this.rate = 0.0,
    this.gstRate = 18.0,
    this.unit = 'Hour',
    this.discount = 0.0,
    this.incomeLedger = 'Service Income',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory from backend JSON response
  factory ServiceDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final code = json['code']?.toString() ??
        json['serviceCode']?.toString() ??
        '';

    final gst = parseDouble(json['gstRate'] ?? json['gstRatePercent'] ?? 18.0);
    final disc = parseDouble(json['discount'] ?? json['discountPercent'] ?? 0.0);

    return ServiceDto(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString(),
      name: json['name']?.toString() ?? '',
      code: code,
      serviceCode: code,
      sacCode: json['sacCode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rate: parseDouble(json['rate']),
      gstRate: gst,
      unit: json['unit']?.toString() ?? 'Hour',
      discount: disc,
      incomeLedger: json['incomeLedger']?.toString() ??
          json['incomeLedgerId']?.toString() ??
          'Service Income',
      isActive: json['isActive'] != false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  /// Converts DTO to Domain Service entity
  Service toDomain() {
    return Service(
      id: id,
      name: name,
      code: code,
      sacCode: sacCode,
      description: description,
      rate: rate,
      gstRate: gstRate,
      unit: unit,
      discount: discount,
      incomeLedger: incomeLedger,
      isActive: isActive,
    );
  }

  /// Factory from Domain Service entity
  factory ServiceDto.fromDomain(Service service) {
    return ServiceDto(
      id: service.id,
      name: service.name,
      code: service.code,
      serviceCode: service.code,
      sacCode: service.sacCode,
      description: service.description,
      rate: service.rate,
      gstRate: service.gstRate,
      unit: service.unit,
      discount: service.discount,
      incomeLedger: service.incomeLedger,
      isActive: service.isActive,
    );
  }

  /// Convert to JSON payload for backend POST / PUT requests
  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final map = <String, dynamic>{
      'name': name,
      'serviceCode': code.isNotEmpty ? code : null,
      'sacCode': sacCode.isNotEmpty ? sacCode : null,
      'description': description.isNotEmpty ? description : null,
      'rate': rate,
      'gstRatePercent': gstRate,
      'unit': unit.isNotEmpty ? unit : 'Hour',
      'discountPercent': discount,
      'incomeLedger': incomeLedger.isNotEmpty ? incomeLedger : null,
      'isActive': isActive,
    };

    if (!isUpdate && businessId != null && businessId!.isNotEmpty) {
      map['businessId'] = businessId;
    }

    return map;
  }
}

/// Paginated response from GET /api/v1/services
class ServiceListResponse {
  final List<Service> services;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const ServiceListResponse({
    required this.services,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory ServiceListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['services'] as List<dynamic>? ?? [];
    // Ensure inactive services are excluded by default
    final services = rawList
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>))
        .where((dto) => dto.isActive)
        .map((dto) => dto.toDomain())
        .toList();

    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return ServiceListResponse(
      services: services,
      total: (pagination['total'] as num?)?.toInt() ?? services.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: pagination['hasNextPage'] == true,
      hasPrevPage: pagination['hasPrevPage'] == true,
    );
  }
}

/// Metrics summary from GET /api/v1/services/metrics/summary
class ServiceMetricsDto {
  final int totalServices;
  final int activeServices;
  final int gstApplicableServices;
  final int exemptServices;
  final double averageRate;

  const ServiceMetricsDto({
    this.totalServices = 0,
    this.activeServices = 0,
    this.gstApplicableServices = 0,
    this.exemptServices = 0,
    this.averageRate = 0.0,
  });

  factory ServiceMetricsDto.fromJson(Map<String, dynamic> json) {
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

    return ServiceMetricsDto(
      totalServices: parseInt(json['totalServices']),
      activeServices: parseInt(json['activeServices']),
      gstApplicableServices: parseInt(json['gstApplicableServices']),
      exemptServices: parseInt(json['exemptServices']),
      averageRate: parseDouble(json['averageRate']),
    );
  }
}
