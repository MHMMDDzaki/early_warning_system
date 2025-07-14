import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ModelRegistration.dart';

class ControllerRegistration {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<List<UserModel>> fetchPendingUsers() async {
    if (baseUrl == null) {
      throw Exception("BASE_URL tidak ditemukan di file .env");
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception("Token tidak ditemukan, silakan login kembali.");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/pending'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Decode body response
      final Map<String, dynamic> body = json.decode(response.body);

      // Ambil list 'data' dari body
      final List<dynamic> usersJson = body['data'];

      // Ubah setiap item JSON di dalam list menjadi objek UserModel
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    } else {
      // Jika request gagal, lempar exception
      throw Exception('Gagal memuat data pengguna: ${response.reasonPhrase}');
    }
  }

  Future<void> approveUser(String userId) async {
    if (baseUrl == null) {
      throw Exception("BASE_URL tidak ditemukan di file .env");
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception("Token tidak ditemukan, silakan login kembali.");
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/$userId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      // Coba parse pesan error dari body jika ada
      String errorMessage = 'Gagal menyetujui pengguna.';
      try {
        final body = json.decode(response.body);
        errorMessage += ' Pesan: ${body['message'] ?? response.reasonPhrase}';
      } catch (_) {
        errorMessage += ' Status: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> rejectUser(String userId) async {
    if (baseUrl == null) {
      throw Exception("BASE_URL tidak ditemukan di file .env");
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception("Token tidak ditemukan, silakan login kembali.");
    }

    final response = await http.delete( // Bisa juga http.post
      Uri.parse('$baseUrl/api/users/$userId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Gagal menolak pengguna.';
      try {
        final body = json.decode(response.body);
        errorMessage += ' Pesan: ${body['message'] ?? response.reasonPhrase}';
      } catch (_) {
        errorMessage += ' Status: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }
}