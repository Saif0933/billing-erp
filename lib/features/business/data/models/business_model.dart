class BusinessModel {
  final String id;
  final String name;
  final String type; // e.g. Retail, Wholesale, etc.
  final String gstNumber;
  final String legalName;
  final String tradeName;
  final String pan;
  final String tan;
  final String cin;
  final String address;
  final String billingAddress;
  final String shippingAddress;
  final String state;
  final String stateCode;
  final String pinCode;
  final String email;
  final String mobile;
  final String financialYear;
  final String booksStartingDate;
  final String gstRegistrationType; // Regular, Composition, Unregistered, etc.
  final String logoUrl;
  final String bankName;
  final String bankAccountNo;
  final String bankIfsc;
  final String upiId;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    required this.gstNumber,
    this.legalName = '',
    this.tradeName = '',
    this.pan = '',
    this.tan = '',
    this.cin = '',
    this.address = '',
    this.billingAddress = '',
    this.shippingAddress = '',
    this.state = 'Maharashtra',
    this.stateCode = '27',
    this.pinCode = '',
    this.email = '',
    this.mobile = '',
    this.financialYear = '2026-27',
    this.booksStartingDate = '2026-04-01',
    this.gstRegistrationType = 'Regular',
    this.logoUrl = '',
    this.bankName = '',
    this.bankAccountNo = '',
    this.bankIfsc = '',
    this.upiId = '',
  });

  BusinessModel copyWith({
    String? name,
    String? type,
    String? gstNumber,
    String? legalName,
    String? tradeName,
    String? pan,
    String? tan,
    String? cin,
    String? address,
    String? billingAddress,
    String? shippingAddress,
    String? state,
    String? stateCode,
    String? pinCode,
    String? email,
    String? mobile,
    String? financialYear,
    String? booksStartingDate,
    String? gstRegistrationType,
    String? logoUrl,
    String? bankName,
    String? bankAccountNo,
    String? bankIfsc,
    String? upiId,
  }) {
    return BusinessModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      gstNumber: gstNumber ?? this.gstNumber,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      pan: pan ?? this.pan,
      tan: tan ?? this.tan,
      cin: cin ?? this.cin,
      address: address ?? this.address,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      pinCode: pinCode ?? this.pinCode,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      financialYear: financialYear ?? this.financialYear,
      booksStartingDate: booksStartingDate ?? this.booksStartingDate,
      gstRegistrationType: gstRegistrationType ?? this.gstRegistrationType,
      logoUrl: logoUrl ?? this.logoUrl,
      bankName: bankName ?? this.bankName,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      upiId: upiId ?? this.upiId,
    );
  }
}
