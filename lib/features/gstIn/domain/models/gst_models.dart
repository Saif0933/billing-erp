enum GstReturnStatus {
  filed,
  notFiled,
  pending,
  dueSoon,
  overdue,
}

enum TaxpayerType {
  regular,
  composition,
  sez,
  nonResident,
}

class GstProfile {
  final String gstin;
  final String legalName;
  final String tradeName;
  final String registrationDate;
  final String primaryPlaceOfBusiness;
  final String state;
  final String stateCode;
  final TaxpayerType taxpayerType;
  final String status;
  final String filingFrequency;

  const GstProfile({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.registrationDate,
    required this.primaryPlaceOfBusiness,
    required this.state,
    required this.stateCode,
    this.taxpayerType = TaxpayerType.regular,
    this.status = 'Active',
    this.filingFrequency = 'Monthly',
  });

  factory GstProfile.fromJson(Map<String, dynamic> json) {
    TaxpayerType type = TaxpayerType.regular;
    final typeStr = json['taxpayerType']?.toString().toUpperCase() ?? '';
    if (typeStr.contains('COMPOSITION')) {
      type = TaxpayerType.composition;
    } else if (typeStr.contains('SEZ')) {
      type = TaxpayerType.sez;
    } else if (typeStr.contains('NON_RESIDENT') || typeStr.contains('NON RESIDENT')) {
      type = TaxpayerType.nonResident;
    }

    return GstProfile(
      gstin: json['gstin']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? json['legalName']?.toString() ?? '',
      registrationDate: json['registrationDate']?.toString() ?? '01 Jul 2023',
      primaryPlaceOfBusiness: json['primaryPlaceOfBusiness']?.toString() ?? '',
      state: json['state']?.toString() ?? 'West Bengal',
      stateCode: json['stateCode']?.toString() ?? '19',
      taxpayerType: type,
      status: json['status']?.toString() ?? 'Active',
      filingFrequency: json['filingFrequency']?.toString() ?? 'Monthly',
    );
  }

  GstProfile copyWith({
    String? gstin,
    String? legalName,
    String? tradeName,
    String? registrationDate,
    String? primaryPlaceOfBusiness,
    String? state,
    String? stateCode,
    TaxpayerType? taxpayerType,
    String? status,
    String? filingFrequency,
  }) {
    return GstProfile(
      gstin: gstin ?? this.gstin,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      registrationDate: registrationDate ?? this.registrationDate,
      primaryPlaceOfBusiness: primaryPlaceOfBusiness ?? this.primaryPlaceOfBusiness,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      taxpayerType: taxpayerType ?? this.taxpayerType,
      status: status ?? this.status,
      filingFrequency: filingFrequency ?? this.filingFrequency,
    );
  }
}

class GstReturnRecord {
  final String id;
  final String returnType; // GSTR-1, GSTR-3B
  final String taxPeriod; // May 2026, Apr 2026, Mar 2026
  final String dueDate; // 11 Jun 2026, 20 Jun 2026
  final GstReturnStatus status;
  final double? liabilityAmount; // null for '-' or double amount
  final String arn;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;
  final int totalInvoices;

  const GstReturnRecord({
    required this.id,
    required this.returnType,
    required this.taxPeriod,
    required this.dueDate,
    required this.status,
    this.liabilityAmount,
    this.arn = '',
    this.taxableAmount = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.totalTax = 0.0,
    this.totalInvoices = 0,
  });

