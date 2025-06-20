import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/ModelRegister.dart';

class ControllerRegister {
  final String? baseUrl = dotenv.env['BASE_URL'];


  Future<void> registerUser(ModelRegister registrationData) async {
    if (baseUrl == null) {
      throw Exception("BASE_URL tidak ditemukan di .env");
    }

    final Uri registerUrl = Uri.parse('$baseUrl/api/users/register');

    try {
      final response = await http.post(
        registerUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(registrationData.toMap()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        // Registrasi gagal, coba parse pesan error dari body jika ada
        String errorMessage = 'Gagal melakukan registrasi. Kode: ${response.statusCode}';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody != null && responseBody['message'] != null) {
            errorMessage = responseBody['message'];
          } else if (responseBody != null && responseBody['errors'] != null) {
            errorMessage = responseBody['errors'][0]['message'];
          }
        } catch (e, stackTrace) {
          // Gagal parse body, gunakan pesan default
          debugPrint('Error updating chart data: $e\nStackTrace: $stackTrace');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}