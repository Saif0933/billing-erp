class OnboardOrganizationRequest {
  final String organizationName;
  final String? legalName;
  final String? tradeName;
  final String organizationType;
  final String? businessNature;
  final String? industry;
  final String? pan;
  final String? dateOfIncorporation;
  final String? logoUrl;
  final String email;
  final String mobileNumber;
  final String? website;
  final String? altPhone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? businessAddress;
  final String? billingAddress;
  final String? shippingAddress;
  final String currency;
  final String? financialYearStart;
  final String? booksStartingDate;
  final bool isGstRegistered;
  final String gstRegistrationType;
  final String? gstin;
  final String? tan;
  final String? cinOrLlpin;
  final String? msmeNumber;
  final String adminName;
  final String? adminEmail;
  final String password;
  final String adminRole;
  final List<String> teamInvites;
  final String? planId;
  final String planName;
  final String billingCycle;

  const OnboardOrganizationRequest({
    required this.organizationName,
    this.legalName,
    this.tradeName,
    this.organizationType = 'Private Limited Company',
    this.businessNature,
    this.industry,
    this.pan,
    this.dateOfIncorporation,
    this.logoUrl,
    required this.email,
    required this.mobileNumber,
    this.website,
    this.altPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pinCode,
    this.businessAddress,
    this.billingAddress,
    this.shippingAddress,
    this.currency = 'INR - Indian Rupee (₹)',
    this.financialYearStart,
    this.booksStartingDate,
    this.isGstRegistered = true,
    this.gstRegistrationType = 'REGULAR',
    this.gstin,
    this.tan,
    this.cinOrLlpin,
    this.msmeNumber,
    required this.adminName,
    this.adminEmail,
    required this.password,
    this.adminRole = 'Store Owner / MD',
    this.teamInvites = const [],
    this.planId,
    this.planName = 'Growth',
    this.billingCycle = 'MONTHLY',
  });

  Map<String, dynamic> toJson() {
    return {
      'organizationName': organizationName,
      'legalName': legalName ?? organizationName,
      'tradeName': tradeName ?? organizationName,
      'organizationType': organizationType,
      'businessNature': businessNature,
      'industry': industry,
      'pan': pan,
      'dateOfIncorporation': dateOfIncorporation,
      'logoUrl': logoUrl,
      'email': email,
      'mobileNumber': mobileNumber,
      'website': website,
      'altPhone': altPhone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'businessAddress': businessAddress,
      'billingAddress': billingAddress,
      'shippingAddress': shippingAddress,
      'currency': currency,
      'financialYearStart': financialYearStart,
      'booksStartingDate': booksStartingDate,
      'isGstRegistered': isGstRegistered,
      'gstRegistrationType': gstRegistrationType,
      'gstin': gstin,
      'tan': tan,
      'cinOrLlpin': cinOrLlpin,
      'msmeNumber': msmeNumber,
      'adminName': adminName,
      'adminEmail': adminEmail ?? email,
      'password': password,
      'adminRole': adminRole,
      'teamInvites': teamInvites,
      'planId': planId,
      'planName': planName,
      'billingCycle': billingCycle,
    };
  }
}

class GstinValidationResult {
  final bool isValid;
  final String gstin;
  final String stateCode;
  final String stateName;
  final String pan;
  final String entityType;
  final bool isAlreadyRegistered;
  final String? registeredBusinessName;

  const GstinValidationResult({
    required this.isValid,
    required this.gstin,
    required this.stateCode,
    required this.stateName,
    required this.pan,
    required this.entityType,
    required this.isAlreadyRegistered,
    this.registeredBusinessName,
  });

  factory GstinValidationResult.fromJson(Map<String, dynamic> json) {
    return GstinValidationResult(
      isValid: json['isValid'] ?? false,
      gstin: json['gstin']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',
      stateName: json['stateName']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      isAlreadyRegistered: json['isAlreadyRegisteredInPlatform'] ?? false,
      registeredBusinessName: json['registeredBusinessName']?.toString(),
    );
  }
}

class NameAvailabilityResult {
  final bool isAvailable;
  final String name;
  final String suggestedSubdomain;
  final String? existingOrganizationId;

  const NameAvailabilityResult({
    required this.isAvailable,
    required this.name,
    required this.suggestedSubdomain,
    this.existingOrganizationId,
  });

  factory NameAvailabilityResult.fromJson(Map<String, dynamic> json) {
    return NameAvailabilityResult(
      isAvailable: json['isAvailable'] ?? false,
      name: json['name']?.toString() ?? '',
      suggestedSubdomain: json['suggestedSubdomain']?.toString() ?? '',
      existingOrganizationId: json['existingOrganizationId']?.toString(),
    );
  }
}

class OnboardingResponseModel {
  final String businessId;
  final String businessName;
  final String? gstin;
  final String? pan;
  final String email;
  final String mobileNumber;
  final String? state;
  final String? logoUrl;
  final String adminUserId;
  final String adminUserName;
  final String adminUserEmail;
  final String planName;
  final String subscriptionStatus;
  final String? accessToken;
  final String? refreshToken;

  const OnboardingResponseModel({
    required this.businessId,
    required this.businessName,
    this.gstin,
    this.pan,
    required this.email,
    required this.mobileNumber,
    this.state,
    this.logoUrl,
    required this.adminUserId,
    required this.adminUserName,
    required this.adminUserEmail,
    required this.planName,
    required this.subscriptionStatus,
    this.accessToken,
    this.refreshToken,
  });

  factory OnboardingResponseModel.fromJson(Map<String, dynamic> json) {
    final org = json['organization'] as Map<String, dynamic>? ?? {};
    final user = json['adminUser'] as Map<String, dynamic>? ?? {};
    final sub = json['subscription'] as Map<String, dynamic>? ?? {};
    final tokens = json['tokens'] as Map<String, dynamic>? ?? {};

    return OnboardingResponseModel(
      businessId: org['id']?.toString() ?? '',
      businessName: org['businessName']?.toString() ?? '',
      gstin: org['gstin']?.toString(),
      pan: org['pan']?.toString(),
      email: org['email']?.toString() ?? '',
      mobileNumber: org['mobileNumber']?.toString() ?? '',
      state: org['state']?.toString(),
      logoUrl: org['logoUrl']?.toString(),
      adminUserId: user['id']?.toString() ?? '',
      adminUserName: user['fullName']?.toString() ?? '',
      adminUserEmail: user['email']?.toString() ?? '',
      planName: sub['planName']?.toString() ?? 'Growth',
      subscriptionStatus: sub['status']?.toString() ?? 'TRIALING',
      accessToken: tokens['accessToken']?.toString(),
      refreshToken: tokens['refreshToken']?.toString(),
    );
  }
}
