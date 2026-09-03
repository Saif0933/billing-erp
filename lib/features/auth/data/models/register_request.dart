class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final bool isPlatformAdmin;
  final String platform;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.isPlatformAdmin = false,
    this.platform = 'WEB',
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phone != null && phone!.isNotEmpty) 'phone': phone!.trim(),
      'isPlatformAdmin': isPlatformAdmin,
      'platform': platform,
    };
  }
}
