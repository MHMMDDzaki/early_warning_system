import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/ModelForgotPassword.dart'; // Sesuaikan path jika berbeda

class ControllerForgotPassword {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<ModelForgotPasswordResponse> validateUsername(String username) async {
    if (baseUrl == null) {
      throw Exception("BASE_URL tidak ditemukan di .env");
    }
    final Uri forgotPasswordUrl = Uri.parse('$baseUrl/api/auth/forgot-password');
    final requestData = ModelForgotPasswordRequest(username: username);

    try {
      final response = await http.post(
        forgotPasswordUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData.toMap()),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final forgotPasswordResponse = ModelForgotPasswordResponse.fromJson(responseBody);
        if (forgotPasswordResponse.success && forgotPasswordResponse.token != null) {
          return forgotPasswordResponse;
        } else {
          throw Exception(forgotPasswordResponse.message);
        }
      } else {
        String errorMessage = 'Gagal validasi username. Kode: ${response.statusCode}';
        if (responseBody != null && responseBody['message'] != null) {
          errorMessage = responseBody['message'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  Future<ModelResetPasswordResponse> resetPassword({
    required String username,
    required String token,
    required String newPassword,
  }) async {
    if (baseUrl == null) {
      throw Exception("BASE_URL tidak ditemukan di .env");
    }
    final Uri resetPasswordUrl = Uri.parse('$baseUrl/api/auth/reset-password');
    final requestData = ModelResetPasswordRequest(
      username: username,
      token: token,
      newPassword: newPassword,
    );

    try {
      final response = await http.post(
        resetPasswordUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData.toMap()),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resetResponse = ModelResetPasswordResponse.fromJson(responseBody);
        if (resetResponse.success) {
          return resetResponse;
        } else {
          throw Exception(resetResponse.message);
        }
      } else {
        String errorMessage = 'Gagal reset password. Kode: ${response.statusCode}';
        if (responseBody['message'] != null) {
          errorMessage = responseBody['message']+' silahkan login ulang';
        } else {
          errorMessage = responseBody['errors'][0]['message'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}