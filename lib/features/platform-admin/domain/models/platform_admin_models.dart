import 'package:flutter/material.dart';

enum TenantStatus {
  active,
  trial,
  suspended,
  pending,
}

enum PlanBillingCycle {
  monthly,
  yearly,
}

class SuperAdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatarUrl;
  final DateTime lastLogin;

  const SuperAdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl = '',
    required this.lastLogin,
  });
}

class OrganizationTenant {
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
  final TenantStatus status;
  final double monthlySpend;
  final int totalInvoices;
  final int activeUsersCount;
  final int maxUsersLimit;
  final double storageUsedGb;
  final double storageLimitGb;
  final DateTime createdAt;
  final DateTime renewalDate;

  const OrganizationTenant({
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

  Color get statusColor {
    switch (status) {
      case TenantStatus.active:
        return const Color(0xFF16A34A);
      case TenantStatus.trial:
        return const Color(0xFF2563EB);
      case TenantStatus.suspended:
        return const Color(0xFFDC2626);
      case TenantStatus.pending:
        return const Color(0xFFD97706);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case TenantStatus.active:
        return const Color(0xFFDCFCE7);
      case TenantStatus.trial:
        return const Color(0xFFDBEAFE);
      case TenantStatus.suspended:
        return const Color(0xFFFEE2E2);
      case TenantStatus.pending:
        return const Color(0xFFFEF3C7);
    }
  }

  String get statusLabel {
    switch (status) {
      case TenantStatus.active:
        return 'Active';
      case TenantStatus.trial:
        return 'Free Trial';
      case TenantStatus.suspended:
        return 'Suspended';
      case TenantStatus.pending:
        return 'Pending Setup';
    }
  }

  OrganizationTenant copyWith({
    String? name,
    String? code,
    String? domain,
    String? gstin,
    String? contactPerson,
    String? contactEmail,
    String? contactPhone,
    String? planId,
    String? planName,
    TenantStatus? status,
    double? monthlySpend,
    int? totalInvoices,
    int? activeUsersCount,
    int? maxUsersLimit,
    double? storageUsedGb,
    double? storageLimitGb,
    DateTime? renewalDate,
  }) {
    return OrganizationTenant(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      domain: domain ?? this.domain,
      gstin: gstin ?? this.gstin,
      contactPerson: contactPerson ?? this.contactPerson,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      monthlySpend: monthlySpend ?? this.monthlySpend,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      activeUsersCount: activeUsersCount ?? this.activeUsersCount,
      maxUsersLimit: maxUsersLimit ?? this.maxUsersLimit,
      storageUsedGb: storageUsedGb ?? this.storageUsedGb,
      storageLimitGb: storageLimitGb ?? this.storageLimitGb,
      createdAt: createdAt,
      renewalDate: renewalDate ?? this.renewalDate,
    );
  }
}

class PlatformPlan {
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
  final Color themeColor;

  const PlatformPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    required this.priceYearly,
    required this.maxUsers,
    required this.maxInvoicesPerMonth,
    required this.storageLimitGb,
    required this.features,
    this.isPopular = false,
    required this.activeTenantsCount,
    required this.themeColor,
  });

  PlatformPlan copyWith({
    String? name,
    String? tagline,
    double? priceMonthly,
    double? priceYearly,
    int? maxUsers,
    int? maxInvoicesPerMonth,
    double? storageLimitGb,
    List<String>? features,
    bool? isPopular,
    int? activeTenantsCount,
    Color? themeColor,
  }) {
    return PlatformPlan(
      id: id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      priceMonthly: priceMonthly ?? this.priceMonthly,
      priceYearly: priceYearly ?? this.priceYearly,
      maxUsers: maxUsers ?? this.maxUsers,
      maxInvoicesPerMonth: maxInvoicesPerMonth ?? this.maxInvoicesPerMonth,
      storageLimitGb: storageLimitGb ?? this.storageLimitGb,
      features: features ?? this.features,
      isPopular: isPopular ?? this.isPopular,
      activeTenantsCount: activeTenantsCount ?? this.activeTenantsCount,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}

class OnboardingRequest {
  final String id;
  final String organizationName;
  final String gstin;
  final String adminName;
  final String adminEmail;
  final String adminPhone;
  final String requestedPlanId;
  final String requestedPlanName;
  final String businessType;
  final String state;
  final TenantStatus status;
  final DateTime requestedAt;

  const OnboardingRequest({
    required this.id,
    required this.organizationName,
    required this.gstin,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhone,
    required this.requestedPlanId,
    required this.requestedPlanName,
    required this.businessType,
    required this.state,
    required this.status,
    required this.requestedAt,
  });

  OnboardingRequest copyWith({
    TenantStatus? status,
  }) {
    return OnboardingRequest(
      id: id,
      organizationName: organizationName,
      gstin: gstin,
      adminName: adminName,
      adminEmail: adminEmail,
      adminPhone: adminPhone,
      requestedPlanId: requestedPlanId,
      requestedPlanName: requestedPlanName,
      businessType: businessType,
      state: state,
      status: status ?? this.status,
      requestedAt: requestedAt,
    );
  }
}

class PlatformKPIs {
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

  const PlatformKPIs({
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
}
