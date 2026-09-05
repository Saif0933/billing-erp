import 'package:flutter/material.dart';
import '../../domain/models/platform_admin_models.dart';

/// DTO for serializing and deserializing OrganizationTenant data between Frontend and Backend
class OrganizationTenantDto {
  final String id;
  final String name;
  final String code;
  final String domain;
  final String gstin;
  final String contactPerson;
  final String contactEmail;
  final String contactPhone;
  final String planId;
  final String planName;
  final String status;
  final double monthlySpend;
  final int totalInvoices;
  final int activeUsersCount;
  final int maxUsersLimit;
  final double storageUsedGb;
  final double storageLimitGb;
  final DateTime createdAt;
  final DateTime renewalDate;

  const OrganizationTenantDto({
    required this.id,
    required this.name,
    required this.code,
    required this.domain,
    required this.gstin,
    required this.contactPerson,
    required this.contactEmail,
    required this.contactPhone,
    required this.planId,
    required this.planName,
    required this.status,
    required this.monthlySpend,
    required this.totalInvoices,
    required this.activeUsersCount,
    required this.maxUsersLimit,
    required this.storageUsedGb,
    required this.storageLimitGb,
    required this.createdAt,
    required this.renewalDate,
  });

  /// Factory from backend JSON
  factory OrganizationTenantDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return fallback;
      }
    }

    return OrganizationTenantDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      contactEmail: json['contactEmail']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      planName: json['planName']?.toString() ?? 'Growth',
      status: json['status']?.toString().toLowerCase() ?? 'active',
      monthlySpend: (json['monthlySpend'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      activeUsersCount: (json['activeUsersCount'] as num?)?.toInt() ?? 1,
      maxUsersLimit: (json['maxUsersLimit'] as num?)?.toInt() ?? 15,
      storageUsedGb: (json['storageUsedGb'] as num?)?.toDouble() ?? 0.1,
      storageLimitGb: (json['storageLimitGb'] as num?)?.toDouble() ?? 25.0,
      createdAt: parseDate(json['createdAt'], DateTime.now()),
      renewalDate: parseDate(
        json['renewalDate'],
        DateTime.now().add(const Duration(days: 30)),
      ),
    );
  }

  /// Convert backend status string to domain TenantStatus enum
  static TenantStatus parseStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'trial':
        return TenantStatus.trial;
      case 'suspended':
        return TenantStatus.suspended;
      case 'pending':
        return TenantStatus.pending;
      case 'active':
      default:
        return TenantStatus.active;
    }
  }

  /// Convert domain TenantStatus enum to backend string
  static String formatStatus(TenantStatus status) {
    switch (status) {
      case TenantStatus.trial:
        return 'trial';
      case TenantStatus.suspended:
        return 'suspended';
      case TenantStatus.pending:
        return 'pending';
      case TenantStatus.active:
        return 'active';
    }
  }

  /// Convert to Domain entity
  OrganizationTenant toDomain() {
    return OrganizationTenant(
      id: id,
      name: name,
      code: code,
      domain: domain,
      gstin: gstin,
      contactPerson: contactPerson,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      planId: planId,
      planName: planName,
      status: parseStatus(status),
      monthlySpend: monthlySpend,
      totalInvoices: totalInvoices,
      activeUsersCount: activeUsersCount,
      maxUsersLimit: maxUsersLimit,
      storageUsedGb: storageUsedGb,
      storageLimitGb: storageLimitGb,
      createdAt: createdAt,
      renewalDate: renewalDate,
    );
  }

  /// Factory from Domain entity
  factory OrganizationTenantDto.fromDomain(OrganizationTenant domain) {
    return OrganizationTenantDto(
      id: domain.id,
      name: domain.name,
      code: domain.code,
      domain: domain.domain,
      gstin: domain.gstin,
      contactPerson: domain.contactPerson,
      contactEmail: domain.contactEmail,
      contactPhone: domain.contactPhone,
      planId: domain.planId,
      planName: domain.planName,
      status: formatStatus(domain.status),
      monthlySpend: domain.monthlySpend,
      totalInvoices: domain.totalInvoices,
      activeUsersCount: domain.activeUsersCount,
      maxUsersLimit: domain.maxUsersLimit,
      storageUsedGb: domain.storageUsedGb,
      storageLimitGb: domain.storageLimitGb,
      createdAt: domain.createdAt,
      renewalDate: domain.renewalDate,
    );
  }

  /// Convert to JSON payload for backend POST / PUT
  Map<String, dynamic> toJson({bool isUpdate = false, String? password}) {
    final map = <String, dynamic>{
      'name': name,
      'code': code,
      'domain': domain,
      'gstin': gstin.isNotEmpty ? gstin : null,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone.isNotEmpty ? contactPhone : null,
      'planName': planName,
      'status': status,
      'maxUsersLimit': maxUsersLimit,
      'storageLimitGb': storageLimitGb,
    };

    if (!isUpdate && password != null && password.isNotEmpty) {
      map['password'] = password;
    }

    return map;
  }
}

