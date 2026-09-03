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
}
