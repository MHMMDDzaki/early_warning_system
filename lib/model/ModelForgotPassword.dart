class ModelForgotPasswordRequest {
  final String username;

  ModelForgotPasswordRequest({required this.username});

  Map<String, dynamic> toMap() {
    return {
      'username': username,
    };
  }
}

class ModelForgotPasswordResponse {
  final bool success;
  final String message;
  final String? token; // Token bisa null jika request gagal

  ModelForgotPasswordResponse({
    required this.success,
    required this.message,
    this.token,
  });

  factory ModelForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ModelForgotPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      token: json['token'], // Akan null jika tidak ada di JSON
    );
  }
}

class ModelResetPasswordRequest {
  final String username;
  final String token;
  final String newPassword;

  ModelResetPasswordRequest({
    required this.username,
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'token': token,
      'newPassword': newPassword,
    };
  }
}

class ModelResetPasswordResponse {
  final bool success;
  final String message;

  ModelResetPasswordResponse({
    required this.success,
    required this.message,
  });

  factory ModelResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ModelResetPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}