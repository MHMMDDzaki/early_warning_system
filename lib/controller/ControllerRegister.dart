// lib/controller/ControllerRegister.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/ModelRegister.dart'; // Sesuaikan path jika berbeda

class ControllerRegister {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<void> registerUser(ModelRegister registrationData) async {
    if (baseUrl == null) {
      throw Exception("BASE_URL tidak ditemukan di .env");
    }

    final Uri registerUrl = Uri.parse('$baseUrl/api/auth/register');

    try {
      final response = await http.post(
        registerUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-F',
        },
        body: json.encode(registrationData.toMap()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registrasi berhasil
        // Anda mungkin ingin mem-parse response.body jika API mengembalikan data pengguna atau token
        print('Registrasi berhasil: ${response.body}');
        return;
      } else {
        // Registrasi gagal, coba parse pesan error dari body jika ada
        String errorMessage = 'Gagal melakukan registrasi. Kode: ${response.statusCode}';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody != null && responseBody['message'] != null) {
            errorMessage = responseBody['message'];
          } else if (responseBody != null && responseBody['error'] != null) {
            errorMessage = responseBody['error'];
          }
        } catch (e) {
          // Gagal parse body, gunakan pesan default
          print('Gagal parse error response body: $e');
        }
        print('Error response body: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error saat registrasi: $e');
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }
}