class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final bool isPlatformAdmin;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime? createdAt;
  final String? accessToken;
  final String? refreshToken;
  final List<dynamic>? businessMemberships;
  final List<dynamic>? ownedBusinesses;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.isPlatformAdmin = false,
    this.isEmailVerified = false,
    this.isActive = true,
    this.createdAt,
    this.accessToken,
    this.refreshToken,
    this.businessMemberships,
    this.ownedBusinesses,
  });

  /// Backwards compatibility getter for `name`
  String get name => fullName;

  factory UserModel.fromJson(Map<String, dynamic> json, {String? accessToken, String? refreshToken}) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      isPlatformAdmin: json['isPlatformAdmin'] == true,
      isEmailVerified: json['isEmailVerified'] == true,
      isActive: json['isActive'] != false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      accessToken: accessToken ?? json['accessToken']?.toString(),
      refreshToken: refreshToken ?? json['refreshToken']?.toString(),
      businessMemberships: json['businessMemberships'] as List<dynamic>?,
      ownedBusinesses: json['ownedBusinesses'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'isPlatformAdmin': isPlatformAdmin,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'businessMemberships': businessMemberships,
      'ownedBusinesses': ownedBusinesses,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    bool? isPlatformAdmin,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? createdAt,
    String? accessToken,
    String? refreshToken,
    List<dynamic>? businessMemberships,
    List<dynamic>? ownedBusinesses,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isPlatformAdmin: isPlatformAdmin ?? this.isPlatformAdmin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      businessMemberships: businessMemberships ?? this.businessMemberships,
      ownedBusinesses: ownedBusinesses ?? this.ownedBusinesses,
    );
  }
}
