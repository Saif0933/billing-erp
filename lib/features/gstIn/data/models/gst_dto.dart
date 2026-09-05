import '../../domain/models/gst_models.dart';

/// Request DTO for updating Business GST Profile (PUT /api/v1/gst/profile)
class UpdateGstProfileDto {
  final String? gstin;
  final String? legalName;
  final String? tradeName;
  final String? primaryPlaceOfBusiness;
  final String? state;
  final String? stateCode;
  final String? taxpayerType; // REGULAR, COMPOSITION, SEZ, NON_RESIDENT, UNREGISTERED
  final String? status; // Active, Inactive, Suspended, Cancelled
  final String? filingFrequency; // Monthly, Quarterly

  const UpdateGstProfileDto({
    this.gstin,
    this.legalName,
    this.tradeName,
    this.primaryPlaceOfBusiness,
    this.state,
    this.stateCode,
    this.taxpayerType,
    this.status,
    this.filingFrequency,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (gstin != null && gstin!.isNotEmpty) map['gstin'] = gstin;
    if (legalName != null && legalName!.isNotEmpty) map['legalName'] = legalName;
    if (tradeName != null) map['tradeName'] = tradeName;
    if (primaryPlaceOfBusiness != null) map['primaryPlaceOfBusiness'] = primaryPlaceOfBusiness;
    if (state != null) map['state'] = state;
    if (stateCode != null) map['stateCode'] = stateCode;
    if (taxpayerType != null) map['taxpayerType'] = taxpayerType;
    if (status != null) map['status'] = status;
    if (filingFrequency != null) map['filingFrequency'] = filingFrequency;
    return map;
  }
}

/// Request DTO for submitting/filing a GST Return (POST /api/v1/gst/returns/file)
class FileGstReturnRequestDto {
  final String returnType; // GSTR-1, GSTR-3B, GSTR-2B, GSTR-9
  final String taxPeriod; // e.g. "May 2026"
  final String? arn;
  final double? liabilityAmount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalTax;
  final int totalInvoices;
  final String? rawPayloadJson;

  const FileGstReturnRequestDto({
    required this.returnType,
    required this.taxPeriod,
    this.arn,
    this.liabilityAmount,
    this.taxableAmount = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
    this.totalTax = 0.0,
    this.totalInvoices = 0,
    this.rawPayloadJson,
  });

  factory FileGstReturnRequestDto.fromDomain(GstReturnRecord record) {
    return FileGstReturnRequestDto(
      returnType: record.returnType,
      taxPeriod: record.taxPeriod,
      arn: record.arn.isNotEmpty ? record.arn : null,
      liabilityAmount: record.liabilityAmount,
      taxableAmount: record.taxableAmount,
      cgstAmount: record.cgstAmount,
      sgstAmount: record.sgstAmount,
      igstAmount: record.igstAmount,
      totalTax: record.totalTax,
      totalInvoices: record.totalInvoices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'returnType': returnType,
      'taxPeriod': taxPeriod,
      if (arn != null && arn!.isNotEmpty) 'arn': arn,
      if (liabilityAmount != null) 'liabilityAmount': liabilityAmount,
      'taxableAmount': taxableAmount,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'cessAmount': cessAmount,
      'totalTax': totalTax,
      'totalInvoices': totalInvoices,
      if (rawPayloadJson != null) 'rawPayloadJson': rawPayloadJson,
    };
  }
}

/// Response DTO from filing return
class FileGstReturnResponseDto {
  final String message;
  final String arn;
  final String filingDate;
  final Map<String, dynamic>? returnRecord;

  const FileGstReturnResponseDto({
    required this.message,
    required this.arn,
    required this.filingDate,
    this.returnRecord,
  });

  factory FileGstReturnResponseDto.fromJson(Map<String, dynamic> json) {
    return FileGstReturnResponseDto(
      message: json['message']?.toString() ?? 'Return filed successfully',
      arn: json['arn']?.toString() ?? '',
      filingDate: json['filingDate']?.toString() ?? '',
      returnRecord: json['returnRecord'] as Map<String, dynamic>?,
    );
  }
}

/// Request DTO for recording GST Challan payment (POST /api/v1/gst/payments)
class RecordGstPaymentRequestDto {
  final String challanNumber;
  final String? cpin;
  final String taxPeriod;
  final String? paymentDate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final String paymentMode;
  final String? bankName;
  final String? brn;

  const RecordGstPaymentRequestDto({
    required this.challanNumber,
    this.cpin,
    required this.taxPeriod,
    this.paymentDate,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
    this.paymentMode = 'NEFT/RTGS',
    this.bankName,
    this.brn,
  });

  Map<String, dynamic> toJson() {
    return {
      'challanNumber': challanNumber,
      if (cpin != null) 'cpin': cpin,
      'taxPeriod': taxPeriod,
      if (paymentDate != null) 'paymentDate': paymentDate,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'cessAmount': cessAmount,
      'paymentMode': paymentMode,
      if (bankName != null) 'bankName': bankName,
      if (brn != null) 'brn': brn,
    };
  }
}

/// Response DTO from syncing live with GST Portal
class GstPortalSyncResponseDto {
  final bool success;
  final String message;
  final String syncTimestamp;
  final int returnsCount;

  const GstPortalSyncResponseDto({
    required this.success,
    required this.message,
    required this.syncTimestamp,
    required this.returnsCount,
  });

  factory GstPortalSyncResponseDto.fromJson(Map<String, dynamic> json) {
    return GstPortalSyncResponseDto(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Synchronized with GST Portal',
      syncTimestamp: json['syncTimestamp']?.toString() ?? '',
      returnsCount: (json['returnsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
