class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;

  ApiResponse({
    this.data,
    this.message,
    required this.success,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse(
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message']?.toString(),
      success: json['success'] as bool? ?? true,
    );
  }
}
