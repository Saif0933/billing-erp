class LoginRequest {
  final String email;
  final String password;
  final String platform;
  final String? deviceInfo;
  final bool isPlatformAdminPortal;

  const LoginRequest({
    required this.email,
    required this.password,
    this.platform = 'WEB',
    this.deviceInfo,
    this.isPlatformAdminPortal = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'platform': platform,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      'isPlatformAdminPortal': isPlatformAdminPortal,
    };
  }
}