/// DTO for Platform KPIs
class PlatformKPIsDto {
  final double totalMrr;
  final double totalArr;
  final double mrrGrowthPercentage;
  final int totalTenants;
  final int activeTenants;
  final int trialTenants;
  final int totalUsers;
  final double systemUptimePercentage;
  final int serverLatencyMs;
  final int pendingOnboardings;

  const PlatformKPIsDto({
    required this.totalMrr,
    required this.totalArr,
    required this.mrrGrowthPercentage,
    required this.totalTenants,
    required this.activeTenants,
    required this.trialTenants,
    required this.totalUsers,
    required this.systemUptimePercentage,
    required this.serverLatencyMs,
    required this.pendingOnboardings,
  });

  factory PlatformKPIsDto.fromJson(Map<String, dynamic> json) {
    return PlatformKPIsDto(
      totalMrr: (json['totalMrr'] as num?)?.toDouble() ?? 0.0,
      totalArr: (json['totalArr'] as num?)?.toDouble() ?? 0.0,
      mrrGrowthPercentage:
          (json['mrrGrowthPercentage'] as num?)?.toDouble() ?? 18.4,
      totalTenants: (json['totalTenants'] as num?)?.toInt() ?? 0,
      activeTenants: (json['activeTenants'] as num?)?.toInt() ?? 0,
      trialTenants: (json['trialTenants'] as num?)?.toInt() ?? 0,
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      systemUptimePercentage:
          (json['systemUptimePercentage'] as num?)?.toDouble() ?? 99.98,
      serverLatencyMs: (json['serverLatencyMs'] as num?)?.toInt() ?? 38,
      pendingOnboardings: (json['pendingOnboardings'] as num?)?.toInt() ?? 0,
    );
  }

  PlatformKPIs toDomain() {
    return PlatformKPIs(
      totalMrr: totalMrr,
      totalArr: totalArr,
      mrrGrowthPercentage: mrrGrowthPercentage,
      totalTenants: totalTenants,
      activeTenants: activeTenants,
      trialTenants: trialTenants,
      totalUsers: totalUsers,
      systemUptimePercentage: systemUptimePercentage,
      serverLatencyMs: serverLatencyMs,
      pendingOnboardings: pendingOnboardings,
    );
  }
}

/// DTO for Paginated Organizations response envelope
class OrganizationListResponseDto {
  final List<OrganizationTenant> tenants;
  final int total;
  final PlatformKPIs? kpis;

  const OrganizationListResponseDto({
    required this.tenants,
    required this.total,
    this.kpis,
  });

  factory OrganizationListResponseDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['tenants'] as List<dynamic>? ?? [];
    final tenants = rawList
        .map((item) =>
            OrganizationTenantDto.fromJson(item as Map<String, dynamic>).toDomain())
        .toList();