  factory GstReturnRecord.fromJson(Map<String, dynamic> json) {
    GstReturnStatus status = GstReturnStatus.notFiled;
    final statusStr = json['status']?.toString().toLowerCase() ?? '';
    if (statusStr == 'filed') {
      status = GstReturnStatus.filed;
    } else if (statusStr == 'duesoon' || statusStr == 'due_soon') {
      status = GstReturnStatus.dueSoon;
    } else if (statusStr == 'overdue') {
      status = GstReturnStatus.overdue;
    } else if (statusStr == 'pending') {
      status = GstReturnStatus.pending;
    }

    return GstReturnRecord(
      id: json['id']?.toString() ?? '',
      returnType: json['returnType']?.toString() ?? '',
      taxPeriod: json['taxPeriod']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      status: status,
      liabilityAmount: json['liabilityAmount'] != null
          ? (json['liabilityAmount'] as num).toDouble()
          : null,
      arn: json['arn']?.toString() ?? '',
      taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0.0,
      totalTax: (json['totalTax'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
    );
  }

  GstReturnRecord copyWith({
    String? id,
    String? returnType,
    String? taxPeriod,
    String? dueDate,
    GstReturnStatus? status,
    double? liabilityAmount,
    String? arn,
    double? taxableAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? totalTax,
    int? totalInvoices,
  }) {
    return GstReturnRecord(
      id: id ?? this.id,
      returnType: returnType ?? this.returnType,
      taxPeriod: taxPeriod ?? this.taxPeriod,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      liabilityAmount: liabilityAmount ?? this.liabilityAmount,
      arn: arn ?? this.arn,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      totalTax: totalTax ?? this.totalTax,
      totalInvoices: totalInvoices ?? this.totalInvoices,
    );
  }
}

class GstLiabilitySummary {
  final double totalLiability;
  final double igst;
  final double cgst;
  final double sgst;
  final double cess;
  final double paidThisFy;
  final double balanceThisFy;
  final String financialYear;

  const GstLiabilitySummary({
    required this.totalLiability,
    required this.igst,
    required this.cgst,
    required this.sgst,
    required this.cess,
    required this.paidThisFy,
    required this.balanceThisFy,
    this.financialYear = 'FY 2025-26',
  });

  factory GstLiabilitySummary.fromJson(Map<String, dynamic> json) {
    return GstLiabilitySummary(
      totalLiability: (json['totalLiability'] as num?)?.toDouble() ?? 0.0,
      igst: (json['igst'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      cess: (json['cess'] as num?)?.toDouble() ?? 0.0,
      paidThisFy: (json['paidThisFy'] as num?)?.toDouble() ?? 0.0,
      balanceThisFy: (json['balanceThisFy'] as num?)?.toDouble() ?? 0.0,
      financialYear: json['financialYear']?.toString() ?? 'FY 2025-26',
    );
  }
}

class GstKpiMetrics {
  final int returnsFiledCount;
  final int totalReturnsCount;
  final double returnCompliancePercentage;
  final double upcomingLiability;
  final double itcAvailable;
  final double annualTurnover;
  final String turnoverDateLabel;
  final String gstinStatus;

  const GstKpiMetrics({
    required this.returnsFiledCount,
    required this.totalReturnsCount,
    required this.returnCompliancePercentage,
    required this.upcomingLiability,
    required this.itcAvailable,
    required this.annualTurnover,
    required this.turnoverDateLabel,
    required this.gstinStatus,
  });

  factory GstKpiMetrics.fromJson(Map<String, dynamic> json) {
    return GstKpiMetrics(
      returnsFiledCount: (json['returnsFiledCount'] as num?)?.toInt() ?? 0,
      totalReturnsCount: (json['totalReturnsCount'] as num?)?.toInt() ?? 0,
      returnCompliancePercentage:
          (json['returnCompliancePercentage'] as num?)?.toDouble() ?? 0.0,
      upcomingLiability: (json['upcomingLiability'] as num?)?.toDouble() ?? 0.0,
      itcAvailable: (json['itcAvailable'] as num?)?.toDouble() ?? 0.0,
      annualTurnover: (json['annualTurnover'] as num?)?.toDouble() ?? 0.0,
      turnoverDateLabel: json['turnoverDateLabel']?.toString() ?? '',
      gstinStatus: json['gstinStatus']?.toString() ?? 'Active',
    );
  }
}

class GstinSearchResult {
  final String gstin;
  final String legalName;
  final String tradeName;
  final String status;
  final String taxpayerType;
  final String state;
  final String stateCode;
  final String address;
  final String pincode;
  final String dateOfRegistration;

  const GstinSearchResult({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.status,
    required this.taxpayerType,
    required this.state,
    required this.stateCode,
    required this.address,
    required this.pincode,
    required this.dateOfRegistration,
  });

  factory GstinSearchResult.fromJson(Map<String, dynamic> json) {
    return GstinSearchResult(
      gstin: json['gstin']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      taxpayerType: json['taxpayerType']?.toString() ?? 'Taxpayer - Regular',
      state: json['state']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      dateOfRegistration: json['dateOfRegistration']?.toString() ?? '',
    );
  }
}