    final total = (json['total'] as num?)?.toInt() ?? tenants.length;

    PlatformKPIs? kpis;
    if (json['kpis'] != null && json['kpis'] is Map<String, dynamic>) {
      kpis = PlatformKPIsDto.fromJson(json['kpis'] as Map<String, dynamic>).toDomain();
    }

    return OrganizationListResponseDto(
      tenants: tenants,
      total: total,
      kpis: kpis,
    );
  }
}

/// Color parsing helper
Color parseHexColor(String hexString) {
  try {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return const Color(0xFF4F46E5);
  }
}

/// Color formatting helper
String colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

/// DTO for PlatformPlan
class PlatformPlanDto {
  final String id;
  final String name;
  final String tagline;
  final double priceMonthly;
  final double priceYearly;
  final int maxUsers;
  final int maxInvoicesPerMonth;
  final double storageLimitGb;
  final List<String> features;
  final bool isPopular;
  final int activeTenantsCount;
  final String themeColor;

  const PlatformPlanDto({
    required this.id,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    required this.priceYearly,
    required this.maxUsers,
    required this.maxInvoicesPerMonth,
    required this.storageLimitGb,
    required this.features,
    required this.isPopular,
    required this.activeTenantsCount,
    required this.themeColor,
  });

  factory PlatformPlanDto.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = <String>[];
    if (rawFeatures is List) {
      for (final f in rawFeatures) {
        if (f != null) features.add(f.toString());
      }
    }

    final priceMonthly = (json['priceMonthly'] as num?)?.toDouble() ?? 0.0;
    final priceYearly =
        (json['priceYearly'] as num?)?.toDouble() ?? (priceMonthly * 10);

    return PlatformPlanDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      priceMonthly: priceMonthly,
      priceYearly: priceYearly,
      maxUsers: (json['maxUsers'] as num?)?.toInt() ?? 10,
      maxInvoicesPerMonth:
          (json['maxInvoicesPerMonth'] as num?)?.toInt() ?? 5000,
      storageLimitGb: (json['storageLimitGb'] as num?)?.toDouble() ?? 25.0,
      features: features,
      isPopular: json['isPopular'] == true,
      activeTenantsCount: (json['activeTenantsCount'] as num?)?.toInt() ?? 0,
      themeColor: json['themeColor']?.toString() ?? '#4F46E5',
    );
  }

  PlatformPlan toDomain() {
    return PlatformPlan(
      id: id,
      name: name,
      tagline: tagline,
      priceMonthly: priceMonthly,
      priceYearly: priceYearly,
      maxUsers: maxUsers,
      maxInvoicesPerMonth: maxInvoicesPerMonth,
      storageLimitGb: storageLimitGb,
      features: features,
      isPopular: isPopular,
      activeTenantsCount: activeTenantsCount,
      themeColor: parseHexColor(themeColor),
    );
  }

  factory PlatformPlanDto.fromDomain(PlatformPlan domain) {
    return PlatformPlanDto(
      id: domain.id,
      name: domain.name,
      tagline: domain.tagline,
      priceMonthly: domain.priceMonthly,
      priceYearly: domain.priceYearly,
      maxUsers: domain.maxUsers,
      maxInvoicesPerMonth: domain.maxInvoicesPerMonth,
      storageLimitGb: domain.storageLimitGb,
      features: domain.features,
      isPopular: domain.isPopular,
      activeTenantsCount: domain.activeTenantsCount,
      themeColor: colorToHex(domain.themeColor),
    );
  }

  Map<String, dynamic> toJson({bool isUpdate = false}) {
    return {
      'name': name,
      'tagline': tagline,
      'priceMonthly': priceMonthly,
      'priceYearly': priceYearly,
      'maxUsers': maxUsers,
      'maxInvoicesPerMonth': maxInvoicesPerMonth,
      'storageLimitGb': storageLimitGb,
      'features': features,
      'isPopular': isPopular,
      'themeColor': themeColor,
    };
  }
}
